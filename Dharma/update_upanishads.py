#!/usr/bin/env python3
"""
Second-pass updater for upanishads.json:
  1. Replaces partial shlokam Katha (29) with complete CSV (119)
  2. Adds Mandukya (12 verses) from atmabodha CSV
  3. Scrapes Brihadaranyaka from wisdomlib.org with proper chapter tracking
  4. Merges everything into upanishads.json and validates
"""

import csv
import json
import re
import time
import requests
from bs4 import BeautifulSoup
from pathlib import Path

OUTPUT = Path(__file__).parent / "upanishads.json"
ATMABODHA = Path("/tmp/atmabodha_repo/Upanishads")

SCHEMA_KEYS = [
    "id", "source", "source_short", "category", "chapter",
    "verse", "sanskrit", "transliteration", "english",
    "hindi", "speaker", "wordMeanings",
]

DEVANAGARI_RE = re.compile(r"[\u0900-\u097F]")
VERSE_NUM_RE = re.compile(r"॥\s*([०-९\d]+)\s*॥")

DEVANAGARI_DIGITS = str.maketrans("०१२३४५६७८९", "0123456789")


def dev_to_arabic(s):
    """Convert Devanagari numeral string to Arabic."""
    return s.translate(DEVANAGARI_DIGITS)


def make_entry(**kw):
    entry = {k: "" for k in SCHEMA_KEYS}
    entry["category"] = "Upanishad"
    entry.update(kw)
    return entry


# ---------------------------------------------------------------------------
# 1. Parse atmabodha CSVs
# ---------------------------------------------------------------------------

def parse_katha_csv():
    entries = []
    path = ATMABODHA / "Upanishad_Katha.csv"
    with open(path, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            ch = row.get("Chapter/Valli", "").strip()
            v = row.get("Verse", "").strip()
            sanskrit = row.get("Sanskrit", "").strip()
            english = row.get("Translation", "").strip()
            verse_label = f"{ch}.{v}" if ch and v else v
            entry = make_entry(
                id=f"katha-{ch.replace('.', '-')}-{v}",
                source="Katha Upanishad",
                source_short="KatU",
                chapter=ch,
                verse=verse_label,
                sanskrit=sanskrit,
                english=english,
            )
            entries.append(entry)
    return entries


def parse_mandukya_csv():
    entries = []
    path = ATMABODHA / "Upanishad_Mandukya.csv"
    with open(path, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            ch = row.get("Chapter", "").strip()
            v = row.get("Verse", "").strip()
            entry = make_entry(
                id=f"mandukya-{ch}-{v}",
                source="Mandukya Upanishad",
                source_short="MU",
                chapter=ch,
                verse=f"{ch}.{v}",
                sanskrit=row.get("Sanskrit", "").strip(),
                english=row.get("Translation", "").strip(),
            )
            entries.append(entry)
    return entries


# ---------------------------------------------------------------------------
# 2. Scrape Brihadaranyaka from wisdomlib.org
# ---------------------------------------------------------------------------

WISDOMLIB_BASE = "https://www.wisdomlib.org"
BRHAD_INDEX = WISDOMLIB_BASE + "/hinduism/book/the-brihadaranyaka-upanishad"

ROMAN_MAP = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6,
    "VII": 7, "VIII": 8, "IX": 9, "X": 10, "XI": 11, "XII": 12,
    "XIII": 13, "XIV": 14, "XV": 15, "XVI": 16, "XVII": 17, "XVIII": 18,
}


def fetch(url, retries=3):
    for attempt in range(retries):
        try:
            r = requests.get(url, timeout=30)
            r.raise_for_status()
            return r
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(1.5 * (attempt + 1))
            else:
                print(f"  FAIL {url}: {e}")
                return None


def discover_all_pages():
    """Get chapter + section pages from the Brihadaranyaka index."""
    r = fetch(BRHAD_INDEX)
    if not r:
        return []
    soup = BeautifulSoup(r.text, "html.parser")
    pages = []
    seen = set()
    for a in soup.find_all("a", href=True):
        href = a["href"]
        if "brihadaranyaka" in href and "/doc" in href and href not in seen:
            seen.add(href)
            text = a.get_text(strip=True)
            if "Chapter" in text or "Section" in text:
                pages.append((href, text))
    return pages


def split_sanskrit_and_transliteration(text):
    lines = text.strip().split("\n")
    sanskrit_lines = []
    translit_lines = []
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        dev_count = len(DEVANAGARI_RE.findall(stripped))
        total = len(stripped.replace(" ", ""))
        if total > 0 and dev_count / total > 0.3:
            sanskrit_lines.append(stripped)
        else:
            translit_lines.append(stripped)
    return "\n".join(sanskrit_lines), "\n".join(translit_lines)


def extract_section_number(title):
    """Extract Roman numeral section number from title like 'Section III - ...'"""
    m = re.search(r"Section\s+(\w+)", title)
    if m:
        return ROMAN_MAP.get(m.group(1), 0)
    return 0


def extract_brihadaranyaka_verses(section_url, section_title, chapter_num, section_num):
    r = fetch(WISDOMLIB_BASE + section_url)
    if not r:
        return []

    soup = BeautifulSoup(r.text, "html.parser")
    blockquotes = soup.find_all("blockquote")
    entries = []
    local_counter = 0

    for bq in blockquotes:
        text = bq.get_text()
        if not DEVANAGARI_RE.search(text):
            continue

        verse_nums = VERSE_NUM_RE.findall(text)
        if verse_nums:
            raw_num = verse_nums[-1]
            verse_label = dev_to_arabic(raw_num)
        else:
            local_counter += 1
            verse_label = str(local_counter)

        sanskrit, transliteration = split_sanskrit_and_transliteration(text)
        sanskrit = re.sub(r"॥[^॥]*॥", "", sanskrit).strip()

        nxt = bq.find_next_sibling("p")
        english = ""
        if nxt:
            eng_text = nxt.get_text(strip=True)
            if len(eng_text) > 20 and not DEVANAGARI_RE.search(eng_text):
                english = eng_text

        vid = f"brhad-{chapter_num}-{section_num}-{verse_label}"

        entries.append(make_entry(
            id=vid,
            source="Brihadaranyaka Upanishad",
            source_short="BU",
            chapter=str(chapter_num),
            verse=f"{chapter_num}.{section_num}.{verse_label}",
            sanskrit=sanskrit,
            transliteration=transliteration,
            english=english,
        ))

    return entries


def scrape_brihadaranyaka():
    print("\n=== Scraping Brihadaranyaka from wisdomlib ===")
    all_pages = discover_all_pages()
    print(f"  Found {len(all_pages)} chapter/section pages")

    all_entries = []
    current_chapter = 0

    for href, title in all_pages:
        if "Chapter" in title and "Section" not in title:
            m = re.search(r"Chapter\s+(\w+)", title)
            if m:
                current_chapter = ROMAN_MAP.get(m.group(1), current_chapter + 1)
            print(f"  --- Chapter {current_chapter} ---")
            continue

        section_num = extract_section_number(title)
        print(f"  Scraping: {title} (ch {current_chapter}, sec {section_num})")
        verses = extract_brihadaranyaka_verses(href, title, current_chapter, section_num)
        print(f"    → {len(verses)} verses")
        all_entries.extend(verses)
        time.sleep(1)

    print(f"  Total Brihadaranyaka verses: {len(all_entries)}")
    return all_entries


# ---------------------------------------------------------------------------
# 3. Scrape Mundaka & Taittiriya from shlokam.org
# ---------------------------------------------------------------------------

def scrape_shlokam_monolithic(slug, source_name, source_short):
    """Scrape a monolithic shlokam.org page with verse-section divs."""
    url = f"https://shlokam.org/{slug}/"
    print(f"\n  Fetching {url}")
    r = fetch(url)
    if not r:
        return []

    soup = BeautifulSoup(r.text, "html.parser")
    verse_sections = soup.find_all("div", class_="verse-section")
    print(f"  Found {len(verse_sections)} verse-sections")

    entries = []
    for idx, vs in enumerate(verse_sections):
        detail_sections = vs.find_all("div", class_="detail-section", recursive=False)
        if len(detail_sections) < 4:
            continue

        sanskrit_div = detail_sections[0].find("div", class_="detail-sanskrit")
        if not sanskrit_div:
            sanskrit_div = detail_sections[0].find("div", class_="detail-text")

        iast_div = detail_sections[1].find("div", class_="detail-text")

        english_div = detail_sections[3].find("div", class_="detail-translation")
        if not english_div:
            english_div = detail_sections[3].find("div", class_="detail-text")

        word_div = None
        if len(detail_sections) >= 5:
            word_div = detail_sections[4].find("div", class_="detail-text")

        sanskrit = ""
        if sanskrit_div:
            parts = []
            for child in sanskrit_div.children:
                if hasattr(child, "name") and child.name == "br":
                    parts.append("\n")
                elif hasattr(child, "name"):
                    parts.append(child.get_text())
                else:
                    parts.append(str(child))
            sanskrit = "".join(parts).strip()

        translit = iast_div.get_text(strip=True) if iast_div else ""
        english = english_div.get_text(strip=True) if english_div else ""
        word_meanings = word_div.get_text(strip=True) if word_div else ""

        verse_num = idx + 1
        vid = f"{slug}-{verse_num}"

        entries.append(make_entry(
            id=vid,
            source=source_name,
            source_short=source_short,
            chapter="1",
            verse=str(verse_num),
            sanskrit=sanskrit,
            transliteration=translit,
            english=english,
            wordMeanings=word_meanings,
        ))

    return entries


def scrape_shlokam_extras():
    """Scrape Mundaka and Taittiriya from shlokam.org."""
    print("\n=== Scraping Mundaka & Taittiriya from shlokam.org ===")
    all_entries = []

    mundaka = scrape_shlokam_monolithic("mundaka", "Mundaka Upanishad", "MundU")
    print(f"  Mundaka: {len(mundaka)} verses")
    all_entries.extend(mundaka)

    taittiriya = scrape_shlokam_monolithic("taittiriya", "Taittiriya Upanishad", "TU")
    print(f"  Taittiriya: {len(taittiriya)} verses")
    all_entries.extend(taittiriya)

    return all_entries


# ---------------------------------------------------------------------------
# 4. Merge and deduplicate
# ---------------------------------------------------------------------------

def merge_all():
    with open(OUTPUT, encoding="utf-8") as f:
        existing = json.load(f)
    print(f"\nExisting entries: {len(existing)}")

    non_katha = [e for e in existing if e["source"] != "Katha Upanishad"]
    old_katha = [e for e in existing if e["source"] == "Katha Upanishad"]
    non_brhad = [e for e in non_katha if e["source"] != "Brihadaranyaka Upanishad"]

    print(f"  Removing {len(old_katha)} old Katha entries (replacing with 119 from CSV)")
    removed_brhad = len(non_katha) - len(non_brhad)
    if removed_brhad:
        print(f"  Removing {removed_brhad} old Brihadaranyaka entries (replacing with fresh scrape)")

    existing_ids = {e["id"] for e in non_brhad}

    katha_csv = parse_katha_csv()
    katha_new = []
    for entry in katha_csv:
        if entry["id"] not in existing_ids:
            katha_new.append(entry)
            existing_ids.add(entry["id"])
    print(f"Katha CSV: {len(katha_csv)} total, {len(katha_new)} added")

    mandukya = parse_mandukya_csv()
    mandukya_new = [e for e in mandukya if e["id"] not in existing_ids]
    for e in mandukya_new:
        existing_ids.add(e["id"])
    print(f"Mandukya CSV: {len(mandukya)} total, {len(mandukya_new)} new")

    brhad = scrape_brihadaranyaka()
    brhad_deduped = []
    for e in brhad:
        if e["id"] not in existing_ids:
            brhad_deduped.append(e)
            existing_ids.add(e["id"])
        else:
            print(f"    Skipping dup: {e['id']}")
    print(f"Brihadaranyaka: {len(brhad)} scraped, {len(brhad_deduped)} after dedup")

    shlokam_extras = scrape_shlokam_extras()
    shlokam_new = []
    for e in shlokam_extras:
        if e["id"] not in existing_ids:
            shlokam_new.append(e)
            existing_ids.add(e["id"])
    print(f"Shlokam extras (Mundaka + Taittiriya): {len(shlokam_extras)} scraped, {len(shlokam_new)} new")

    merged = non_brhad + katha_new + mandukya_new + brhad_deduped + shlokam_new
    return merged


# ---------------------------------------------------------------------------
# 4. Validation and summary
# ---------------------------------------------------------------------------

def validate_and_save(data):
    print(f"\n=== Validation ===")
    print(f"Total entries: {len(data)}")

    errors = []
    ids_seen = set()
    for i, item in enumerate(data):
        for k in SCHEMA_KEYS:
            if k not in item:
                errors.append(f"Entry {i} missing key '{k}'")
        if item["id"] in ids_seen:
            errors.append(f"Duplicate ID: {item['id']}")
        ids_seen.add(item["id"])

    if errors:
        print(f"  {len(errors)} errors:")
        for e in errors[:20]:
            print(f"    {e}")
    else:
        print("  All entries valid — no missing keys, no duplicate IDs")

    source_counts = {}
    for item in data:
        s = item.get("source", "?")
        source_counts[s] = source_counts.get(s, 0) + 1

    print(f"\n=== Entries per Upanishad ===")
    total = 0
    for s in sorted(source_counts.keys()):
        print(f"  {s}: {source_counts[s]}")
        total += source_counts[s]
    print(f"\n  TOTAL: {total}")
    print(f"  Upanishads represented: {len(source_counts)}")

    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"\nSaved to {OUTPUT}")


if __name__ == "__main__":
    merged = merge_all()
    validate_and_save(merged)
