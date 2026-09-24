# No Skill Break Timer

A World of Warcraft addon that displays a random meme image whenever a break timer is triggered through DBM, BigWigs, or Blizzard's built-in countdown. Built for WoW Midnight (12.0.1).

## Installation

### WoWUp
Paste the repo URL into WoWUp's **Get Addons** search to install and receive automatic updates.

### Manual
1. Download the zip from the latest [Release](../../releases)
2. Extract the `NoSkillBreakTimer` folder into your WoW addons directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/
   ```
   Your folder structure should look like:
   ```
   World of Warcraft/
   └── _retail_/
       └── Interface/
           └── AddOns/
               └── NoSkillBreakTimer/
                   ├── NoSkillBreakTimer.toc
                   ├── NoSkillBreakTimer.lua
                   └── Memes/
                       ├── Bingo1.tga
                       ├── Cyc1.tga
                       └── ... (etc)
   ```
3. Restart WoW or `/reload` if already in-game

## How It Works

When someone in your group triggers a break timer via `/break`, `/dbm break`, or Blizzard's countdown (60s+), a random meme pops up with a "BREAK TIME" header. The meme stays up for the duration of the break and auto-hides when it ends.

## Slash Commands

| Command | Description |
|---|---|
| `/nsbt` | Open the addon options panel |
| `/nsbt test` | Toggle the meme frame on/off for positioning |
| `/nsbt lock` | Toggle frame lock (prevent moving/resizing) |
| `/nsbt reset` | Reset frame position and size to default |

## Options

Found under **ESC > Options > AddOns > No Skill Break Timer**:

- **Lock/Unlock** — When unlocked, drag the frame to reposition it and use the grip in the bottom-right corner to resize. Lock it when you're happy with the placement.
- **Toggle Test** — Shows the meme frame so you can adjust position and size without needing an actual break timer. Click again to hide.
- **Reset Position** — Resets the frame to default size and center of screen if you lose it.
- **Meme List** — Enable or disable individual memes with checkboxes. Only enabled memes will be shown during breaks. Use the Preview button to see each meme. Select All / Deselect All buttons for quick toggling.

All settings are account-wide and persist between sessions.

## Supported Break Timer Sources

- **BigWigs** — `/break <minutes>`
- **DBM** — `/break <minutes>` or `/dbm break <minutes>`
- **Blizzard Countdown** — `C_PartyInfo.DoCountdown` timers of 60 seconds or longer

## Compatibility

This is a cosmetic/utility addon and is fully compatible with WoW Midnight's addon API restrictions. It does not read or interact with any combat data.

## Releasing

Releases are built automatically by [BigWigsMods/packager](https://github.com/BigWigsMods/packager) (`.github/workflows/release.yml`). Push a tag and a GitHub Release with the packaged zip is created, which WoWUp picks up:

```
git tag v1.1.9
git push origin v1.1.9
```

The tag becomes the addon version (`@project-version@` in the `.toc`).
