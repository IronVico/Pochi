# Pochi 🐶

A small gamified habit tracker for iOS, made for personal use. The app itself is in French.

- **XP and levels**: 10 XP per check-in, +2 XP per day of streak (up to +20), +25 XP for a perfect day.
- **Streaks** 🔥, confetti and a level-up screen.
- **Pochi's doghouse**: a little sketchbook-style patch of land that grows with every level (foundations, walls, roof…), with a tree planted for every perfect day. The sky follows the time of day.
- **Pochi, a doodled corgi** who comments on your day with plenty of sarcasm and changes pose as you go (in a box, on its phone, asleep in its basket, rolled up in a plaid, with its ball or its bowl, in a beanie in winter, happy).
- **Tamagotchi-style needs**: food, happiness and energy drop on their own and your check-ins fill them back up. Neglect your habits for a few days and Pochi sulks under a rain cloud.
- **Apple Health** (read-only, optional): steps, exercise, workouts, sleep and mindfulness. A habit can be linked to one of them with a goal, and checks itself once the goal is reached. Sleep and activity also nudge Pochi's energy.
- **Calendar** of the last 5 weeks for each habit, to fix a forgotten check-in.

SwiftUI + SwiftData, iOS 18+. Data stays on the device; Pochi never writes to Health.

## Running the app

1. Open `Pochi.xcodeproj` in Xcode.
2. *Signing & Capabilities* → pick your Apple ID under **Team**.
3. Choose a simulator or your iPhone, then ▶︎.

With a free Apple ID, the app installed on an iPhone expires after 7 days: just run it again from Xcode.

## Debug launch arguments

Debug builds accept a few launch arguments (*Product → Scheme → Edit Scheme… → Run → Arguments*):

| Argument | Effect |
| --- | --- |
| `-seedDemo` | Replaces the data with sample habits. |
| `-seedNeglected` | Same sample habits, abandoned for 4 days. |
| `-fakeHealth` | Shows sample Health numbers (the simulator has no Health data). |
| `-debugHour 21` | Draws the doghouse scene at another time of day. |
| `-levelUp` | Shows the level-up screen. |
| `-corgiGallery`, `-nicheGallery`, `-iconGallery` | Opens a gallery of Pochi's poses, the doghouse stages or the icons. |

## App icon

The icon is generated from Pochi's head sprite:

```bash
swift Scripts/make_icon.swift Pochi/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```
