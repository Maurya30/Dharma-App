#!/usr/bin/env python3
"""
Scrape selected Rig Veda hymns from sacred-texts.com into Dharma/rigveda.json
with a unified schema compatible with Dharma loaders.
"""

from __future__ import annotations

import argparse
import json
import re
import time
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Set, Tuple

import requests
from bs4 import BeautifulSoup

REQUEST_DELAY_SECONDS = 1.0
MAX_RETRIES = 3
BACKOFF_BASE = 1.0

DEFAULT_GITA_PATH = Path.home() / "Desktop" / "Dharma" / "Dharma" / "gita.json"
DEFAULT_OUTPUT_PATH = Path.home() / "Desktop" / "Dharma" / "Dharma" / "rigveda.json"

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

HYMNS: Sequence[Tuple[int, int, str]] = [
    (1, 1, "Agni Sukta"),
    (1, 89, "Universal Blessings"),
    (1, 90, ""),
    (3, 62, "Gayatri context"),
    (7, 89, "Varuna"),
    (10, 90, "Purusha Sukta"),
    (10, 121, "Hiranyagarbha"),
    (10, 129, "Nasadiya Sukta"),
    (10, 191, "Harmony"),
]


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
    return p.parse_args()


def main() -> None:
    args = parse_args()
    _ensure_unified_schema_matches_gita(args.gita)

    limiter = RequestLimiter()
    rows: List[Dict[str, object]] = []

    printed_debug = False
    for book, hymn, label in HYMNS:
        url = _hymn_url(book, hymn)
        print(f"\n== Scraping Book {book}, Hymn {hymn} {f'({label})' if label else ''} ==")
        try:
            html = _fetch(url, limiter)
        except Exception as exc:  # noqa: BLE001
            print(f"[warn] Failed {url}: {exc}. Skipping hymn.")
            continue

        if not printed_debug:
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
            continue

        for vno, vtext in verses:
            rows.append(_make_entry(book, hymn, vno, vtext))

    # deterministic order
    rows.sort(key=lambda e: tuple(int(x) for x in str(e["id"]).split("-")[1:4]))
    _validate(rows)
    _write_json(args.output, rows)
    print(f"\nWrote {args.output}")
    _summary(rows)


if __name__ == "__main__":
    main()

