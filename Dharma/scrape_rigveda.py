#!/usr/bin/env python3
"""
Scrape selected Rig Veda hymns from sacred-texts.com into Dharma/rigveda.json
with a unified schema compatible with Dharma loaders.

Merges with an existing rigveda.json: skips hymns already present (by book + hymn),
appends new verses, dedupes by id, and can write rigveda_new_ids.json for embedding.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Set, Tuple

import requests
from bs4 import BeautifulSoup

_SCRIPT_DIR = Path(__file__).resolve().parent

REQUEST_DELAY_SECONDS = 2.0
MAX_RETRIES = 3
BACKOFF_BASE = 1.0

DEFAULT_GITA_PATH = _SCRIPT_DIR / "gita.json"
DEFAULT_OUTPUT_PATH = _SCRIPT_DIR / "rigveda.json"
DEFAULT_NEW_IDS_PATH = _SCRIPT_DIR / "rigveda_new_ids.json"

REQUIRED_FIELDS = [
    "id",
    "source",
    "source_short",
    "category",
    "chapter",
    "verse",
    "sanskrit",
    "transliteration",
    "english",
    "hindi",
    "speaker",
    "wordMeanings",
]


def _build_hymns_list() -> List[Tuple[int, int, str]]:
    """Full target list (book, hymn, label); deduped by (book, hymn)."""
    raw: Sequence[Tuple[int, int, str]] = [
        # Mandala 1
        (1, 1, "Agni Sukta"),
        (1, 3, ""),
        (1, 22, ""),
        (1, 89, "Universal Blessings"),
        (1, 90, ""),
        (1, 115, ""),
        (1, 154, ""),
        (1, 155, ""),
        (1, 156, ""),
        (1, 164, ""),
        # Mandala 2
        (2, 1, ""),
        (2, 12, ""),
        (2, 23, ""),
        (2, 28, ""),
        (2, 33, ""),
        (2, 35, ""),
        (2, 38, ""),
        (2, 41, ""),
        # Mandala 3
        (3, 1, ""),
        (3, 33, ""),
        (3, 54, ""),
        (3, 59, ""),
        (3, 62, "Gayatri context"),
        # Mandala 4
        (4, 1, ""),
        (4, 26, ""),
        (4, 40, ""),
        (4, 50, ""),
        (4, 51, ""),
        (4, 58, ""),
        # Mandala 5
        (5, 1, ""),
        (5, 47, ""),
        (5, 51, ""),
        (5, 63, ""),
        (5, 82, ""),
        (5, 85, ""),
        # Mandala 6
        (6, 1, ""),
        (6, 47, ""),
        (6, 54, ""),
        (6, 61, ""),
        (6, 69, ""),
        (6, 75, ""),
        # Mandala 7
        (7, 1, ""),
        (7, 32, ""),
        (7, 49, ""),
        (7, 59, ""),
        (7, 63, ""),
        (7, 71, ""),
        (7, 86, ""),
        (7, 89, "Varuna"),
        # Mandala 8
        (8, 1, ""),
        (8, 29, ""),
        (8, 48, ""),
        (8, 58, ""),
        (8, 89, ""),
        # Mandala 9
        (9, 1, ""),
        (9, 10, ""),
        (9, 96, ""),
        (9, 107, ""),
        (9, 113, ""),
        # Mandala 10
        (10, 9, ""),
        (10, 14, ""),
        (10, 71, ""),
        (10, 85, ""),
        (10, 90, "Purusha Sukta"),
        (10, 97, ""),
        (10, 121, "Hiranyagarbha"),
        (10, 125, ""),
        (10, 127, ""),
        (10, 129, "Nasadiya Sukta"),
        (10, 154, ""),
        (10, 190, ""),
    ]
    seen: Set[Tuple[int, int]] = set()
    out: List[Tuple[int, int, str]] = []
    for b, h, lab in raw:
        if (b, h) in seen:
            continue
        seen.add((b, h))
        out.append((b, h, lab))
    return out


HYMNS: Sequence[Tuple[int, int, str]] = _build_hymns_list()


class RequestLimiter:
    def __init__(self) -> None:
        self.last_ts = 0.0

    def wait(self) -> None:
        now = time.time()
        elapsed = now - self.last_ts
        if elapsed < REQUEST_DELAY_SECONDS:
            time.sleep(REQUEST_DELAY_SECONDS - elapsed)
        self.last_ts = time.time()


def _read_json(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)


def _ensure_unified_schema_matches_gita(gita_path: Path) -> None:
    gita = _read_json(gita_path)
    chapters = gita.get("chapters", [])
    if not chapters or not chapters[0].get("verses"):
        raise RuntimeError(f"Could not find verses in {gita_path}")
    verse0 = chapters[0]["verses"][0]
    print("Detected gita.json verse fields:", sorted(list(verse0.keys())))
    if "wordMeanings" not in verse0:
        raise RuntimeError("gita.json does not contain `wordMeanings`; field naming mismatch risk.")


def _load_existing_rigveda(path: Path) -> List[Dict[str, object]]:
    if not path.is_file():
        return []
    try:
        data = _read_json(path)
    except (json.JSONDecodeError, OSError) as exc:
        print(f"[warn] Could not read {path}: {exc}. Starting empty.", file=sys.stderr)
        return []
    if not isinstance(data, list):
        print(f"[warn] {path} is not a JSON array. Starting empty.", file=sys.stderr)
        return []
    return data  # type: ignore[return-value]


def _hymns_from_entries(entries: List[Dict[str, object]]) -> Set[Tuple[int, int]]:
    """Parse rv-book-hymn-verse ids -> (book, hymn) set."""
    out: Set[Tuple[int, int]] = set()
    for e in entries:
        sid = str(e.get("id", ""))
        parts = sid.split("-")
        if len(parts) >= 4 and parts[0] == "rv":
            try:
                out.add((int(parts[1]), int(parts[2])))
            except ValueError:
                continue
    return out


def _fetch(url: str, limiter: RequestLimiter, timeout: int = 30) -> str:
    last_exc: Optional[Exception] = None
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            limiter.wait()
            headers = {
                "User-Agent": (
                    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
                ),
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
                "Referer": "https://www.sacred-texts.com/hin/rigveda/index.htm",
            }
            resp = requests.get(url, headers=headers, timeout=timeout)
            if resp.status_code == 404:
                raise requests.HTTPError(f"404 Not Found: {url}")
            if resp.status_code == 403:
                # Cloudflare often blocks direct script requests.
                mirror = f"https://r.jina.ai/http://{url.replace('https://', '').replace('http://', '')}"
                mresp = requests.get(mirror, timeout=timeout)
                mresp.raise_for_status()
                return mresp.text
            resp.raise_for_status()
            resp.encoding = resp.apparent_encoding or "utf-8"
            return resp.text
        except Exception as exc:  # noqa: BLE001
            last_exc = exc
            if attempt == MAX_RETRIES:
                break
            sleep_for = BACKOFF_BASE * (2 ** (attempt - 1))
            print(f"[warn] Fetch failed ({attempt}/{MAX_RETRIES}) for {url}: {exc}. Retrying in {sleep_for:.1f}s")
            time.sleep(sleep_for)
    raise RuntimeError(f"Failed to fetch {url}: {last_exc}")


def _hymn_url(book: int, hymn: int) -> str:
    return f"https://www.sacred-texts.com/hin/rigveda/rv{book:02d}{hymn:03d}.htm"


def _normalize_text(s: str) -> str:
    return re.sub(r"\s+", " ", (s or "")).strip()


def _extract_title_and_deity(soup: BeautifulSoup) -> Tuple[str, str]:
    heading = ""
    for tag in soup.find_all(["h1", "h2", "h3", "b", "strong"]):
        t = _normalize_text(tag.get_text(" ", strip=True))
        if "hymn" in t.lower() or "rig veda" in t.lower():
            heading = t
            break
    deity = ""
    body_txt = _normalize_text(soup.get_text(" ", strip=True))
    m = re.search(r"\bDeity\b[:\-\s]+([A-Za-z][A-Za-z\s\-']{1,80})", body_txt, flags=re.IGNORECASE)
    if m:
        deity = _normalize_text(m.group(1))
    return heading, deity


def _extract_numbered_verses(soup: BeautifulSoup) -> List[Tuple[int, str]]:
    # Gather candidate text lines from common containers.
    lines: List[str] = []
    for tag in soup.find_all(["p", "div", "li", "blockquote", "td"]):
        txt = _normalize_text(tag.get_text(" ", strip=True))
        if txt:
            lines.append(txt)

    verses: List[Tuple[int, str]] = []
    seen_numbers: Set[int] = set()
    for ln in lines:
        m = re.match(r"^(\d+)\.\s+(.+)$", ln)
        if not m:
            continue
        n = int(m.group(1))
        text = _normalize_text(m.group(2))
        # avoid capturing menu items / TOC noise
        if len(text) < 8:
            continue
        if n in seen_numbers:
            # keep first occurrence for stability
            continue
        seen_numbers.add(n)
        verses.append((n, text))

    verses.sort(key=lambda x: x[0])
    return verses


def _extract_numbered_verses_from_plain_text(text: str) -> List[Tuple[int, str]]:
    verses: List[Tuple[int, str]] = []
    seen: Set[int] = set()
    for raw in text.splitlines():
        ln = _normalize_text(raw)
        if not ln:
            continue
        m = re.match(r"^(\d+)[\.\)]?\s+(.+)$", ln)
        if not m:
            continue
        n = int(m.group(1))
        body = _normalize_text(m.group(2))
        if len(body) < 20:
            continue
        if n in seen:
            continue
        seen.add(n)
        verses.append((n, body))
    verses.sort(key=lambda x: x[0])
    return verses


def _make_entry(book: int, hymn: int, verse_no: int, english: str) -> Dict[str, object]:
    return {
        "id": f"rv-{book}-{hymn}-{verse_no}",
        "source": "Rig Veda",
        "source_short": "RV",
        "category": "Rig Veda",
        "chapter": int(book),
        "verse": f"{book}.{hymn}.{verse_no}",
        "sanskrit": "",
        "transliteration": "",
        "english": english or "",
        "hindi": "",
        "speaker": "",
        "wordMeanings": "",
    }


def _validate(entries: List[Dict[str, object]]) -> None:
    required = set(REQUIRED_FIELDS)
    seen: Set[str] = set()
    dupes: Set[str] = set()
    for i, e in enumerate(entries):
        keys = set(e.keys())
        if keys != required:
            missing = sorted(required - keys)
            extra = sorted(keys - required)
            raise RuntimeError(
                f"Schema mismatch at index {i}, id={e.get('id')}: missing={missing}, extra={extra}"
            )
        sid = str(e["id"])
        if sid in seen:
            dupes.add(sid)
        seen.add(sid)
    if dupes:
        raise RuntimeError(f"Duplicate IDs detected: {sorted(dupes)[:20]}")


def _sort_key_entry(e: Dict[str, object]) -> Tuple[int, int, int]:
    parts = str(e["id"]).split("-")
    return tuple(int(x) for x in parts[1:4])  # type: ignore[return-value]


def _merge_entries(
    existing: List[Dict[str, object]], new_rows: List[Dict[str, object]]
) -> List[Dict[str, object]]:
    by_id: Dict[str, Dict[str, object]] = {str(e["id"]): e for e in existing}
    for e in new_rows:
        by_id[str(e["id"])] = e
    combined = list(by_id.values())
    combined.sort(key=_sort_key_entry)
    return combined


def _summary(entries: List[Dict[str, object]]) -> None:
    by_hymn: Dict[str, int] = {}
    for e in entries:
        parts = str(e["id"]).split("-")
        key = f"Book {parts[1]}, Hymn {parts[2]}"
        by_hymn[key] = by_hymn.get(key, 0) + 1
    print("\n== Summary ==")
    for k in sorted(by_hymn):
        print(f"{k}: {by_hymn[k]}")
    print(f"Total entries: {len(entries)}")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Scrape selected Rig Veda hymns into unified schema JSON.")
    p.add_argument("--gita", type=Path, default=DEFAULT_GITA_PATH, help="Path to existing gita.json")
    p.add_argument("--output", type=Path, default=DEFAULT_OUTPUT_PATH, help="Output rigveda.json path")
    p.add_argument(
        "--new-ids-output",
        type=Path,
        default=DEFAULT_NEW_IDS_PATH,
        help="Write JSON array of ids added this run (for embed_verses.js --only-ids)",
    )
    p.add_argument("--dry-run", action="store_true", help="Print hymns to scrape/ skip; do not fetch or write")
    p.add_argument("--verbose", action="store_true", help="Print HTML snippet for first fetched page")
    return p.parse_args()


def main() -> None:
    args = parse_args()
    _ensure_unified_schema_matches_gita(args.gita)

    existing_entries = _load_existing_rigveda(args.output)
    have_hymns = _hymns_from_entries(existing_entries)

    to_scrape: List[Tuple[int, int, str]] = []
    skipped_hymns: List[Tuple[int, int]] = []
    for book, hymn, label in HYMNS:
        if (book, hymn) in have_hymns:
            skipped_hymns.append((book, hymn))
        else:
            to_scrape.append((book, hymn, label))

    print(f"Existing rigveda.json entries: {len(existing_entries)}")
    print(f"Hymns in target list: {len(HYMNS)} (unique book/hymn pairs)")
    print(f"Hymns skipped (already in file): {len(skipped_hymns)}")
    print(f"Hymns to scrape: {len(to_scrape)}")

    if args.dry_run:
        print("\n[dry-run] Would scrape:")
        for b, h, lab in to_scrape:
            print(f"  Book {b}, Hymn {h} {f'({lab})' if lab else ''}")
        print("\n[dry-run] No files written.")
        return

    limiter = RequestLimiter()
    new_rows: List[Dict[str, object]] = []
    scraped_hymns: List[Tuple[int, int]] = []
    failed_hymns: List[Tuple[int, int]] = []

    printed_debug = False
    for book, hymn, label in to_scrape:
        url = _hymn_url(book, hymn)
        print(f"\n== Scraping Book {book}, Hymn {hymn} {f'({label})' if label else ''} ==")
        try:
            html = _fetch(url, limiter)
        except Exception as exc:  # noqa: BLE001
            print(f"[warn] Failed {url}: {exc}. Skipping hymn.")
            failed_hymns.append((book, hymn))
            continue

        if args.verbose and not printed_debug:
            print(f"\n[debug] Raw HTML for first hymn page: {url}")
            print(html[:5000])
            printed_debug = True

        soup = BeautifulSoup(html, "html.parser")
        heading, deity = _extract_title_and_deity(soup)
        if heading:
            print(f"Heading: {heading}")
        if deity:
            print(f"Deity: {deity}")

        verses = _extract_numbered_verses(soup)
        if not verses:
            verses = _extract_numbered_verses_from_plain_text(html)
        if not verses:
            print(f"[warn] Unexpected structure for {url}: no numbered verses found. Skipping hymn.")
            failed_hymns.append((book, hymn))
            continue

        scraped_hymns.append((book, hymn))
        for vno, vtext in verses:
            new_rows.append(_make_entry(book, hymn, vno, vtext))

    combined = _merge_entries(existing_entries, new_rows)
    _validate(combined)
    _write_json(args.output, combined)

    new_ids = [str(e["id"]) for e in new_rows]
    _write_json(args.new_ids_output, new_ids)

    print(f"\nWrote {args.output}")
    print(f"Wrote {len(new_ids)} new verse ids to {args.new_ids_output}")
    print(f"\n== Counts ==")
    print(f"New verses added this run: {len(new_rows)}")
    print(f"Total verses in rigveda.json: {len(combined)}")
    print(f"Hymns scraped successfully: {len(scraped_hymns)}")
    if failed_hymns:
        print(f"Hymns failed/skipped (no verses): {failed_hymns}")
    _summary(combined)


if __name__ == "__main__":
    main()
