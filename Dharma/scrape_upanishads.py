#!/usr/bin/env python3
"""
Scrape Upanishad data into Dharma/upanishads.json using a unified schema.

Important:
- Reads gita.json first and enforces matching field naming conventions.
- Scrapes 7 Upanishads from shlokam.org by discovering verse URLs dynamically.
- Loads additional Upanishads from atmabodha/Vedanta_Datasets.
- Never omits required fields; non-applicable fields are empty strings.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup

REQUEST_DELAY_SECONDS = 1.0
MAX_RETRIES = 3
BACKOFF_BASE = 1.0

DEFAULT_GITA_PATH = Path.home() / "Desktop" / "Dharma" / "Dharma" / "gita.json"
DEFAULT_OUTPUT_PATH = Path.home() / "Desktop" / "Dharma" / "Dharma" / "upanishads.json"

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

SHLOKAM_SOURCES = [
    ("Isha Upanishad", "IU", "isha", "https://shlokam.org/isha/"),
    ("Kena Upanishad", "KenU", "kena", "https://shlokam.org/kena/"),
    ("Katha Upanishad", "KatU", "katha", "https://shlokam.org/katha/"),
    ("Taittiriya Upanishad", "TU", "taittiriya", "https://shlokam.org/taittiriya/"),
    ("Chandogya Upanishad", "CU", "chandogya", "https://shlokam.org/chandogya-upanishad/"),
    ("Brihadaranyaka Upanishad", "BU", "brihadaranyaka", "https://shlokam.org/brihadaranyaka/"),
    ("Prashna Upanishad", "PU", "prashna", "https://shlokam.org/prashna/"),
]


@dataclass
class RequestLimiter:
    last_request_ts: float = 0.0

    def wait(self) -> None:
        now = time.time()
        elapsed = now - self.last_request_ts
        if elapsed < REQUEST_DELAY_SECONDS:
            time.sleep(REQUEST_DELAY_SECONDS - elapsed)
        self.last_request_ts = time.time()


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
        raise RuntimeError(
            "gita.json does not contain `wordMeanings`; cannot guarantee compatible field naming."
        )


def _request_with_retries(url: str, limiter: RequestLimiter, timeout: int = 30) -> str:
    last_exc: Optional[Exception] = None
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            limiter.wait()
            resp = requests.get(url, timeout=timeout)
            if resp.status_code == 404:
                raise requests.HTTPError(f"404 Not Found: {url}")
            resp.raise_for_status()
            resp.encoding = resp.apparent_encoding or "utf-8"
            return resp.text
        except Exception as exc:  # noqa: BLE001
            last_exc = exc
            if attempt == MAX_RETRIES:
                break
            sleep_for = BACKOFF_BASE * (2 ** (attempt - 1))
            print(f"[warn] Request failed ({attempt}/{MAX_RETRIES}) for {url}: {exc}. Retrying in {sleep_for:.1f}s")
            time.sleep(sleep_for)
    raise RuntimeError(f"Failed to fetch {url} after {MAX_RETRIES} attempts: {last_exc}")


def _normalize_text(s: str) -> str:
    return re.sub(r"\s+", " ", s or "").strip()


def _contains_devanagari(s: str) -> bool:
    return bool(re.search(r"[\u0900-\u097F]", s or ""))


def _looks_like_iast(s: str) -> bool:
    return bool(re.search(r"[āīūṛṝḷṅñṭḍṇśṣḥṃṁ]", s or "", flags=re.IGNORECASE))


def _extract_from_verse_page(html: str) -> Tuple[str, str, str]:
    soup = BeautifulSoup(html, "html.parser")

    # Try broad content area first, fallback to full document text blocks.
    containers = []
    for sel in ("article", "main", "div.entry-content", "div.post-content", "div.content"):
        containers.extend(soup.select(sel))
    if not containers:
        containers = [soup]

    candidates: List[str] = []
    for c in containers:
        for tag in c.find_all(["p", "div", "span", "li", "blockquote"]):
            txt = _normalize_text(tag.get_text(" ", strip=True))
            if len(txt) >= 20:
                candidates.append(txt)

    # De-duplicate while preserving order.
    seen: Set[str] = set()
    uniq = []
    for t in candidates:
        if t not in seen:
            seen.add(t)
            uniq.append(t)

    sanskrit = ""
    transliteration = ""
    english = ""

    for t in uniq:
        if not sanskrit and _contains_devanagari(t):
            sanskrit = t
            continue
        if not transliteration and _looks_like_iast(t):
            transliteration = t
            continue
        if not english and not _contains_devanagari(t):
            # Heuristic: English translation sentences are generally long and mostly ASCII words.
            alpha_words = re.findall(r"[A-Za-z]{3,}", t)
            if len(alpha_words) >= 8:
                english = t

    return sanskrit, transliteration, english


def _extract_inline_verses_from_page(html: str) -> List[Tuple[int, str, str, str]]:
    """
    Fallback parser for monolithic shlokam pages where all verses are on one page.
    Returns tuples: (verse_no, sanskrit, transliteration, english)
    """
    soup = BeautifulSoup(html, "html.parser")
    lines = [" ".join(x.split()) for x in soup.stripped_strings if x and x.strip()]

    out: List[Tuple[int, str, str, str]] = []
    curr_sanskrit = ""
    curr_iast = ""
    seen_verses: Set[int] = set()

    for ln in lines:
        # Capture Sanskrit candidate
        if _contains_devanagari(ln):
            curr_sanskrit = ln
            continue

        # Capture IAST line candidate
        if _looks_like_iast(ln) and not re.match(r"^\d+[\.\)]\s+", ln):
            curr_iast = ln
            continue

        # English verse line candidate: "1. ..." or "1 ..."
        m = re.match(r"^(\d+)[\.\)]?\s+(.+)$", ln)
        if not m:
            continue
        vnum = int(m.group(1))
        etext = _normalize_text(m.group(2))
        if len(etext) < 25:
            continue
        # Heuristic: translation likely has many alphabetic words.
        if len(re.findall(r"[A-Za-z]{3,}", etext)) < 6:
            continue
        if vnum in seen_verses:
            continue
        seen_verses.add(vnum)
        out.append((vnum, curr_sanskrit, curr_iast, etext))

    return sorted(out, key=lambda x: x[0])


def _stable_slug(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


def _discover_verse_urls(index_url: str, html: str) -> List[str]:
    soup = BeautifulSoup(html, "html.parser")
    base_path = urlparse(index_url).path.rstrip("/") + "/"

    out: Set[str] = set()
    for a in soup.find_all("a", href=True):
        href = a["href"].strip()
        if href.startswith("#") or href.lower().startswith("javascript:"):
            continue
        full = urljoin(index_url, href)
        parsed = urlparse(full)
        if parsed.netloc != "shlokam.org":
            continue

        # Keep pages under this Upanishad prefix that appear to include verse/chapter ids.
        if not parsed.path.startswith(base_path):
            continue
        leaf = parsed.path.rstrip("/").split("/")[-1]
        if not re.search(r"\d", leaf):
            continue
        out.add(full)

    # Natural sort by embedded numbers.
    def nkey(u: str):
        leaf = urlparse(u).path.rstrip("/").split("/")[-1]
        parts = re.split(r"(\d+)", leaf)
        key = []
        for p in parts:
            key.append(int(p) if p.isdigit() else p)
        return key

    return sorted(out, key=nkey)


def _parse_chapter_verse_from_url(url: str) -> Tuple[int, str]:
    leaf = urlparse(url).path.rstrip("/").split("/")[-1]
    nums = [int(n) for n in re.findall(r"\d+", leaf)]
    if not nums:
        return 1, "1"
    if len(nums) == 1:
        return 1, str(nums[0])
    return nums[0], ".".join(str(n) for n in nums[1:])


def _make_entry(
    *,
    id_: str,
    source: str,
    source_short: str,
    chapter: int,
    verse: str,
    sanskrit: str,
    transliteration: str,
    english: str,
) -> Dict[str, object]:
    return {
        "id": id_,
        "source": source,
        "source_short": source_short,
        "category": "Upanishad",
        "chapter": int(chapter),
        "verse": str(verse),
        "sanskrit": sanskrit or "",
        "transliteration": transliteration or "",
        "english": english or "",
        "hindi": "",
        "speaker": "",
        "wordMeanings": "",
    }


def scrape_shlokam() -> List[Dict[str, object]]:
    limiter = RequestLimiter()
    rows: List[Dict[str, object]] = []

    for source, short, slug, index_url in SHLOKAM_SOURCES:
        print(f"\n== Scraping {source} ({index_url}) ==")
        try:
            idx_html = _request_with_retries(index_url, limiter)
        except Exception as exc:  # noqa: BLE001
            print(f"[warn] Could not fetch index for {source}: {exc}. Skipping.")
            continue
        verse_urls = _discover_verse_urls(index_url, idx_html)
        print(f"Discovered {len(verse_urls)} verse URLs.")

        if verse_urls:
            # Required inspection output: raw HTML of first verse page.
            first_html = _request_with_retries(verse_urls[0], limiter)
            print(f"\n[debug] Raw HTML for first verse page of {source}: {verse_urls[0]}")
            print(first_html[:5000])

            for i, vurl in enumerate(verse_urls):
                try:
                    html = first_html if i == 0 else _request_with_retries(vurl, limiter)
                except Exception as exc:  # noqa: BLE001
                    print(f"[warn] Failed page {vurl}: {exc}. Skipping.")
                    continue

                chapter, verse = _parse_chapter_verse_from_url(vurl)
                sanskrit, translit, english = _extract_from_verse_page(html)
                if not any([sanskrit, translit, english]):
                    print(f"[warn] Unexpected page structure for {vurl}; extracted no content. Skipping.")
                    continue

                id_ = f"{slug}-{chapter}-{verse}".replace(".", "-")
                rows.append(
                    _make_entry(
                        id_=id_,
                        source=source,
                        source_short=short,
                        chapter=chapter,
                        verse=verse,
                        sanskrit=sanskrit,
                        transliteration=translit,
                        english=english,
                    )
                )
            continue

        # Fallback: parse all verses inline from monolithic page.
        print(f"[info] Falling back to inline verse extraction for {source}")
        print(f"\n[debug] Raw HTML for first verse page of {source}: {index_url}")
        print(idx_html[:5000])
        inline = _extract_inline_verses_from_page(idx_html)
        if not inline:
            print(f"[warn] No inline verses extracted for {source}.")
            continue
        for vnum, sanskrit, translit, english in inline:
            verse = str(vnum)
            id_ = f"{slug}-1-{verse}".replace(".", "-")
            rows.append(
                _make_entry(
                    id_=id_,
                    source=source,
                    source_short=short,
                    chapter=1,
                    verse=verse,
                    sanskrit=sanskrit,
                    transliteration=translit,
                    english=english,
                )
            )

    return rows


def _clone_atmabodha_repo(tmpdir: Path) -> Path:
    repo_dir = tmpdir / "Vedanta_Datasets"
    cmd = [
        "git",
        "clone",
        "--depth",
        "1",
        "https://github.com/atmabodha/Vedanta_Datasets.git",
        str(repo_dir),
    ]
    subprocess.run(cmd, check=True)
    return repo_dir


def _iter_json_files(root: Path) -> Iterable[Path]:
    for p in root.rglob("*.json"):
        if p.is_file():
            yield p


def _source_short_for_name(name: str) -> str:
    n = name.lower()
    mapping = {
        "isha": "IU",
        "kena": "KenU",
        "katha": "KatU",
        "taittiriya": "TU",
        "chandogya": "CU",
        "brihadaranyaka": "BU",
        "prashna": "PU",
        "mundaka": "MuU",
        "mandukya": "MaU",
        "aitareya": "AU",
        "svetasvatara": "SU",
    }
    for k, v in mapping.items():
        if k in n:
            return v
    return "".join(w[:1].upper() for w in re.findall(r"[A-Za-z]+", name)) or "UP"


def _name_from_filename(path: Path) -> str:
    stem = path.stem.replace("_", " ").replace("-", " ").strip()
    words = [w.capitalize() for w in stem.split()]
    if "Upanishad" not in words:
        words.append("Upanishad")
    return " ".join(words)


def _flatten_records(payload) -> List[dict]:
    if isinstance(payload, list):
        return [x for x in payload if isinstance(x, dict)]
    if isinstance(payload, dict):
        for key in ("data", "verses", "items", "records", "shlokas"):
            if isinstance(payload.get(key), list):
                return [x for x in payload[key] if isinstance(x, dict)]
    return []


def _pick_field(rec: dict, keys: Sequence[str]) -> str:
    for k in keys:
        if k in rec and rec[k] is not None:
            return str(rec[k]).strip()
    return ""


def load_atmabodha_missing(shlokam_sources: Set[str]) -> List[Dict[str, object]]:
    out: List[Dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix="dharma-upanishads-") as td:
        repo = _clone_atmabodha_repo(Path(td))
        up_root = repo / "Upanishads"
        if not up_root.exists():
            print("[warn] Upanishads directory missing in atmabodha repo.")
            return out

        files = sorted(_iter_json_files(up_root))
        if not files:
            print("[warn] No JSON files found under atmabodha Upanishads.")
            return out

        print("\n== Inspecting Atmabodha Upanishad files ==")
        sample_payload = _read_json(files[0])
        sample_records = _flatten_records(sample_payload)
        if sample_records:
            print(f"[debug] Example file: {files[0].name}")
            print("[debug] Detected record fields:", sorted(sample_records[0].keys()))
        else:
            print(f"[debug] Could not flatten records from sample: {files[0].name}")

        for path in files:
            source = _name_from_filename(path)
            if source in shlokam_sources:
                # Keep shlokam as primary for these 7.
                continue

            try:
                payload = _read_json(path)
            except Exception as exc:  # noqa: BLE001
                print(f"[warn] Failed reading {path.name}: {exc}. Skipping.")
                continue

            records = _flatten_records(payload)
            if not records:
                print(f"[warn] No records found in {path.name}, skipping.")
                continue

            short = _source_short_for_name(source)
            src_slug = _stable_slug(source.replace(" Upanishad", ""))

            for idx, rec in enumerate(records, start=1):
                chapter_raw = _pick_field(rec, ("chapter", "chapter_no", "chapterNumber", "adhyaya", "section"))
                verse_raw = _pick_field(rec, ("verse", "verse_no", "verseNumber", "shloka_no", "mantra"))
                chapter = int(chapter_raw) if chapter_raw.isdigit() else 1
                verse = verse_raw or str(idx)

                sanskrit = _pick_field(rec, ("sanskrit", "devanagari", "text_sanskrit", "sloka", "shloka"))
                translit = _pick_field(rec, ("transliteration", "iast", "roman", "text_transliteration"))
                english = _pick_field(rec, ("english", "translation", "translation_english", "meaning"))

                id_ = f"{src_slug}-{chapter}-{verse}".replace(".", "-")
                out.append(
                    _make_entry(
                        id_=id_,
                        source=source,
                        source_short=short,
                        chapter=chapter,
                        verse=verse,
                        sanskrit=sanskrit,
                        transliteration=translit,
                        english=english,
                    )
                )

    return out


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
    by_source: Dict[str, int] = {}
    for e in entries:
        src = str(e["source"])
        by_source[src] = by_source.get(src, 0) + 1

    print("\n== Summary ==")
    for src in sorted(by_source):
        print(f"{src}: {by_source[src]}")
    print(f"Total entries: {len(entries)}")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Scrape Upanishads into unified schema JSON.")
    p.add_argument("--gita", type=Path, default=DEFAULT_GITA_PATH, help="Path to existing gita.json")
    p.add_argument("--output", type=Path, default=DEFAULT_OUTPUT_PATH, help="Output upanishads.json path")
    return p.parse_args()


def main() -> None:
    args = parse_args()
    _ensure_unified_schema_matches_gita(args.gita)

    shlokam_rows = scrape_shlokam()
    shlokam_sources = {src for src, *_ in SHLOKAM_SOURCES}
    atmabodha_rows = load_atmabodha_missing(shlokam_sources)

    all_rows = shlokam_rows + atmabodha_rows

    # Ensure deterministic order: source, chapter, verse, id
    def sort_key(e: Dict[str, object]):
        verse_str = str(e["verse"])
        nums = tuple(int(x) for x in re.findall(r"\d+", verse_str)) or (0,)
        return (str(e["source"]), int(e["chapter"]), nums, str(e["id"]))

    all_rows = sorted(all_rows, key=sort_key)
    _validate(all_rows)
    _write_json(args.output, all_rows)
    print(f"\nWrote {args.output}")
    _summary(all_rows)


if __name__ == "__main__":
    main()

