#!/usr/bin/env python3
"""
Merge upstream gita/gita verse.json + translation.json into this project's `Dharma/gita.json`.

The upstream data contains:
- verse.json: Sanskrit + transliteration + word meanings (per verse)
- translation.json: translations by author/language (per verse)

This script outputs an app-compatible structure:
{
  "chapters": [
    {
      "chapter": 1,
      "title": "...",   // taken from existing Dharma/gita.json when available
      "verses": [
        {
          "reference": "1.1",
          "speaker": "Dhritarashtra",
          "text": "<english translation text>", // existing app expects this
          // plus extra fields from upstream:
          "chapter": 1,
          "verse": 1,
          "sanskrit": "...",
          "transliteration": "...",
          "wordMeanings": "...",
          "english": "...",
          "hindi": "..."
        }
      ]
    }
  ]
}
"""

from __future__ import annotations

import argparse
import copy
import datetime as _dt
import json
import os
import re
import shutil
import sys
import urllib.request
from typing import Any, Dict, Optional, Tuple


VERSE_URL_DEFAULT = "https://raw.githubusercontent.com/gita/gita/main/data/verse.json"
TRANSLATION_URL_DEFAULT = "https://raw.githubusercontent.com/gita/gita/main/data/translation.json"


def _read_json_from_path(path: str) -> Any:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _read_json_from_url(url: str) -> Any:
    with urllib.request.urlopen(url) as resp:
        raw = resp.read().decode("utf-8")
    return json.loads(raw)


def _maybe_strip(s: Any) -> str:
    if s is None:
        return ""
    if isinstance(s, str):
        return s.strip()
    return str(s).strip()


def _parse_speaker_from_english(english: str) -> str:
    """
    Upstream english translation descriptions generally start like:
    "Dhritarashtra said, ..." or "Sanjaya said: ..."
    """
    if not english:
        return ""
    s = english.replace("\n", " ").strip()

    # Capture "Speaker" before a common speech verb.
    m = re.match(
        r'^([A-Za-z][A-Za-z\s\'.-]*?)\s+(?:said|spoke|asked|answered|replied|declared)\b',
        s,
        flags=re.IGNORECASE,
    )
    if m:
        return m.group(1).strip()
    return ""


def _parse_speaker_from_word_meanings(word_meanings: str) -> str:
    """
    word_meanings often looks like:
    "dhṛitarāśhtraḥ uvācha—Dhritarashtra said; ..."
    so we attempt to grab the English speaker after the em-dash.
    """
    if not word_meanings:
        return ""
    s = word_meanings.replace("\n", " ").strip()
    # Anything before the first em-dash is the transliterated subject; we want after that.
    m = re.search(
        r'—\s*([A-Za-z][A-Za-z\s\'.-]*?)\s+(?:said|spoke|asked|answered|replied|declared)\b',
        s,
        flags=re.IGNORECASE,
    )
    if m:
        return m.group(1).strip()
    return ""


def _load_existing_gita_mapping(existing_gita_path: str) -> Tuple[Dict[int, str], Dict[str, str]]:
    """
    Returns:
    - chapter_titles: {chapter_number: title}
    - speaker_by_reference: {"1.1": "Dhritarashtra", ...}
    """
    chapter_titles: Dict[int, str] = {}
    speaker_by_reference: Dict[str, str] = {}

    if not existing_gita_path or not os.path.exists(existing_gita_path):
        return chapter_titles, speaker_by_reference

    existing = _read_json_from_path(existing_gita_path)
    chapters = existing.get("chapters", [])
    for ch in chapters:
        ch_num = ch.get("chapter")
        if isinstance(ch_num, int):
            chapter_titles[ch_num] = ch.get("title", f"Chapter {ch_num}")

        for v in ch.get("verses", []):
            ref = v.get("reference")
            speaker = v.get("speaker")
            if isinstance(ref, str) and isinstance(speaker, str) and ref:
                speaker_by_reference[ref] = speaker

    return chapter_titles, speaker_by_reference


def _ensure_backup(path: str) -> None:
    if not os.path.exists(path):
        return
    ts = _dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{path}.bak.{ts}"
    shutil.copy2(path, backup_path)
    print(f"Backed up existing gita.json to: {backup_path}", file=sys.stderr)


def main() -> int:
    parser = argparse.ArgumentParser(description="Merge upstream gita data into Dharma/gita.json")
    parser.add_argument("--verse-json", default="", help="Local path to upstream verse.json (optional)")
    parser.add_argument("--translation-json", default="", help="Local path to upstream translation.json (optional)")
    parser.add_argument("--verse-url", default=VERSE_URL_DEFAULT, help="Upstream verse.json URL")
    parser.add_argument("--translation-url", default=TRANSLATION_URL_DEFAULT, help="Upstream translation.json URL")
    parser.add_argument("--out", default=os.path.join("Dharma", "gita.json"), help="Output path")
    parser.add_argument("--english-author-id", type=int, default=16, help="Swami Sivananda author_id (english)")
    parser.add_argument("--hindi-author-id", type=int, default=1, help="Swami Ramsukhdas author_id (hindi)")
    parser.add_argument(
        "--existing-gita",
        default="",
        help="Optional path to an existing Dharma gita.json for chapter titles/speaker mapping (optional)",
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Do not create a backup before overwriting --out",
    )
    args = parser.parse_args()

    out_path = args.out
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)

    existing_path = args.existing_gita or out_path
    chapter_titles, speaker_by_ref = _load_existing_gita_mapping(existing_path)

    # Load upstream JSON
    if args.verse_json:
        verse_data = _read_json_from_path(args.verse_json)
    else:
        verse_data = _read_json_from_url(args.verse_url)

    if args.translation_json:
        translation_data = _read_json_from_path(args.translation_json)
    else:
        translation_data = _read_json_from_url(args.translation_url)

    if not isinstance(verse_data, list):
        raise ValueError("Expected upstream verse.json to be a list")
    if not isinstance(translation_data, list):
        raise ValueError("Expected upstream translation.json to be a list")

    # Build translation lookup by verse_id.
    # translation.json items have: lang ("english"/"hindi"), author_id, verse_id, description
    english_by_verse_id: Dict[int, str] = {}
    hindi_by_verse_id: Dict[int, str] = {}

    for t in translation_data:
        if not isinstance(t, dict):
            continue
        verse_id = t.get("verse_id")
        if not isinstance(verse_id, int):
            continue
        lang = t.get("lang")
        author_id = t.get("author_id")
        desc = t.get("description")
        if not isinstance(desc, str):
            continue

        if lang == "english" and author_id == args.english_author_id:
            english_by_verse_id[verse_id] = desc
        elif lang == "hindi" and author_id == args.hindi_author_id:
            hindi_by_verse_id[verse_id] = desc

    # Create chapters
    chapters: Dict[int, Dict[str, Any]] = {}

    # Sort verses by chapter + verse_order for deterministic output.
    def sort_key(v: Dict[str, Any]) -> Tuple[int, int]:
        ch = v.get("chapter_number") or 0
        vo = v.get("verse_order") or v.get("verse_number") or 0
        return (int(ch), int(vo))

    verse_entries: list[Dict[str, Any]] = [v for v in verse_data if isinstance(v, dict)]
    verse_entries.sort(key=sort_key)

    for v in verse_entries:
        verse_id = v.get("id")
        chapter_num = v.get("chapter_number")
        verse_num = v.get("verse_number")

        if not isinstance(verse_id, int) or not isinstance(chapter_num, int) or not isinstance(verse_num, int):
            continue

        chapter = chapter_num
        verse = verse_num
        reference = f"{chapter}.{verse}"

        if chapter not in chapters:
            chapters[chapter] = {
                "chapter": chapter,
                "title": chapter_titles.get(chapter, f"Chapter {chapter}"),
                "verses": [],
            }

        sanskrit = _maybe_strip(v.get("text"))
        transliteration = _maybe_strip(v.get("transliteration"))
        word_meanings = _maybe_strip(v.get("word_meanings"))

        english = _maybe_strip(english_by_verse_id.get(verse_id, ""))
        hindi = _maybe_strip(hindi_by_verse_id.get(verse_id, ""))

        speaker = speaker_by_ref.get(reference) or _parse_speaker_from_english(english) or _parse_speaker_from_word_meanings(word_meanings)
        if not speaker:
            speaker = "Krishna"  # last-resort fallback so the app never shows empty speaker

        chapters[chapter]["verses"].append(
            {
                # Compatibility fields for this app:
                "reference": reference,
                "speaker": speaker,
                "text": english,

                # Your requested "clean" verse fields:
                "chapter": chapter,
                "verse": verse,
                "sanskrit": sanskrit,
                "transliteration": transliteration,
                "wordMeanings": word_meanings,
                "english": english,
                "hindi": hindi,
            }
        )

    output = {"chapters": [chapters[c] for c in sorted(chapters.keys())]}

    if not args.no_backup:
        _ensure_backup(out_path)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    # A quick sanity print (not exhaustive)
    total_verses = sum(len(ch["verses"]) for ch in output["chapters"])
    print(f"Wrote {len(output['chapters'])} chapters with {total_verses} verses to: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

