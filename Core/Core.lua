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
        -- self:Debug("Database not initialized, creating default values")
        self.db = {}
    end
    
    if not self.db.playerFrame then
        -- self:Debug("Creating playerFrame in database")
        self.db.playerFrame = {
            enabled = true,
            position = { "CENTER", UIParent, "CENTER", 0, -150 },
            scale = 1.0,
            locked = false
        }
    end
    
    if not self.db.targetFrame then
        -- self:Debug("Creating targetFrame in database")
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
    
    if not self.db.explorerMode then
        -- self:Debug("Creating explorerMode in database")
        self.db.explorerMode = {
            enabled = true,
            hideQuestLog = true,
            hideChatFrame = true,
            hideMinimap = false,
            hideActionBars = false,
            stationaryDelay = 30.0,
            movementThreshold = 0.1
        }
    end
    
    -- self:Debug("EnsureDatabase complete - playerFrame: " .. tostring(self.db.playerFrame ~= nil) .. ", targetFrame: " .. tostring(self.db.targetFrame ~= nil) .. ", explorerMode: " .. tostring(self.db.explorerMode ~= nil))
end

-- Event frame for handling addon events
AzeriteMOP.eventFrame = CreateFrame("Frame")

-- Initialize function
function AzeriteMOP:Initialize()
    -- self:Debug("Initializing AzeriteMOP...")
    
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
    
                if not AzeriteMOPDB.explorerMode then
        AzeriteMOPDB.explorerMode = {
            enabled = true,
            hideQuestLog = true,
            hideChatFrame = true,
            hideMinimap = false,
            hideActionBars = false,
            stationaryDelay = 30.0,
            movementThreshold = 0.1,
            isActive = false
        }
    end
    
    self.db = AzeriteMOPDB
    
    -- Debug database state
    -- self:Debug("Database initialized - playerFrame exists: " .. tostring(self.db.playerFrame ~= nil))
    -- self:Debug("Database initialized - targetFrame exists: " .. tostring(self.db.targetFrame ~= nil))
    
    -- Initialize modules
    if self.PlayerFrame then
        self.PlayerFrame:Initialize()
    else
        -- self:Debug("PlayerFrame module not found!")
    end
    
    if self.TargetFrame then
        self.TargetFrame:Initialize()
    else
        -- self:Debug("TargetFrame module not found!")
    end
    
    if self.ExplorerMode then
        self.ExplorerMode:Initialize()
    else
        -- self:Debug("ExplorerMode module not found!")
    end
    
    -- Set up slash commands
    self:SetupSlashCommands()
    
    -- self:Debug("AzeriteMOP initialized successfully!")
end

-- Slash command handler
function AzeriteMOP:SetupSlashCommands()
    -- Register slash commands with unique names
    SLASH_AZERITEMOP1 = "/az"
    SLASH_AZERITEMOP2 = "/azeritemop"
    SLASH_AZERITEMOP3 = "/azmop"
    
    SlashCmdList["AZERITEMOP"] = function(msg)
        AzeriteMOP:HandleSlashCommand(msg)
    end
    
    -- self:Debug("Slash commands registered: /az, /azeritemop, /azmop")
end

function AzeriteMOP:HandleSlashCommand(msg)
    -- self:Debug("Slash command received: " .. (msg or "nil"))
    
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    local command = string.lower(args[1] or "")
    -- self:Debug("Command: " .. command)
    
    if command == "lock" or command == "unlock" then
        self:ToggleFrameLock()
    elseif command == "scale" then
        self:HandleScaleCommand(args)
    elseif command == "reset" then
        self:ResetFramePositions()
    elseif command == "help" then
        self:ShowHelp()
    elseif command == "test" then
        -- print("|cFF4488FF[AzeriteMOP]|r Test command works!")
        -- self:Debug("Test command executed successfully")
    elseif command == "testscale" then
        if self.TargetFrame then
            self.TargetFrame:TestScaling()
            -- print("|cFF4488FF[AzeriteMOP]|r Target frame scaling test applied!")
        else
            -- print("|cFF4488FF[AzeriteMOP]|r TargetFrame module not found!")
        end
    elseif command == "testfontscale" then
        if self.PlayerFrame then
            self.PlayerFrame:ScaleFonts(1.5)
            -- print("|cFF4488FF[AzeriteMOP]|r Player frame font scaling test applied!")
        else
            -- print("|cFF4488FF[AzeriteMOP]|r PlayerFrame module not found!")
        end
        if self.TargetFrame then
            self.TargetFrame:ScaleFonts(1.5)
            -- print("|cFF4488FF[AzeriteMOP]|r Target frame font scaling test applied!")
        else
            -- print("|cFF4488FF[AzeriteMOP]|r TargetFrame module not found!")
        end
    elseif command == "fontscale" then
        self:HandleFontScaleCommand(args)
    elseif command == "resetfonts" then
        local frameType = string.lower(args[2] or "all")
        
        if frameType == "player" or frameType == "all" then
            if self.PlayerFrame then
                self.PlayerFrame:ResetFonts()
                -- print("|cFF4488FF[AzeriteMOP]|r Player frame fonts reset to default!")
            else
                -- print("|cFF4488FF[AzeriteMOP]|r PlayerFrame module not found!")
            end
        end
        
        if frameType == "target" or frameType == "all" then
            if self.TargetFrame then
                self.TargetFrame:ResetFonts()
                -- print("|cFF4488FF[AzeriteMOP]|r Target frame fonts reset to default!")
            else
                -- print("|cFF4488FF[AzeriteMOP]|r TargetFrame module not found!")
            end
        end
    elseif command == "testdb" then
        self:EnsureDatabase()
        -- print("|cFF4488FF[AzeriteMOP]|r Database test - playerFrame exists: " .. tostring(self.db.playerFrame ~= nil))
        -- print("|cFF4488FF[AzeriteMOP]|r Database test - targetFrame exists: " .. tostring(self.db.targetFrame ~= nil))
        -- print("|cFF4488FF[AzeriteMOP]|r Database test - explorerMode exists: " .. tostring(self.db.explorerMode ~= nil))
        -- if self.db.playerFrame then
        --     print("|cFF4488FF[AzeriteMOP]|r Player frame locked: " .. tostring(self.db.playerFrame.locked))
        -- end
        -- if self.db.targetFrame then
        --     print("|cFF4488FF[AzeriteMOP]|r Target frame locked: " .. tostring(self.db.targetFrame.locked))
        -- end
        -- if self.db.explorerMode then
        --     print("|cFF4488FF[AzeriteMOP]|r Explorer mode enabled: " .. tostring(self.db.explorerMode.enabled))
        -- end
    elseif command == "resetdb" then
        -- Completely reset the saved variables
        AzeriteMOPDB = nil
        self.db = nil
        self:EnsureDatabase()
        -- print("|cFF4488FF[AzeriteMOP]|r Database completely reset and reinitialized")
    elseif command == "explorer" then
        local subCommand = string.lower(args[2] or "")
        if subCommand == "debug" then
            if self.ExplorerMode then
                self.ExplorerMode:DebugInfo()
            else
                print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
            end
        elseif subCommand == "checkdelay" then
            if self.ExplorerMode then
                self.ExplorerMode:CheckDelayValue()
            else
                print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
            end
        elseif subCommand == "resetdelay" then
            if self.ExplorerMode then
                self.ExplorerMode:ResetStationaryDelay()
            else
                print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
            end
        elseif subCommand == "enable" then
            if self.ExplorerMode then
                self.ExplorerMode:ForceEnable()
            else
                print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
            end
        elseif subCommand == "disable" then
            if self.ExplorerMode then
                self.ExplorerMode:ForceDisable()
            else
                print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
            end
        elseif subCommand == "setdelay" then
            local seconds = tonumber(args[3])
            if seconds and seconds > 0 then
                if self.ExplorerMode then
                    self.ExplorerMode:SetStationaryDelay(seconds)
                    print("|cFF4488FF[AzeriteMOP]|r Stationary delay set to " .. seconds .. " seconds")
                else
                    print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
                end
            else
                print("|cFF4488FF[AzeriteMOP]|r Usage: /az explorer setdelay <seconds>")
                print("  Example: /az explorer setdelay 30")
            end
        elseif subCommand == "forcereset" then
            if self.ExplorerMode then
                self.ExplorerMode:ForceResetDatabase()
                print("|cFF4488FF[AzeriteMOP]|r Database force reset complete")
            else
                print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
            end
        elseif subCommand == "on" then
            if self.ExplorerMode then
                self.ExplorerMode:ForceEnable()
                print("|cFF4488FF[AzeriteMOP]|r Explorer mode enabled")
            else
                print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
            end
        elseif subCommand == "off" then
            if self.ExplorerMode then
                self.ExplorerMode:ForceDisable()
                print("|cFF4488FF[AzeriteMOP]|r Explorer mode disabled")
            else
                print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
            end
        else
            print("|cFF4488FF[AzeriteMOP]|r Explorer mode commands:")
            print("  /az explorer debug - Show debug info")
            print("  /az explorer checkdelay - Check current delay value")
            print("  /az explorer resetdelay - Reset delay to 30 seconds")
            print("  /az explorer setdelay <seconds> - Set delay to specific seconds")
            print("  /az explorer forcereset - Force reset database to defaults")
            print("  /az explorer enable - Force enable explorer mode")
            print("  /az explorer disable - Force disable explorer mode")
            print("  /az explorer on - Enable explorer mode")
            print("  /az explorer off - Disable explorer mode")
        end
        -- print("|cFF4488FF[AzeriteMOP]|r playerFrame exists: " .. tostring(self.db.playerFrame ~= nil))
        -- print("|cFF4488FF[AzeriteMOP]|r targetFrame exists: " .. tostring(self.db.targetFrame ~= nil))
        -- print("|cFF4488FF[AzeriteMOP]|r explorerMode exists: " .. tostring(self.db.explorerMode ~= nil))
    elseif command == "ex" then
        local subCommand = string.lower(args[2] or "")
        if subCommand == "on" then
            if self.ExplorerMode then
                self.ExplorerMode:ForceEnable()
                print("|cFF4488FF[AzeriteMOP]|r Explorer mode enabled")
            else
                print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
            end
        elseif subCommand == "off" then
            if self.ExplorerMode then
                self.ExplorerMode:ForceDisable()
                print("|cFF4488FF[AzeriteMOP]|r Explorer mode disabled")
            else
                print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
            end
        else
            print("|cFF4488FF[AzeriteMOP]|r Explorer mode commands:")
            print("  /az ex on - Enable explorer mode")
            print("  /az ex off - Disable explorer mode")
        end
    elseif command == "checkdb" then
        -- Check the current state of saved variables
        -- print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPDB exists: " .. tostring(AzeriteMOPDB ~= nil))
        -- if AzeriteMOPDB then
        --     print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPDB.playerFrame exists: " .. tostring(AzeriteMOPDB.playerFrame ~= nil))
        --     print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPDB.targetFrame exists: " .. tostring(AzeriteMOPDB.targetFrame ~= nil))
        --     print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPDB.explorerMode exists: " .. tostring(AzeriteMOPDB.explorerMode ~= nil))
        -- end
        -- print("|cFF4488FF[AzeriteMOP]|r self.db exists: " .. tostring(self.db ~= nil))
        -- if self.db then
        --     print("|cFF4488FF[AzeriteMOP]|r self.db.playerFrame exists: " .. tostring(self.db.playerFrame ~= nil))
        --     print("|cFF4488FF[AzeriteMOP]|r self.db.targetFrame exists: " .. tostring(self.db.targetFrame ~= nil))
        --     print("|cFF4488FF[AzeriteMOP]|r self.db.explorerMode exists: " .. tostring(self.db.explorerMode ~= nil))
        -- end
    elseif command == "explorer" then
        self:HandleExplorerCommand(args)
    elseif command == "testexplorer" then
        if self.ExplorerMode then
            print("|cFF4488FF[AzeriteMOP]|r Testing Explorer Mode...")
            self.ExplorerMode:DebugInfo()
            -- Manually trigger explorer mode for testing
            if not self.ExplorerMode.isActive then
                self.ExplorerMode:EnableExplorerMode()
                print("|cFF4488FF[AzeriteMOP]|r Manually enabled explorer mode for testing")
            else
                self.ExplorerMode:DisableExplorerMode()
                print("|cFF4488FF[AzeriteMOP]|r Manually disabled explorer mode for testing")
            end
        else
            print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        end
    elseif command == "forceexplorer" then
        local subCommand = string.lower(args[2] or "")
        if self.ExplorerMode then
            if subCommand == "on" then
                self.ExplorerMode:ForceEnable()
                print("|cFF4488FF[AzeriteMOP]|r Force enabled explorer mode")
            elseif subCommand == "off" then
                self.ExplorerMode:ForceDisable()
                print("|cFF4488FF[AzeriteMOP]|r Force disabled explorer mode")
            else
                print("|cFF4488FF[AzeriteMOP]|r Usage: /az forceexplorer [on|off]")
            end
        else
            print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        end
    elseif command == "scanframes" then
        if self.ExplorerMode then
            print("|cFF4488FF[AzeriteMOP]|r Scanning for visible frames...")
            self.ExplorerMode:ScanVisibleFrames()
        else
            print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        end
    elseif command == "scanvisible" then
        if self.ExplorerMode then
            print("|cFF4488FF[AzeriteMOP]|r Scanning for visible UI frames...")
            self.ExplorerMode:ScanForVisibleFrames()
        else
            print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        end
    elseif command == "restore" then
        if self.ExplorerMode then
            print("|cFF4488FF[AzeriteMOP]|r Force restoring all UI elements...")
            self.ExplorerMode:ForceDisable()
            -- Force show all chat frames
            for i = 1, 10 do
                local chatFrame = _G["ChatFrame" .. i]
                if chatFrame then
                    chatFrame:Show()
                    chatFrame:SetAlpha(1)
                end
                local chatTab = _G["ChatFrame" .. i .. "Tab"]
                if chatTab then
                    chatTab:Show()
                    chatTab:SetAlpha(1)
                end
            end
            -- Force show quest frames
            local questFrames = {"QuestLogFrame", "ObjectiveTrackerFrame", "WatchFrame"}
            for _, frameName in ipairs(questFrames) do
                local frame = _G[frameName]
                if frame then
                    frame:Show()
                    frame:SetAlpha(1)
                end
            end
            print("|cFF4488FF[AzeriteMOP]|r All UI elements restored!")
        else
            print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        end
    elseif command == "showui" then
        if self.ExplorerMode then
            print("|cFF4488FF[AzeriteMOP]|r Force showing all UI elements...")
            self.ExplorerMode:ShowUI()
        else
            print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        end
    elseif command == "hideui" then
        if self.ExplorerMode then
            print("|cFF4488FF[AzeriteMOP]|r Force hiding all UI elements...")
            self.ExplorerMode:HideUI()
        else
            print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        end
    elseif command == "showframes" then
        print("|cFF4488FF[AzeriteMOP]|r Force showing PlayerFrame and TargetFrame...")
        -- Force show PlayerFrame
        if self.PlayerFrame and self.PlayerFrame.frame then
            self.PlayerFrame.frame:Show()
            print("|cFF4488FF[AzeriteMOP]|r PlayerFrame shown")
        else
            print("|cFF4488FF[AzeriteMOP]|r PlayerFrame not found")
        end
        -- Force show TargetFrame only if target exists
        if self.TargetFrame and self.TargetFrame.frame then
            if UnitExists("target") then
                self.TargetFrame.frame:Show()
                print("|cFF4488FF[AzeriteMOP]|r TargetFrame shown (target exists)")
            else
                self.TargetFrame.frame:Hide()
                print("|cFF4488FF[AzeriteMOP]|r TargetFrame hidden (no target selected)")
            end
        else
            print("|cFF4488FF[AzeriteMOP]|r TargetFrame not found")
        end
    elseif command == "checkframes" then
        print("|cFF4488FF[AzeriteMOP]|r Checking frame status...")
        -- Check PlayerFrame status
        if self.PlayerFrame and self.PlayerFrame.frame then
            local isShown = self.PlayerFrame.frame:IsShown()
            print("|cFF4488FF[AzeriteMOP]|r PlayerFrame exists and is shown: " .. tostring(isShown))
        else
            print("|cFF4488FF[AzeriteMOP]|r PlayerFrame not found")
        end
        -- Check TargetFrame status
        if self.TargetFrame and self.TargetFrame.frame then
            local isShown = self.TargetFrame.frame:IsShown()
            local hasTarget = UnitExists("target")
            print("|cFF4488FF[AzeriteMOP]|r TargetFrame exists and is shown: " .. tostring(isShown) .. " (has target: " .. tostring(hasTarget) .. ")")
        else
            print("|cFF4488FF[AzeriteMOP]|r TargetFrame not found")
        end
        -- Check by name
        local playerFrame = _G["AzeriteMOPPlayerFrame"]
        if playerFrame then
            print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPPlayerFrame exists and is shown: " .. tostring(playerFrame:IsShown()))
        else
            print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPPlayerFrame not found")
        end
        local targetFrame = _G["AzeriteMOPTargetFrame"]
        if targetFrame then
            print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPTargetFrame exists and is shown: " .. tostring(targetFrame:IsShown()))
        else
            print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPTargetFrame not found")
        end
    else
        self:ShowHelp()
    end
end

function AzeriteMOP:ToggleFrameLock()
    -- self:Debug("ToggleFrameLock called")
    
    -- Ensure database is properly initialized
    self:EnsureDatabase()
    
    -- self:Debug("Before toggle - playerFrame.locked: " .. tostring(self.db.playerFrame.locked))
    -- self:Debug("Before toggle - targetFrame.locked: " .. tostring(self.db.targetFrame.locked))
    
    local newLockState = not self.db.playerFrame.locked
    self.db.playerFrame.locked = newLockState
    self.db.targetFrame.locked = newLockState
    
    -- self:Debug("After toggle - newLockState: " .. tostring(newLockState))
    
    -- self:Debug("New lock state: " .. tostring(newLockState))
    
    -- Update frame movable states
    if self.PlayerFrame and self.PlayerFrame.frame then
        self.PlayerFrame.frame:SetMovable(not newLockState)
        self.PlayerFrame.frame:EnableMouse(not newLockState)
        -- self:Debug("Updated PlayerFrame movable state")
    else
        -- self:Debug("PlayerFrame not found")
    end
    
    if self.TargetFrame and self.TargetFrame.frame then
        self.TargetFrame.frame:SetMovable(not newLockState)
        self.TargetFrame.frame:EnableMouse(not newLockState)
        -- self:Debug("Updated TargetFrame movable state")
    else
        -- self:Debug("TargetFrame not found")
    end
    
    local status = newLockState and "locked" or "unlocked"
    -- self:Debug("Frames " .. status)
    -- print("|cFF4488FF[AzeriteMOP]|r Frames " .. status)
end

function AzeriteMOP:HandleScaleCommand(args)
    local frameType = string.lower(args[2] or "all")
    local scale = tonumber(args[3])
    
            if not scale or scale < 0.1 or scale > 3.0 then
            print("|cFF4488FF[AzeriteMOP]|r Usage: /az scale [player|target|all] [0.1-3.0]")
            print("|cFF4488FF[AzeriteMOP]|r Example: /az scale all 1.2")
            return
        end
    
    -- Ensure database is properly initialized
    self:EnsureDatabase()
    
    if frameType == "player" or frameType == "all" then
        self.db.playerFrame.scale = scale
        if self.PlayerFrame and self.PlayerFrame.frame then
            self.PlayerFrame.frame:SetScale(scale)
        end
        -- print("|cFF4488FF[AzeriteMOP]|r Player frame scaled to " .. scale)
    end
    
    if frameType == "target" or frameType == "all" then
        self.db.targetFrame.scale = scale
        if self.TargetFrame then
            self.TargetFrame:ApplyScaling(scale)
        end
        -- print("|cFF4488FF[AzeriteMOP]|r Target frame scaled to " .. scale)
    end
end

function AzeriteMOP:HandleFontScaleCommand(args)
    local frameType = string.lower(args[2] or "all")
    local scale = tonumber(args[3])
    
            if not scale or scale < 0.5 or scale > 3.0 then
            print("|cFF4488FF[AzeriteMOP]|r Usage: /az fontscale [player|target|all] [0.5-3.0]")
            print("|cFF4488FF[AzeriteMOP]|r Example: /az fontscale all 1.5")
            return
        end
    
    if frameType == "player" or frameType == "all" then
        if self.PlayerFrame then
            self.PlayerFrame:ScaleFonts(scale)
            -- print("|cFF4488FF[AzeriteMOP]|r Player frame fonts scaled to " .. scale)
        else
            -- print("|cFF4488FF[AzeriteMOP]|r PlayerFrame module not found!")
        end
    end
    
    if frameType == "target" or frameType == "all" then
        if self.TargetFrame then
            self.TargetFrame:ScaleFonts(scale)
            -- print("|cFF4488FF[AzeriteMOP]|r Target frame fonts scaled to " .. scale)
        else
            -- print("|cFF4488FF[AzeriteMOP]|r TargetFrame module not found!")
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
    
    -- print("|cFF4488FF[AzeriteMOP]|r Frame positions and scales reset to default")
end

function AzeriteMOP:HandleExplorerCommand(args)
    local subCommand = string.lower(args[2] or "")
    
    if subCommand == "on" then
        if self.ExplorerMode then
            self.ExplorerMode:SetEnabled(true)
            -- print("|cFF4488FF[AzeriteMOP]|r Explorer mode enabled!")
        else
            -- print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        end
    elseif subCommand == "off" then
        if self.ExplorerMode then
            self.ExplorerMode:SetEnabled(false)
            -- print("|cFF4488FF[AzeriteMOP]|r Explorer mode disabled!")
        else
            -- print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        end
    elseif subCommand == "status" then
        if self.ExplorerMode then
            local enabled = self.ExplorerMode:IsEnabled()
            local active = self.ExplorerMode:IsActive()
            -- print("|cFF4488FF[AzeriteMOP]|r Explorer mode enabled: " .. tostring(enabled))
            -- print("|cFF4488FF[AzeriteMOP]|r Explorer mode active: " .. tostring(active))
            -- if self.db.explorerMode then
            --     print("|cFF4488FF[AzeriteMOP]|r Stationary delay: " .. self.db.explorerMode.stationaryDelay .. " seconds")
            --     print("|cFF4488FF[AzeriteMOP]|r Movement threshold: " .. self.db.explorerMode.movementThreshold)
            -- end
        else
            -- print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        end
    elseif subCommand == "delay" then
        local delay = tonumber(args[3])
        if not delay or delay < 0.5 or delay > 10.0 then
            print("|cFF4488FF[AzeriteMOP]|r Usage: /az explorer delay [0.5-10.0]")
            print("|cFF4488FF[AzeriteMOP]|r Example: /az explorer delay 3.0")
            return
        end
        if self.ExplorerMode then
            self.ExplorerMode:SetStationaryDelay(delay)
            -- print("|cFF4488FF[AzeriteMOP]|r Stationary delay set to " .. delay .. " seconds")
        else
            -- print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        end
    elseif subCommand == "threshold" then
        local threshold = tonumber(args[3])
        if not threshold or threshold < 0.01 or threshold > 1.0 then
            print("|cFF4488FF[AzeriteMOP]|r Usage: /az explorer threshold [0.01-1.0]")
            print("|cFF4488FF[AzeriteMOP]|r Example: /az explorer threshold 0.05")
            return
        end
        if self.ExplorerMode then
            self.ExplorerMode:SetMovementThreshold(threshold)
            -- print("|cFF4488FF[AzeriteMOP]|r Movement threshold set to " .. threshold)
        else
            -- print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        end
    else
        -- print("|cFF4488FF[AzeriteMOP]|r Explorer mode commands:")
        -- print("  /azlock explorer on|off - Enable/disable explorer mode")
        -- print("  /azlock explorer status - Show explorer mode status")
        -- print("  /azlock explorer delay [seconds] - Set stationary delay")
        -- print("  /azlock explorer threshold [value] - Set movement threshold")
    end
end

function AzeriteMOP:ShowHelp()
    print("|cFF4488FF[AzeriteMOP]|r Commands:")
    print("  /az - Toggle frame lock (movable/immovable)")
    print("  /az scale [player|target|all] [0.1-3.0] - Scale frames")
    print("  /az fontscale [player|target|all] [0.5-3.0] - Scale fonts")
    print("  /az resetfonts [player|target|all] - Reset fonts to default size")
    print("  /az reset - Reset frame positions and scales")
    print("  /az testscale - Test target frame scaling")
    print("  /az testfontscale - Test font scaling on both frames")
    print("  /az testdb - Test database initialization")
    print("  /az resetdb - Reset database completely")
    print("  /az checkdb - Check database state")
    print("  /az testexplorer - Test explorer mode manually")
    print("  /az forceexplorer [on|off] - Force enable/disable explorer mode")
    print("  /az scanframes - Scan for visible frames (debugging)")
    print("  /az restore - Force restore all UI elements")
    print("  /az showui - Force show all UI elements")
    print("  /az hideui - Force hide all UI elements")
    print("  /az showframes - Force show PlayerFrame and TargetFrame")
    print("  /az checkframes - Check frame status")
    print("  /az ex on - Enable explorer mode (manual control)")
    print("  /az ex off - Disable explorer mode (manual control)")
    print("  /az help - Show this help")
    print("")
    print("Examples:")
    print("  /az scale all 1.2 - Scale all frames to 120%")
    print("  /az scale player 0.8 - Scale player frame to 80%")
    print("  /az scale target 1.5 - Scale target frame to 150%")
    print("  /az fontscale all 1.3 - Scale all fonts to 130%")
    print("  /az fontscale player 1.2 - Scale player fonts to 120%")
    print("  /az fontscale target 1.4 - Scale target fonts to 140%")
    print("  /az resetfonts all - Reset all fonts to default")
    print("  /az resetfonts player - Reset player fonts to default")
    print("  /az resetfonts target - Reset target fonts to default")
    print("")
    print("Explorer Mode Commands:")
    print("  /az ex on - Enable explorer mode (manual control)")
    print("  /az ex off - Disable explorer mode (manual control)")
    print("  /az explorer on|off - Enable/disable explorer mode")
    print("  /az explorer status - Show explorer mode status")
    print("  /az explorer delay [seconds] - Set stationary delay")
    print("  /az explorer threshold [value] - Set movement threshold")
    print("  /az testexplorer - Test explorer mode manually")
    print("  /az forceexplorer on|off - Force enable/disable explorer mode")
    print("  /az scanframes - Scan for visible frames (debugging)")
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

-- Explorer Mode State Management
function AzeriteMOP:SetExplorerModeActive(active)
    self:EnsureDatabase()
    self.db.explorerMode.isActive = active
    AzeriteMOP:Debug("Explorer mode active state set to: " .. tostring(active))
end

function AzeriteMOP:GetExplorerModeActive()
    self:EnsureDatabase()
    return self.db.explorerMode.isActive or false
end

function AzeriteMOP:SetExplorerModeEnabled(enabled)
    self:EnsureDatabase()
    self.db.explorerMode.enabled = enabled
    AzeriteMOP:Debug("Explorer mode enabled state set to: " .. tostring(enabled))
end

function AzeriteMOP:GetExplorerModeEnabled()
    self:EnsureDatabase()
    return self.db.explorerMode.enabled or false
end

-- Safety check
if not AzeriteMOP:IsMoPClassic() then
    error("AzeriteMOP: This addon is designed for MoP Classic (5.4.x) only!")
end