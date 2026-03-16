# Dharma — Xcode Setup Guide

Follow these steps in order. Should take about 20 minutes.

---

## Step 1 — Create the Xcode project

1. Open Xcode
2. File → New → Project
3. Choose: iOS → App
4. Fill in:
   - Product Name: Dharma
   - Team: (your Apple ID — add one in Xcode → Settings → Accounts if needed)
   - Organisation Identifier: com.yourname.dharma
   - Interface: SwiftUI
   - Language: Swift
   - Storage: None (we use SwiftData later)
   - ✅ Include Tests: optional
5. Save it somewhere on your Mac

---

## Step 2 — Delete the default files

Xcode creates placeholder files. Delete these (Move to Trash):
- ContentView.swift  ← we replace this
- (any other auto-generated view files)

Keep:
- DharmaApp.swift  ← we replace this too, but keep the file

---

## Step 3 — Add all Swift files

Drag these files into your Xcode project navigator (left panel):
- DharmaApp.swift
- Theme.swift
- Models.swift
- SampleData.swift
- ContentView.swift
- LibraryView.swift
- ScriptureDetailView.swift
- ScriptureStore.swift
- CalendarView.swift
- FestivalDetailView.swift
- TodayView.swift

When prompted: ✅ Copy items if needed, ✅ Add to target: Dharma

---

## Step 4 — Set up Color Assets

Open Assets.xcassets in Xcode.
Follow the instructions in COLOR_ASSETS_SETUP.md to create each named colour.
This takes about 10 minutes but only needs to be done once.

---

## Step 5 — Run the app

Press ▶ (or Cmd+R) to build and run on the iOS Simulator.
Choose iPhone 15 Pro from the device picker at the top.

You should see a tab bar with Library, Calendar, and Today tabs.

---

## Common errors and fixes

**"Cannot find type 'ScriptureStore' in scope"**
→ Make sure ScriptureStore.swift was added to the Dharma target.
   Click the file, check Target Membership in the right panel.

**"No such module 'SwiftUI'"**
→ Make sure you're targeting iOS 16+.
   Click the Dharma project → General → Deployment Info → iOS 16.0

**Colours showing as black/white**
→ You haven't created the Color Assets yet. Follow Step 4.

**"The file couldn't be opened"**
→ The audio files referenced in SampleData don't exist yet — that's fine.
   The audio player UI will show but not play. Add .mp3 files to your project later.

---

## Next features to add (ask Claude for the code)

1. WidgetKit extension — daily shlok on lock screen
2. Push notifications — festival reminders
3. AVAudioPlayer — wire up the audio player in ScriptureDetailView
4. SwiftData — replace UserDefaults with proper local database
5. Krishna chatbot — Claude API integration (v2)
