-- AzeriteMOP Core Framework
-- MoP Classic Port of Azerite UI Player Frame

local ADDON_NAME, Addon = ...

-- Create our main addon object
AzeriteMOP = AzeriteMOP or {}
local AzeriteMOP = AzeriteMOP

-- Store addon reference
Addon.AzeriteMOP = AzeriteMOP

-- Debug flag for development
AzeriteMOP.DEBUG = true

-- Simple debug print function
function AzeriteMOP:Debug(...)
    if self.DEBUG then
        print("|cFF4488FF[AzeriteMOP]|r", ...)
    end
end

-- Helper function to ensure database is properly initialized
function AzeriteMOP:EnsureDatabase()
    if not self.db then
        self:Debug("Database not initialized, creating default values")
        self.db = {}
    end
    
    if not self.db.playerFrame then
        self:Debug("Creating playerFrame in database")
        self.db.playerFrame = {
            enabled = true,
            position = { "CENTER", UIParent, "CENTER", 0, -150 },
            scale = 1.0,
            locked = false
        }
    end
    
    if not self.db.targetFrame then
        self:Debug("Creating targetFrame in database")
        self.db.targetFrame = {
            enabled = true,
            position = { "CENTER", UIParent, "CENTER", 0, 150 },
            scale = 1.0,
            locked = false
        }
    end
    
    -- Ensure sub-fields exist
    if not self.db.playerFrame.position then
        self.db.playerFrame.position = { "CENTER", UIParent, "CENTER", 0, -150 }
    end
    if not self.db.playerFrame.scale then
        self.db.playerFrame.scale = 1.0
    end
    if not self.db.playerFrame.locked then
        self.db.playerFrame.locked = false
    end
    
    if not self.db.targetFrame.position then
        self.db.targetFrame.position = { "CENTER", UIParent, "CENTER", 0, 150 }
    end
    if not self.db.targetFrame.scale then
        self.db.targetFrame.scale = 1.0
    end
    if not self.db.targetFrame.locked then
        self.db.targetFrame.locked = false
    end
    
    self:Debug("EnsureDatabase complete - playerFrame: " .. tostring(self.db.playerFrame ~= nil) .. ", targetFrame: " .. tostring(self.db.targetFrame ~= nil))
end

-- Event frame for handling addon events
AzeriteMOP.eventFrame = CreateFrame("Frame")

-- Initialize function
function AzeriteMOP:Initialize()
    self:Debug("Initializing AzeriteMOP...")
    
    -- Set up saved variables with defaults
    if not AzeriteMOPDB then
        AzeriteMOPDB = {}
    end
    
    -- Ensure all required fields exist with defaults
    if not AzeriteMOPDB.playerFrame then
        AzeriteMOPDB.playerFrame = {
            enabled = true,
            position = { "CENTER", UIParent, "CENTER", 0, -150 },
            scale = 1.0,
            locked = false
        }
    end
    
    if not AzeriteMOPDB.targetFrame then
        AzeriteMOPDB.targetFrame = {
            enabled = true,
            position = { "CENTER", UIParent, "CENTER", 0, 150 },
            scale = 1.0,
            locked = false
        }
    end
    
    -- Ensure all sub-fields exist
    if not AzeriteMOPDB.playerFrame.position then
        AzeriteMOPDB.playerFrame.position = { "CENTER", UIParent, "CENTER", 0, -150 }
    end
    if not AzeriteMOPDB.playerFrame.scale then
        AzeriteMOPDB.playerFrame.scale = 1.0
    end
    if not AzeriteMOPDB.playerFrame.locked then
        AzeriteMOPDB.playerFrame.locked = false
    end
    
    if not AzeriteMOPDB.targetFrame.position then
        AzeriteMOPDB.targetFrame.position = { "CENTER", UIParent, "CENTER", 0, 150 }
    end
    if not AzeriteMOPDB.targetFrame.scale then
        AzeriteMOPDB.targetFrame.scale = 1.0
    end
    if not AzeriteMOPDB.targetFrame.locked then
        AzeriteMOPDB.targetFrame.locked = false
    end
    
    self.db = AzeriteMOPDB
    
    -- Debug database state
    self:Debug("Database initialized - playerFrame exists: " .. tostring(self.db.playerFrame ~= nil))
    self:Debug("Database initialized - targetFrame exists: " .. tostring(self.db.targetFrame ~= nil))
    
    -- Initialize modules
    if self.PlayerFrame then
        self.PlayerFrame:Initialize()
    else
        self:Debug("PlayerFrame module not found!")
    end
    
    if self.TargetFrame then
        self.TargetFrame:Initialize()
    else
        self:Debug("TargetFrame module not found!")
    end
    
    -- Set up slash commands
    self:SetupSlashCommands()
    
    self:Debug("AzeriteMOP initialized successfully!")
end

-- Slash command handler
function AzeriteMOP:SetupSlashCommands()
    -- Register slash commands with unique names
    SLASH_AZERITEMOP1 = "/azlock"
    SLASH_AZERITEMOP2 = "/azeritemop"
    SLASH_AZERITEMOP3 = "/azmop"
    
    SlashCmdList["AZERITEMOP"] = function(msg)
        AzeriteMOP:HandleSlashCommand(msg)
    end
    
    self:Debug("Slash commands registered: /azlock, /azeritemop, /azmop")
end

function AzeriteMOP:HandleSlashCommand(msg)
    self:Debug("Slash command received: " .. (msg or "nil"))
    
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    local command = string.lower(args[1] or "")
    self:Debug("Command: " .. command)
    
    if command == "lock" or command == "unlock" then
        self:ToggleFrameLock()
    elseif command == "scale" then
        self:HandleScaleCommand(args)
    elseif command == "reset" then
        self:ResetFramePositions()
    elseif command == "help" then
        self:ShowHelp()
    elseif command == "test" then
        print("|cFF4488FF[AzeriteMOP]|r Test command works!")
        self:Debug("Test command executed successfully")
    elseif command == "testscale" then
        if self.TargetFrame then
            self.TargetFrame:TestScaling()
            print("|cFF4488FF[AzeriteMOP]|r Target frame scaling test applied!")
        else
            print("|cFF4488FF[AzeriteMOP]|r TargetFrame module not found!")
        end
    elseif command == "testfontscale" then
        if self.PlayerFrame then
            self.PlayerFrame:ScaleFonts(1.5)
            print("|cFF4488FF[AzeriteMOP]|r Player frame font scaling test applied!")
        else
            print("|cFF4488FF[AzeriteMOP]|r PlayerFrame module not found!")
        end
        if self.TargetFrame then
            self.TargetFrame:ScaleFonts(1.5)
            print("|cFF4488FF[AzeriteMOP]|r Target frame font scaling test applied!")
        else
            print("|cFF4488FF[AzeriteMOP]|r TargetFrame module not found!")
        end
    elseif command == "fontscale" then
        self:HandleFontScaleCommand(args)
    elseif command == "resetfonts" then
        local frameType = string.lower(args[2] or "all")
        
        if frameType == "player" or frameType == "all" then
            if self.PlayerFrame then
                self.PlayerFrame:ResetFonts()
                print("|cFF4488FF[AzeriteMOP]|r Player frame fonts reset to default!")
            else
                print("|cFF4488FF[AzeriteMOP]|r PlayerFrame module not found!")
            end
        end
        
        if frameType == "target" or frameType == "all" then
            if self.TargetFrame then
                self.TargetFrame:ResetFonts()
                print("|cFF4488FF[AzeriteMOP]|r Target frame fonts reset to default!")
            else
                print("|cFF4488FF[AzeriteMOP]|r TargetFrame module not found!")
            end
        end
    elseif command == "testdb" then
        self:EnsureDatabase()
        print("|cFF4488FF[AzeriteMOP]|r Database test - playerFrame exists: " .. tostring(self.db.playerFrame ~= nil))
        print("|cFF4488FF[AzeriteMOP]|r Database test - targetFrame exists: " .. tostring(self.db.targetFrame ~= nil))
        if self.db.playerFrame then
            print("|cFF4488FF[AzeriteMOP]|r Player frame locked: " .. tostring(self.db.playerFrame.locked))
        end
        if self.db.targetFrame then
            print("|cFF4488FF[AzeriteMOP]|r Target frame locked: " .. tostring(self.db.targetFrame.locked))
        end
    elseif command == "resetdb" then
        -- Completely reset the saved variables
        AzeriteMOPDB = nil
        self.db = nil
        self:EnsureDatabase()
        print("|cFF4488FF[AzeriteMOP]|r Database completely reset and reinitialized")
        print("|cFF4488FF[AzeriteMOP]|r playerFrame exists: " .. tostring(self.db.playerFrame ~= nil))
        print("|cFF4488FF[AzeriteMOP]|r targetFrame exists: " .. tostring(self.db.targetFrame ~= nil))
    elseif command == "checkdb" then
        -- Check the current state of saved variables
        print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPDB exists: " .. tostring(AzeriteMOPDB ~= nil))
        if AzeriteMOPDB then
            print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPDB.playerFrame exists: " .. tostring(AzeriteMOPDB.playerFrame ~= nil))
            print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPDB.targetFrame exists: " .. tostring(AzeriteMOPDB.targetFrame ~= nil))
        end
        print("|cFF4488FF[AzeriteMOP]|r self.db exists: " .. tostring(self.db ~= nil))
        if self.db then
            print("|cFF4488FF[AzeriteMOP]|r self.db.playerFrame exists: " .. tostring(self.db.playerFrame ~= nil))
            print("|cFF4488FF[AzeriteMOP]|r self.db.targetFrame exists: " .. tostring(self.db.targetFrame ~= nil))
        end
    else
        self:ShowHelp()
    end
end

function AzeriteMOP:ToggleFrameLock()
    self:Debug("ToggleFrameLock called")
    
    -- Ensure database is properly initialized
    self:EnsureDatabase()
    
    self:Debug("Before toggle - playerFrame.locked: " .. tostring(self.db.playerFrame.locked))
    self:Debug("Before toggle - targetFrame.locked: " .. tostring(self.db.targetFrame.locked))
    
    local newLockState = not self.db.playerFrame.locked
    self.db.playerFrame.locked = newLockState
    self.db.targetFrame.locked = newLockState
    
    self:Debug("After toggle - newLockState: " .. tostring(newLockState))
    
    self:Debug("New lock state: " .. tostring(newLockState))
    
    -- Update frame movable states
    if self.PlayerFrame and self.PlayerFrame.frame then
        self.PlayerFrame.frame:SetMovable(not newLockState)
        self.PlayerFrame.frame:EnableMouse(not newLockState)
        self:Debug("Updated PlayerFrame movable state")
    else
        self:Debug("PlayerFrame not found")
    end
    
    if self.TargetFrame and self.TargetFrame.frame then
        self.TargetFrame.frame:SetMovable(not newLockState)
        self.TargetFrame.frame:EnableMouse(not newLockState)
        self:Debug("Updated TargetFrame movable state")
    else
        self:Debug("TargetFrame not found")
    end
    
    local status = newLockState and "locked" or "unlocked"
    self:Debug("Frames " .. status)
    print("|cFF4488FF[AzeriteMOP]|r Frames " .. status)
end

function AzeriteMOP:HandleScaleCommand(args)
    local frameType = string.lower(args[2] or "all")
    local scale = tonumber(args[3])
    
    if not scale or scale < 0.1 or scale > 3.0 then
        print("|cFF4488FF[AzeriteMOP]|r Usage: /azlock scale [player|target|all] [0.1-3.0]")
        print("|cFF4488FF[AzeriteMOP]|r Example: /azlock scale all 1.2")
        return
    end
    
    -- Ensure database is properly initialized
    self:EnsureDatabase()
    
    if frameType == "player" or frameType == "all" then
        self.db.playerFrame.scale = scale
        if self.PlayerFrame and self.PlayerFrame.frame then
            self.PlayerFrame.frame:SetScale(scale)
        end
        print("|cFF4488FF[AzeriteMOP]|r Player frame scaled to " .. scale)
    end
    
    if frameType == "target" or frameType == "all" then
        self.db.targetFrame.scale = scale
        if self.TargetFrame then
            self.TargetFrame:ApplyScaling(scale)
        end
        print("|cFF4488FF[AzeriteMOP]|r Target frame scaled to " .. scale)
    end
end

function AzeriteMOP:HandleFontScaleCommand(args)
    local frameType = string.lower(args[2] or "all")
    local scale = tonumber(args[3])
    
    if not scale or scale < 0.5 or scale > 3.0 then
        print("|cFF4488FF[AzeriteMOP]|r Usage: /azlock fontscale [player|target|all] [0.5-3.0]")
        print("|cFF4488FF[AzeriteMOP]|r Example: /azlock fontscale all 1.5")
        return
    end
    
    if frameType == "player" or frameType == "all" then
        if self.PlayerFrame then
            self.PlayerFrame:ScaleFonts(scale)
            print("|cFF4488FF[AzeriteMOP]|r Player frame fonts scaled to " .. scale)
        else
            print("|cFF4488FF[AzeriteMOP]|r PlayerFrame module not found!")
        end
    end
    
    if frameType == "target" or frameType == "all" then
        if self.TargetFrame then
            self.TargetFrame:ScaleFonts(scale)
            print("|cFF4488FF[AzeriteMOP]|r Target frame fonts scaled to " .. scale)
        else
            print("|cFF4488FF[AzeriteMOP]|r TargetFrame module not found!")
        end
    end
end

function AzeriteMOP:ResetFramePositions()
    -- Ensure database is properly initialized
    self:EnsureDatabase()
    
    -- Reset to default positions
    self.db.playerFrame.position = { "CENTER", UIParent, "CENTER", 0, -150 }
    self.db.targetFrame.position = { "CENTER", UIParent, "CENTER", 0, 150 }
    
    -- Reset scales
    self.db.playerFrame.scale = 1.0
    self.db.targetFrame.scale = 1.0
    
    -- Apply to frames
    if self.PlayerFrame and self.PlayerFrame.frame then
        self.PlayerFrame.frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
        self.PlayerFrame.frame:SetScale(1.0)
    end
    
    if self.TargetFrame then
        self.TargetFrame.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        self.TargetFrame:ApplyScaling(1.0)
    end
    
    print("|cFF4488FF[AzeriteMOP]|r Frame positions and scales reset to default")
end

function AzeriteMOP:ShowHelp()
    print("|cFF4488FF[AzeriteMOP]|r Commands:")
    print("  /azlock - Toggle frame lock (movable/immovable)")
    print("  /azlock scale [player|target|all] [0.1-3.0] - Scale frames")
    print("  /azlock fontscale [player|target|all] [0.5-3.0] - Scale fonts")
    print("  /azlock resetfonts [player|target|all] - Reset fonts to default size")
    print("  /azlock reset - Reset frame positions and scales")
    print("  /azlock testscale - Test target frame scaling")
    print("  /azlock testfontscale - Test font scaling on both frames")
    print("  /azlock testdb - Test database initialization")
    print("  /azlock resetdb - Reset database completely")
    print("  /azlock checkdb - Check database state")
    print("  /azlock help - Show this help")
    print("")
    print("Examples:")
    print("  /azlock scale all 1.2 - Scale all frames to 120%")
    print("  /azlock scale player 0.8 - Scale player frame to 80%")
    print("  /azlock scale target 1.5 - Scale target frame to 150%")
    print("  /azlock fontscale all 1.3 - Scale all fonts to 130%")
    print("  /azlock fontscale player 1.2 - Scale player fonts to 120%")
    print("  /azlock fontscale target 1.4 - Scale target fonts to 140%")
    print("  /azlock resetfonts all - Reset all fonts to default")
    print("  /azlock resetfonts player - Reset player fonts to default")
    print("  /azlock resetfonts target - Reset target fonts to default")
end

-- Handle addon loading
AzeriteMOP.eventFrame:RegisterEvent("ADDON_LOADED")
AzeriteMOP.eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        AzeriteMOP:Initialize()
        AzeriteMOP.eventFrame:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Utility function to check if we're in MoP Classic
function AzeriteMOP:IsMoPClassic()
    local version = select(4, GetBuildInfo())
    return version >= 50400 and version < 60000
end

-- Safety check
if not AzeriteMOP:IsMoPClassic() then
    error("AzeriteMOP: This addon is designed for MoP Classic (5.4.x) only!")
end