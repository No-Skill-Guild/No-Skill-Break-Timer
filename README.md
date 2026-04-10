# No Skill Break Timer

Displays a random meme image whenever a break timer is triggered through DBM, BigWigs, or Blizzard's built-in countdown. Built for WoW Midnight (12.0.1).

## Installation

1. Download or clone this repo
2. Copy the `NoSkillBreakTimer` folder into your WoW addons directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/
   ```
3. Copy the `Memes` folder into your WoW Interface directory:
   ```
   World of Warcraft/_retail_/Interface/
   ```
   Your folder structure should look like:
   ```
   World of Warcraft/
   └── _retail_/
       └── Interface/
           ├── AddOns/
           │   └── NoSkillBreakTimer/
           │       ├── NoSkillBreakTimer.toc
           │       └── NoSkillBreakTimer.lua
           └── Memes/
               ├── Bingo1.tga
               ├── Cyc1.tga
               ├── Elijah1.tga
               └── ... (etc)
   ```
4. Restart WoW or `/reload` if already in-game

## How It Works

When someone in your group triggers a break timer via `/dbm break`, BigWigs, or Blizzard's countdown (60s+), a random meme pops up with a "BREAK TIME" header. The meme stays up for the duration of the break and auto-hides when it ends.

## Slash Commands

| Command | Description |
|---|---|
| `/nsbt` | Open the addon options panel |
| `/nsbt test` | Toggle the meme frame on/off for positioning |
| `/nsbt lock` | Toggle frame lock (prevent moving/resizing) |

## Options

Found under **ESC > Options > AddOns > No Skill Break Timer**:

- **Lock/Unlock** — When unlocked, drag the frame to reposition it and use the grip in the bottom-right corner to resize. Lock it when you're happy with the placement.
- **Toggle Test** — Shows the meme frame so you can adjust position and size without needing an actual break timer. Click again to hide.

Position and size are saved between sessions.

## Supported Break Timer Sources

- **DBM** — `/dbm break <minutes>` (direct API hook + addon message listener)
- **BigWigs** — Break bar callbacks
- **Blizzard Countdown** — `C_PartyInfo.DoCountdown` timers of 60 seconds or longer

## Compatibility

This is a cosmetic/utility addon and is fully compatible with WoW Midnight's addon API restrictions. It does not read or interact with any combat data.
