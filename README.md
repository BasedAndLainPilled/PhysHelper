# PhysHelper
A lightweight Roblox module to keep unanchored parts awake and responsive. Designed primarily for single player physics heavy games. 

## Features

- Automatically nudges unanchored parts to prevent physics sleep.

- Supports both BasePart and Model (uses PrimaryPart if available).

- Scales nudges based on part mass for consistent motion.

- Optional multiplayer support via network ownership assignment but it might not be stable in multiplayer

- Cleans up automatically when parts are removed.

- Chunked updates to minimize performance impact works smoothly with a large amount of parts.

## Installation
Place PhysHelper.lua in ServerScriptService.
Require it in a Script or ModuleScript:

```lua
local PhysHelper = require(game.ServerScriptService:WaitForChild("PhysHelper"))
```
## API

### PhysHelper:StopSleep(obj)
- Start monitoring a Part. The part will receive nudges when its velocity is below a certain threshold.
```lua
PhysHelper:StopSleep(part)
PhysHelper:StopSleep(model)
```
### PhysHelper:LetSleep(obj)
- Stop monitoring a BasePart or Model. The part will no longer be nudged.
```lua
PhysHelper:LetSleep(part)
```
### PhysHelper:ClearAllWatched()
- Clears all watched parts and resets network ownership.
```lua
PhysHelper:ClearAllWatched()
```

## Configuration
Inside PhysHelper you can change:

- chunkSize: number of parts processed per frame (higher numbr = more perframe load).

- FramesSkip: updates occur every X frames (higher number = less frequent updates).

- thresh: velocity threshold below which parts are nudged.

- nudge: base Vector3 applied per update (scaled by the mass of a part).

- neighborMultiplier: radius multiplier for nearby part detection (used to decide if a part is “active”).

## Disclaimer 
I probably won’t be updating this module. I originally created it for a small project that only needed to handle a few objects at a time, so it’s somewhat overkill now. I also don’t plan to fix any bugs (there are likely a few, since I haven’t done extensive testing). That said, it solves a problem I encountered, and it might be useful for others, which is why I’m sharing it.

