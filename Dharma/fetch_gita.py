import requests
from bs4 import BeautifulSoup
import json
import re
import time

def get_speaker(text):
    text_lower = text.lower()
    markers = {
        "Krishna": ["the blessed lord said", "the lord said", "lord said", "lord krishna said", "krishna said"],
        "Arjuna": ["arjuna said", "arjun said"],
        "Sanjaya": ["sanjaya said"],
        "Dhritarashtra": ["dhritarashtra said"]
    }
    for speaker, phrases in markers.items():
        for phrase in phrases:
            if phrase in text_lower:
                return speaker
    return None

CHAPTERS = [
    (1, "Arjuna Vishada Yoga"),
    (2, "Sankhya Yoga"),
    (3, "Karma Yoga"),
    (4, "Jnana Yoga"),
    (5, "Karma Sanyasa Yoga"),
    (6, "Dhyana Yoga"),
    (7, "Vijnana Yoga"),
    (8, "Akshara Parabrahma Yoga"),
    (9, "Raja Vidya Yoga"),
    (10, "Vibhuti Yoga"),
    (11, "Vishwarupa Sandarsana Yoga"),
    (12, "Bhakti Yoga"),
    (13, "Kshetra Kshetrajna Vibhaga Yoga"),
    (14, "Guna Traya Vibhaga Yoga"),
    (15, "Purushottama Yoga"),
    (16, "Daivasura Sampad Vibhaga Yoga"),
    (17, "Shraddha Traya Vibhaga Yoga"),
    (18, "Moksha Sanyasa Yoga"),
]

gita = {"chapters": []}
current_speaker = "Krishna"

for ch_num, ch_title in CHAPTERS:
    url = f"https://vivekavani.com/b{ch_num}/"
    print(f"Fetching Chapter {ch_num}...")
    r = requests.get(url)
    soup = BeautifulSoup(r.text, "html.parser")
    
    content = soup.find("div", class_="entry-content") or soup.find("article")
    items = content.find_all("li") if content else soup.find_all("li")
    
    verses = []
    for item in items:
        text = item.get_text(strip=True)
        
        if not text or len(text) < 20:
            continue
        if "vivekavani.com" in text.lower():
            continue
            
        link = item.find("a")
        ref = ""
        if link and link.get("href"):
            href = link.get("href", "")
            match = re.search(r'b\d+v(\d+)', href)
            if match:
                ref = f"{ch_num}.{match.group(1)}"
        
        bold = item.find(["strong", "em", "b", "i"])
        if bold:
            bold_text = bold.get_text(strip=True).lower()
            detected = get_speaker(bold_text)
            if detected:
                current_speaker = detected
        
        detected = get_speaker(text)
        if detected:
            current_speaker = detected
        
        if ref:
            verses.append({
                "reference": ref,
                "speaker": current_speaker,
                "text": text
            })
    
    gita["chapters"].append({
        "chapter": ch_num,
        "title": ch_title,
        "verses": verses
    })
    
    time.sleep(0.5)

with open("gita.json", "w", encoding="utf-8") as f:
    json.dump(gita, f, indent=2, ensure_ascii=False)

print(f"Done! gita.json written.")
total = sum(len(c["verses"]) for c in gita["chapters"])
print(f"Total verses: {total}")
