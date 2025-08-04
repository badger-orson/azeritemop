# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AzeriteMOP is a custom UI addon for World of Warcraft MoP Classic (5.4.x) that provides an immersive interface with enhanced player/target frames, chat system, and explorer mode functionality. It's a port of the Azerite UI adapted for Mists of Pandaria Classic.

## References

- [World of Warcraft Classic Developer Documentation](https://develop.battle.net/documentation/world-of-warcraft-classic)

## Architecture

### Core System (Core/Core.lua)
- Main addon namespace: `AzeriteMOP`
- Database/SavedVariables: `AzeriteMOPDB`
- Module-based architecture with independent modules for each UI component
- Event-driven initialization system
- Includes addon conflict detection (Bartender4 + DragonflightUI stack overflow prevention)

### Module Structure
Each module follows this pattern:
1. Creates module table: `AzeriteMOP.ModuleName = {}`
2. Has `Initialize()` function called from Core
3. Manages its own frames and events
4. Stores settings in `AzeriteMOP.db.moduleName`

### Active Modules
- **PlayerFrame**: Custom player unit frame with health/power bars
- **TargetFrame**: Custom target unit frame
- **ChatFrame**: Enhanced chat system with fade effects, copy functionality, and emoji support
- **ExplorerMode**: UI hiding system for immersive gameplay

## Development Commands

### Testing & Debugging
```lua
/az test                    -- Test command functionality
/az testscale              -- Test target frame scaling
/az testfontscale          -- Test font scaling on frames
/az fontscale [player|target|all] [scale] -- Set font scale
/az resetfonts [player|target|all]        -- Reset font scales
```

### Frame Management
```lua
/az lock                   -- Toggle frame lock/unlock
/az unlock                 -- Same as lock toggle
/az scale [player|target] [value] -- Set frame scale (0.5-2.0)
/az reset                  -- Reset all frame positions
```

### Explorer Mode
```lua
/explorer on               -- Enable explorer mode
/explorer off              -- Disable explorer mode
/explorer hide             -- Hide UI elements
/explorer show             -- Show UI elements
/explorer debug            -- Toggle debug frames
```

### Chat System
```lua
/az chat toggle            -- Toggle chat frame module
/az chat copy              -- Open copy chat window
/az chat settings          -- Show chat settings
/az chat refresh           -- Refresh chat backgrounds
```

## Key Technical Details

### WoW API Version
- Interface: 50400 (MoP Classic 5.4.x)
- Uses both modern C_Timer API and fallback timer implementations for compatibility

### Saved Variables Structure
```lua
AzeriteMOPDB = {
    playerFrame = {
        enabled = true,
        position = {point, parent, relativePoint, x, y},
        scale = 1.0,
        locked = false
    },
    targetFrame = { -- same structure as playerFrame },
    explorerMode = {
        enabled = true,
        hideQuestLog = true,
        hideChatFrame = true,
        hideMinimap = false,
        hideActionBars = false,
        stationaryDelay = 30.0,
        movementThreshold = 0.1,
        isActive = false
    },
    chatFrame = {
        enabled = true,
        fade = true,
        editboxHide = true,
        addTimestamp = false,
        numScrollMessages = 3,
        scrollDownInterval = 0,
        maxCopyLines = 100,
        showTimestamps = false,
        hideEditBox = true,
        fadeChat = true,
        showEmojis = false,
        showURLs = true,
        showChatBubbles = true
    }
}
```

### Module Loading Order (from .toc)
1. Core/Core.lua
2. Modules/PlayerFrame/PlayerFrame.lua
3. Modules/TargetFrame/TargetFrame.lua
4. Modules/ChatFrame/ChatFrame.lua
5. Modules/ExplorerMode/ExplorerMode.lua

### Frame Naming Convention
- Main frames: `AzeriteMOP[Module]Frame` (e.g., `AzeriteMOPPlayerFrame`)
- Sub-elements: Parent frame name + element (e.g., `AzeriteMOPPlayerFrameHealthBar`)

### Texture Organization
- Main textures in `/Textures/`
- Chat-specific textures in `/Textures/chat/`
- Custom chat bubbles in `/Textures/chat/chatbubbles/`
- Emojis in `/Textures/chat/emoji/`

## Common Development Tasks

### Adding a New Module
1. Create module file in `Modules/ModuleName/ModuleName.lua`
2. Add module table to AzeriteMOP namespace
3. Implement `Initialize()` function
4. Add to .toc file after Core.lua
5. Add initialization call in Core.lua
6. Add database defaults in `EnsureDatabase()` function

### Debugging
- Set `AzeriteMOP.DEBUG = true` in Core.lua for debug output
- Use `AzeriteMOP:Debug(...)` for debug messages
- Check for addon conflicts in Initialize() function

### Working with Saved Variables
- Always check database exists with `EnsureDatabase()`
- Access via `AzeriteMOP.db.moduleName.setting`
- Save positions as: `{point, "UIParent", relativePoint, x, y}`

## Git Workflow
Current branch: `nameplates`
Recent work includes transparent chat window functionality and texture cleanup.

## Important Notes
- The addon detects and prevents loading when conflicting addons (Bartender4 + DragonflightUI) are present
- Nameplate module directory exists but appears to be empty/not implemented yet
- Many texture files were recently deleted (based on git status)
- Debug mode is currently enabled (`AzeriteMOP.DEBUG = true`)

## Memories and Learning

- Comprehensive setup of a World of Warcraft Classic addon involves creating a modular architecture with independent modules for different UI components
- Key components include player/target frames, chat system, and explorer mode functionality
- Saved variables are crucial for maintaining user preferences and addon state
- Debugging and development tools are essential for managing complex addon interactions
- Texture and file organization helps maintain a clean and manageable project structure