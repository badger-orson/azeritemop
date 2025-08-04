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
    if not self.db.playerFrame.fontScale then
        self.db.playerFrame.fontScale = 1.0
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
    if not self.db.targetFrame.fontScale then
        self.db.targetFrame.fontScale = 1.0
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
    
    if not self.db.chatFrame then
        -- self:Debug("Creating chatFrame in database")
        self.db.chatFrame = {
            enabled = true,
            fadeChat = true,  -- Enable chat fade effect
            hideEditBox = true,  -- Hide edit box when not typing
            showTimestamps = false,  -- Add timestamps to messages
            numScrollMessages = 3,
            scrollDownInterval = 0,
            maxCopyLines = 100,
            showEmojis = false,
            showURLs = true,
            showChatBubbles = true
        }
    end
    
    if not self.db.nameplate then
        -- self:Debug("Creating nameplate in database")
        self.db.nameplate = {
            enabled = true,
            scale = 1.0,
            width = 120,
            height = 12,
            showCastbar = true,
            showLevel = true,
            showName = true,
            classColors = true,
            threatColors = true,
            hideBlizzard = true,
            fontSize = 10,
            healthTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            castTexture = "Interface\\TargetingFrame\\UI-StatusBar"
        }
    end
    
    -- Global UI settings
    if not self.db.global then
        self.db.global = {
            uiScale = 1.0,  -- Global UI scale multiplier
            useGlobalScale = false  -- Whether to use global scale
        }
    end
    
    -- Texture settings
    if not self.db.textures then
        self.db.textures = {
            -- Bar textures
            healthBar = "Interface\\TargetingFrame\\UI-StatusBar",
            powerBar = "Interface\\TargetingFrame\\UI-StatusBar",
            castBar = "Interface\\TargetingFrame\\UI-StatusBar",
            
            -- Background textures
            barBackground = "Interface\\DialogFrame\\UI-DialogBox-Background",
            frameBackground = "Interface\\DialogFrame\\UI-DialogBox-Background",
            
            -- Border textures
            frameBorder = "Interface\\Tooltips\\UI-Tooltip-Border",
            
            -- Custom texture paths (user can add their own)
            custom = {}
        }
    end
    
    -- Color customization settings
    if not self.db.colors then
        self.db.colors = {
            -- Player Frame colors
            playerHealth = { r = 0.0, g = 0.8, b = 0.0 },  -- Green
            playerHealthBg = { r = 0.1, g = 0.1, b = 0.1 },
            playerPower = { r = 0.0, g = 0.5, b = 1.0 },  -- Blue (mana)
            playerPowerBg = { r = 0.1, g = 0.1, b = 0.2 },
            playerText = { r = 1.0, g = 1.0, b = 1.0 },
            playerLevelText = { r = 1.0, g = 0.82, b = 0.0 },
            
            -- Target Frame colors
            targetHealthFriendly = { r = 0.0, g = 1.0, b = 0.0 },
            targetHealthNeutral = { r = 1.0, g = 1.0, b = 0.0 },
            targetHealthHostile = { r = 1.0, g = 0.0, b = 0.0 },
            targetHealthBg = { r = 0.1, g = 0.1, b = 0.1 },
            targetPower = { r = 0.0, g = 0.5, b = 1.0 },
            targetPowerBg = { r = 0.1, g = 0.1, b = 0.2 },
            targetText = { r = 1.0, g = 1.0, b = 1.0 },
            targetLevelText = { r = 1.0, g = 0.82, b = 0.0 },
            
            -- Cast bar colors
            castBarNormal = { r = 1.0, g = 0.7, b = 0.0 },  -- Orange
            castBarChannel = { r = 0.0, g = 1.0, b = 0.0 },  -- Green
            castBarInterruptible = { r = 1.0, g = 0.7, b = 0.0 },
            castBarNotInterruptible = { r = 0.7, g = 0.7, b = 0.7 },  -- Gray
            castBarBg = { r = 0.1, g = 0.1, b = 0.1 },
            castBarText = { r = 1.0, g = 1.0, b = 1.0 },
            castBarTimeText = { r = 1.0, g = 1.0, b = 0.0 },
            
            -- Nameplate colors
            nameplateHealthFriendly = { r = 0.0, g = 1.0, b = 0.0 },
            nameplateHealthNeutral = { r = 1.0, g = 1.0, b = 0.0 },
            nameplateHealthHostile = { r = 1.0, g = 0.0, b = 0.0 },
            nameplateHealthBg = { r = 0.1, g = 0.1, b = 0.1 },
            nameplateCastBar = { r = 1.0, g = 0.7, b = 0.0 },
            nameplateCastBarBg = { r = 0.1, g = 0.1, b = 0.1 },
            nameplateNameText = { r = 1.0, g = 1.0, b = 1.0 },
            nameplateLevelText = { r = 1.0, g = 0.82, b = 0.0 },
            
            -- Power colors by type
            powerColors = {
                MANA = { r = 0.0, g = 0.5, b = 1.0 },
                RAGE = { r = 1.0, g = 0.0, b = 0.0 },
                FOCUS = { r = 1.0, g = 0.5, b = 0.25 },
                ENERGY = { r = 1.0, g = 1.0, b = 0.0 },
                RUNIC_POWER = { r = 0.0, g = 0.82, b = 1.0 },
                CHI = { r = 0.71, g = 1.0, b = 0.92 }
            },
            
            -- Class colors override (optional)
            useClassColors = true,
            overrideClassColors = false,
            classColorOverrides = {}  -- Will be populated if needed
        }
    end
    
    -- Profile system (initialize after all other settings)
    if not self.db.profiles then
        self.db.profiles = {
            current = "Default",
            list = {}
        }
        -- Save current settings as Default profile
        self.db.profiles.list["Default"] = {
            playerFrame = self:CopyTable(self.db.playerFrame),
            targetFrame = self:CopyTable(self.db.targetFrame),
            explorerMode = self:CopyTable(self.db.explorerMode),
            chatFrame = self:CopyTable(self.db.chatFrame),
            nameplate = self:CopyTable(self.db.nameplate),
            global = self:CopyTable(self.db.global)
        }
    end
    

    
    -- self:Debug("EnsureDatabase complete - playerFrame: " .. tostring(self.db.playerFrame ~= nil) .. ", targetFrame: " .. tostring(self.db.targetFrame ~= nil) .. ", explorerMode: " .. tostring(self.db.explorerMode ~= nil))
end

-- Event frame for handling addon events
AzeriteMOP.eventFrame = CreateFrame("Frame")

-- Initialize function
function AzeriteMOP:Initialize()
    -- self:Debug("Initializing AzeriteMOP...")
    
    -- CRITICAL: Check for addon conflicts that cause stack overflow
    if IsAddOnLoaded("Bartender4") and IsAddOnLoaded("DragonflightUI") then
        print("|cFFFF0000[AzeriteMOP]|r CRITICAL: Detected conflicting addons!")
        print("|cFFFF0000[AzeriteMOP]|r Bartender4 and DragonflightUI are causing stack overflow")
        print("|cFFFF0000[AzeriteMOP]|r Please disable one of these addons to prevent crashes")
        print("|cFFFF0000[AzeriteMOP]|r AzeriteMOP will not load to prevent further issues")
        return -- Don't initialize anything
    end
    
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
    
    if not AzeriteMOPDB.nameplate then
        AzeriteMOPDB.nameplate = {
            enabled = true,
            scale = 1.0,
            width = 120,
            height = 12,
            showCastbar = true,
            showLevel = true,
            showName = true,
            classColors = true,
            threatColors = true,
            hideBlizzard = true,
            fontSize = 10,
            healthTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            castTexture = "Interface\\TargetingFrame\\UI-StatusBar"
        }
    end
    
    -- Global UI settings
    if not AzeriteMOPDB.global then
        AzeriteMOPDB.global = {
            uiScale = 1.0,  -- Global UI scale multiplier
            useGlobalScale = false  -- Whether to use global scale
        }
    end
    
    -- Profile system (initialize after all other settings)
    if not AzeriteMOPDB.profiles then
        AzeriteMOPDB.profiles = {
            current = "Default",
            list = {}
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
    
    if self.ChatFrame then
        self.ChatFrame:Initialize()
    else
        -- self:Debug("ChatFrame module not found!")
    end
    
    if self.ExplorerMode then
        self.ExplorerMode:Initialize()
    else
        -- self:Debug("ExplorerMode module not found!")
    end
    
    if self.Nameplate then
        self.Nameplate:Initialize()
    else
        -- self:Debug("Nameplate module not found!")
    end
    
    -- Initialize Settings Menu
    if self.SettingsMenu then
        self.SettingsMenu:Initialize()
    else
        -- self:Debug("SettingsMenu module not found!")
    end
    
    -- Set up slash commands
    self:SetupSlashCommands()
    
    -- Create preset profiles if they don't exist
    self:CreatePresetProfiles()
    
    -- Apply global scale if enabled
    if self.db.global and self.db.global.useGlobalScale then
        -- Delay to ensure frames are created
        self:ScheduleTimer(function()
            self:ApplyGlobalScale()
        end, 0.5)
    end
    
    -- self:Debug("AzeriteMOP initialized successfully!")
end

-- Helper functions for ChatFrame module
function AzeriteMOP:RGBToHex(r, g, b)
    return format("|cff%02x%02x%02x", r*255, g*255, b*255)
end

function AzeriteMOP:StripString(str)
    if not str then return "" end
    str = gsub(str, "|c%x%x%x%x%x%x%x%x", "") -- Remove color codes
    str = gsub(str, "|r", "") -- Remove reset codes
    str = gsub(str, "|H.-|h", "") -- Remove hyperlink codes
    str = gsub(str, "|h", "") -- Remove hyperlink end codes
    str = gsub(str, "|T.-|t", "") -- Remove texture codes
    str = gsub(str, "|A.-|a", "") -- Remove atlas codes
    return str
end

function AzeriteMOP:EscapeString(str)
    if not str then return "" end
    str = gsub(str, "%%", "%%%%")
    str = gsub(str, "%(", "%%(")
    str = gsub(str, "%)", "%%)")
    str = gsub(str, "%.", "%%.")
    str = gsub(str, "%+", "%%+")
    str = gsub(str, "%-", "%%-")
    str = gsub(str, "%*", "%%*")
    str = gsub(str, "%?", "%%?")
    str = gsub(str, "%[", "%%[")
    str = gsub(str, "%]", "%%]")
    str = gsub(str, "%^", "%%^")
    str = gsub(str, "%$", "%%$")
    return str
end

-- Timer function for Classic compatibility
function AzeriteMOP:ScheduleTimer(func, delay)
    if C_Timer and C_Timer.NewTimer then
        return C_Timer.NewTimer(delay, func)
    else
        -- Fallback for Classic using older API
        local timer = {}
        timer.func = func
        timer.delay = delay
        timer.startTime = GetTime()
        
        timer.Cancel = function(self)
            self.cancelled = true
        end
        
        -- Create a frame to handle the timer
        local frame = CreateFrame("Frame")
        frame:SetScript("OnUpdate", function(self, elapsed)
            if timer.cancelled then
                self:SetScript("OnUpdate", nil)
                return
            end
            
            if GetTime() - timer.startTime >= timer.delay then
                timer.func()
                self:SetScript("OnUpdate", nil)
            end
        end)
        
        return timer
    end
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
    elseif command == "globalscale" then
        self:HandleGlobalScaleCommand(args)
    elseif command == "profile" then
        self:HandleProfileCommand(args)
    elseif command == "color" then
        self:HandleColorCommand(args)
    elseif command == "texture" then
        self:HandleTextureCommand(args)
    elseif command == "reset" then
        self:ResetFramePositions()
    elseif command == "settings" or command == "config" or command == "menu" then
        if self.SettingsMenu then
            self.SettingsMenu:Toggle()
        else
            print("|cFF4488FF[AzeriteMOP]|r Settings menu not available")
        end
    elseif command == "help" then
        self:ShowHelp()
    -- DEBUG COMMANDS (commented out for production)
    -- elseif command == "test" then
    --     -- print("|cFF4488FF[AzeriteMOP]|r Test command works!")
    --     -- self:Debug("Test command executed successfully")
    -- elseif command == "testscale" then
    --     if self.TargetFrame then
    --         self.TargetFrame:TestScaling()
    --         -- print("|cFF4488FF[AzeriteMOP]|r Target frame scaling test applied!")
    --     else
    --         -- print("|cFF4488FF[AzeriteMOP]|r TargetFrame module not found!")
    --     end
    -- elseif command == "testfontscale" then
    --     if self.PlayerFrame then
    --         self.PlayerFrame:ScaleFonts(1.5)
    --         -- print("|cFF4488FF[AzeriteMOP]|r Player frame font scaling test applied!")
    --     else
    --         -- print("|cFF4488FF[AzeriteMOP]|r PlayerFrame module not found!")
    --     end
    --     if self.TargetFrame then
    --         self.TargetFrame:ScaleFonts(1.5)
    --         -- print("|cFF4488FF[AzeriteMOP]|r Target frame font scaling test applied!")
    --     else
    --         -- print("|cFF4488FF[AzeriteMOP]|r TargetFrame module not found!")
    --     end
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
    -- elseif command == "testdb" then
    --     self:EnsureDatabase()
    --     -- print("|cFF4488FF[AzeriteMOP]|r Database test - playerFrame exists: " .. tostring(self.db.playerFrame ~= nil))
    --     -- print("|cFF4488FF[AzeriteMOP]|r Database test - targetFrame exists: " .. tostring(self.db.targetFrame ~= nil))
    --     -- print("|cFF4488FF[AzeriteMOP]|r Database test - explorerMode exists: " .. tostring(self.db.explorerMode ~= nil))
    --     -- if self.db.playerFrame then
    --     --     print("|cFF4488FF[AzeriteMOP]|r Player frame locked: " .. tostring(self.db.playerFrame.locked))
    --     -- end
    --     -- if self.db.targetFrame then
    --     --     print("|cFF4488FF[AzeriteMOP]|r Target frame locked: " .. tostring(self.db.targetFrame.locked))
    --     -- end
    --     -- if self.db.explorerMode then
    --     --     print("|cFF4488FF[AzeriteMOP]|r Explorer mode enabled: " .. tostring(self.db.explorerMode.enabled))
    --     -- end
    elseif command == "resetdb" then
        -- Completely reset the saved variables
        AzeriteMOPDB = nil
        self.db = nil
        self:EnsureDatabase()
        -- print("|cFF4488FF[AzeriteMOP]|r Database completely reset and reinitialized")
    elseif command == "explorer" then
        local subCommand = string.lower(args[2] or "")
        -- Keep only "on" and "off" for enabling/disabling
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
        -- Debug commands (commented out)
        -- elseif subCommand == "debug" then
        --     if self.ExplorerMode then
        --         self.ExplorerMode:DebugInfo()
        --     else
        --         print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        --     end
        -- elseif subCommand == "checkdelay" then
        --     if self.ExplorerMode then
        --         self.ExplorerMode:CheckDelayValue()
        --     else
        --         print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        --     end
        -- elseif subCommand == "resetdelay" then
        --     if self.ExplorerMode then
        --         self.ExplorerMode:ResetStationaryDelay()
        --     else
        --         print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        --     end
        -- elseif subCommand == "forcereset" then
        --     if self.ExplorerMode then
        --         self.ExplorerMode:ForceResetDatabase()
        --         print("|cFF4488FF[AzeriteMOP]|r Database force reset complete")
        --     else
        --         print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
        --     end
        else
            print("|cFF4488FF[AzeriteMOP]|r Explorer mode commands:")
            print("  /az explorer on - Enable explorer mode")
            print("  /az explorer off - Disable explorer mode")
            print("  /az explorer setdelay <seconds> - Set UI hide delay (default: 30)")
        end
        -- print("|cFF4488FF[AzeriteMOP]|r playerFrame exists: " .. tostring(self.db.playerFrame ~= nil))
        -- print("|cFF4488FF[AzeriteMOP]|r targetFrame exists: " .. tostring(self.db.targetFrame ~= nil))
        -- print("|cFF4488FF[AzeriteMOP]|r explorerMode exists: " .. tostring(self.db.explorerMode ~= nil))
    -- Removed duplicate "ex" command - use "explorer" instead
    -- elseif command == "checkdb" then
    --     -- Check the current state of saved variables
    --     -- print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPDB exists: " .. tostring(AzeriteMOPDB ~= nil))
    --     -- if AzeriteMOPDB then
    --     --     print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPDB.playerFrame exists: " .. tostring(AzeriteMOPDB.playerFrame ~= nil))
    --     --     print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPDB.targetFrame exists: " .. tostring(AzeriteMOPDB.targetFrame ~= nil))
    --     --     print("|cFF4488FF[AzeriteMOP]|r AzeriteMOPDB.explorerMode exists: " .. tostring(AzeriteMOPDB.explorerMode ~= nil))
    --     -- end
    --     -- print("|cFF4488FF[AzeriteMOP]|r self.db exists: " .. tostring(self.db ~= nil))
    --     -- if self.db then
    --     --     print("|cFF4488FF[AzeriteMOP]|r self.db.playerFrame exists: " .. tostring(self.db.playerFrame ~= nil))
    --     --     print("|cFF4488FF[AzeriteMOP]|r self.db.targetFrame exists: " .. tostring(self.db.targetFrame ~= nil))
    --     --     print("|cFF4488FF[AzeriteMOP]|r self.db.explorerMode exists: " .. tostring(self.db.explorerMode ~= nil))
    --     -- end
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
    -- elseif command == "forceexplorer" then
    --     local subCommand = string.lower(args[2] or "")
    --     if self.ExplorerMode then
    --         if subCommand == "on" then
    --             self.ExplorerMode:ForceEnable()
    --             print("|cFF4488FF[AzeriteMOP]|r Force enabled explorer mode")
    --         elseif subCommand == "off" then
    --             self.ExplorerMode:ForceDisable()
    --             print("|cFF4488FF[AzeriteMOP]|r Force disabled explorer mode")
    --         else
    --             print("|cFF4488FF[AzeriteMOP]|r Usage: /az forceexplorer [on|off]")
    --         end
    --     else
    --         print("|cFF4488FF[AzeriteMOP]|r ExplorerMode module not found!")
    --     end
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
    elseif command == "chat" then
        local subCommand = string.lower(args[2] or "")
        if subCommand == "toggle" then
            if self.ChatFrame then
                self.ChatFrame:Toggle()
                print("|cFF4488FF[AzeriteMOP]|r Chat frame toggled")
            else
                print("|cFF4488FF[AzeriteMOP]|r ChatFrame module not found!")
            end
        elseif subCommand == "copy" then
            if self.ChatFrame then
                ShowCopyChatFrame(ChatFrame1)
                print("|cFF4488FF[AzeriteMOP]|r Copy chat frame opened")
            else
                print("|cFF4488FF[AzeriteMOP]|r ChatFrame module not found!")
            end
        elseif subCommand == "settings" then
            if self.db and self.db.chatFrame then
                print("|cFF4488FF[AzeriteMOP]|r Chat Frame Settings:")
                print("  Show Timestamps: " .. tostring(self.db.chatFrame.showTimestamps))
                print("  Hide Edit Box: " .. tostring(self.db.chatFrame.hideEditBox))
                print("  Fade Chat: " .. tostring(self.db.chatFrame.fadeChat))
                print("  Show Emojis: " .. tostring(self.db.chatFrame.showEmojis))
                print("  Show URLs: " .. tostring(self.db.chatFrame.showURLs))
                print("  Show Chat Bubbles: " .. tostring(self.db.chatFrame.showChatBubbles))
                print("  Max Copy Lines: " .. tostring(self.db.chatFrame.maxCopyLines))
            else
                print("|cFF4488FF[AzeriteMOP]|r Chat frame settings not found")
            end
        elseif subCommand == "show" then
            -- Force show all chat frames
            for i = 1, 10 do
                local frame = _G["ChatFrame" .. i]
                if frame then
                    frame:Show()
                    frame:SetAlpha(1.0)
                    print("|cFF4488FF[AzeriteMOP]|r Showing ChatFrame" .. i)
                end
            end
            print("|cFF4488FF[AzeriteMOP]|r All chat frames should now be visible")
        elseif subCommand == "test" then
            -- Send a test message
            if ChatFrame1 then
                ChatFrame1:AddMessage("|cFF4488FF[AzeriteMOP]|r This is a test message from AzeriteMOP!")
                print("|cFF4488FF[AzeriteMOP]|r Test message sent to chat")
            else
                print("|cFF4488FF[AzeriteMOP]|r ChatFrame1 not found")
            end
        elseif subCommand == "check" then
            -- Check chat frame status
            print("|cFF4488FF[AzeriteMOP]|r Chat Frame Status:")
            for i = 1, 5 do
                local frame = _G["ChatFrame" .. i]
                if frame then
                    local isShown = frame:IsShown()
                    local alpha = frame:GetAlpha()
                    local background = _G["ChatFrame" .. i .. "Background"]
                    local hasBackground = background and background:GetTexture()
                    print("  ChatFrame" .. i .. ": Shown=" .. tostring(isShown) .. ", Alpha=" .. tostring(alpha) .. ", Background=" .. tostring(hasBackground))
                else
                    print("  ChatFrame" .. i .. ": Not found")
                end
            end
            
            -- Check ExplorerMode status
            if self.ExplorerMode then
                local isActive = self.ExplorerMode:GetIsActive()
                print("  ExplorerMode Active: " .. tostring(isActive))
            else
                print("  ExplorerMode: Not found")
            end
        elseif subCommand == "refresh" then
            -- Force refresh chat backgrounds
            if self.ChatFrame then
                for i = 1, 10 do
                    local frame = _G["ChatFrame" .. i]
                    if frame then
                        local background = _G["ChatFrame" .. i .. "Background"]
                        if background then
                            local texturePath = "Interface/AddOns/AzeriteMOP/Textures/chat/chatframebackground.tga"
                            background:SetTexture(texturePath)
                            background:SetVertexColor(1, 1, 1, 1)
                            background:Show()
                            
                            local loadedTexture = background:GetTexture()
                            print("|cFF4488FF[AzeriteMOP]|r Refreshed background for ChatFrame" .. i .. " - Loaded: " .. tostring(loadedTexture))
                        else
                            print("|cFF4488FF[AzeriteMOP]|r No background found for ChatFrame" .. i)
                        end
                    end
                end
                print("|cFF4488FF[AzeriteMOP]|r Chat backgrounds refreshed")
            else
                print("|cFF4488FF[AzeriteMOP]|r ChatFrame module not found")
            end
        elseif subCommand == "testtexture" then
            -- Test texture loading directly
            local testFrame = CreateFrame("Frame", "AzeriteMOPTestTexture", UIParent)
            testFrame:SetSize(100, 100)
            testFrame:SetPoint("CENTER")
            
            local testTexture = testFrame:CreateTexture(nil, "ARTWORK")
            testTexture:SetAllPoints()
            testTexture:SetTexture("Interface/AddOns/AzeriteMOP/Textures/chat/chatframebackground.tga")
            
            local loadedTexture = testTexture:GetTexture()
            print("|cFF4488FF[AzeriteMOP]|r Test texture loaded: " .. tostring(loadedTexture))
            
            if loadedTexture and loadedTexture ~= "" then
                print("|cFF4488FF[AzeriteMOP]|r Texture loading successful!")
                testFrame:Show()
            else
                print("|cFF4488FF[AzeriteMOP]|r Texture loading failed!")
                testFrame:Hide()
            end
        elseif subCommand == "applychat" then
            -- Directly apply texture to ChatFrame1
            if ChatFrame1 then
                print("|cFF4488FF[AzeriteMOP]|r Applying texture directly to ChatFrame1")
                
                -- Check if background already exists
                local background = _G["ChatFrame1Background"]
                if not background then
                    print("|cFF4488FF[AzeriteMOP]|r Creating new background for ChatFrame1")
                    background = ChatFrame1:CreateTexture("ChatFrame1Background", "BACKGROUND", nil, -1)
                    background:SetAllPoints()
                else
                    print("|cFF4488FF[AzeriteMOP]|r Found existing background for ChatFrame1")
                end
                
                -- Apply texture
                background:SetTexture("Interface/AddOns/AzeriteMOP/Textures/chat/chatframebackground.tga")
                background:SetVertexColor(1, 1, 1, 1)
                background:SetDrawLayer("BACKGROUND", -1)
                background:Show()
                
                -- Verify texture was applied
                local loadedTexture = background:GetTexture()
                print("|cFF4488FF[AzeriteMOP]|r Background texture loaded: " .. tostring(loadedTexture))
                
                if loadedTexture and loadedTexture ~= "" then
                    print("|cFF4488FF[AzeriteMOP]|r Successfully applied background to ChatFrame1")
                else
                                    print("|cFF4488FF[AzeriteMOP]|r WARNING: Background texture failed to load")
            end
        else
            print("|cFF4488FF[AzeriteMOP]|r ChatFrame1 not found")
        end
            elseif subCommand == "debugchat" then
            -- Debug ChatFrame1 structure
            if ChatFrame1 then
                print("|cFF4488FF[AzeriteMOP]|r ChatFrame1 Debug Info:")
                print("  Name: " .. ChatFrame1:GetName())
                print("  Shown: " .. tostring(ChatFrame1:IsShown()))
                print("  Alpha: " .. tostring(ChatFrame1:IsShown()))
                print("  Frame Level: " .. tostring(ChatFrame1:GetFrameLevel()))
                
                -- Check for background elements
                local regions = {ChatFrame1:GetRegions()}
                print("  Regions found: " .. #regions)
                for i, region in ipairs(regions) do
                    if region:IsObjectType("Texture") then
                        print("    Region " .. i .. ": Texture - " .. tostring(region:GetTexture()))
                    else
                        print("    Region " .. i .. ": " .. region:GetObjectType())
                    end
                end
                
                -- Check specific background names
                local backgroundNames = {"Background", "BackgroundTexture", "BackgroundFrame", "Backdrop"}
                for _, name in ipairs(backgroundNames) do
                    local element = _G["ChatFrame1" .. name]
                    if element then
                        print("  Found " .. name .. ": " .. tostring(element:GetTexture()))
                    else
                        print("  " .. name .. ": Not found")
                    end
                end
            else
                print("|cFF4488FF[AzeriteMOP]|r ChatFrame1 not found")
            end

        else
            print("|cFF4488FF[AzeriteMOP]|r Chat commands:")
            print("  /az chat toggle - Toggle custom chat frame")
            print("  /az chat copy - Open copy chat window")
            print("  /az chat settings - Show chat frame settings")
            print("  /az chat show - Force show all chat frames")
            print("  /az chat test - Send test message to chat")
            print("  /az chat check - Check chat frame status")
            print("  /az chat refresh - Force refresh chat backgrounds")
            print("  /az chat testtexture - Test texture loading")
            print("  /az chat applychat - Apply texture directly to ChatFrame1")
            print("  /az chat debugchat - Debug ChatFrame1 structure")
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

function AzeriteMOP:UpdateFrameLocks()
    -- Update frame lock states without toggling
    -- This is called from the settings menu
    
    -- Ensure database is properly initialized
    self:EnsureDatabase()
    
    local lockState = self.db.playerFrame.locked
    
    -- Update player frame
    if self.PlayerFrame and self.PlayerFrame.frame then
        self.PlayerFrame.frame:SetMovable(not lockState)
        self.PlayerFrame.frame:EnableMouse(not lockState)
    end
    
    -- Update target frame  
    if self.TargetFrame and self.TargetFrame.frame then
        self.TargetFrame.frame:SetMovable(not lockState)
        self.TargetFrame.frame:EnableMouse(not lockState)
    end
    
    local status = lockState and "locked" or "unlocked"
    print("|cFF4488FF[AzeriteMOP]|r Frames " .. status)
end

function AzeriteMOP:HandleTextureCommand(args)
    local subCommand = string.lower(args[2] or "")
    
    if subCommand == "set" then
        local textureKey = args[3]
        local textureName = args[4]
        
        if not textureKey or not textureName then
            print("|cFF4488FF[AzeriteMOP]|r Usage: /az texture set <key> <name>")
            print("  Keys: healthBar, powerBar, castBar, barBackground, frameBackground")
            print("  Example: /az texture set healthBar Smooth")
            return
        end
        
        -- Find texture by name
        local texturePath = nil
        local textureList = self:GetTextureList()
        
        for _, texture in ipairs(textureList) do
            if string.lower(texture.name) == string.lower(textureName) then
                texturePath = texture.path
                break
            end
        end
        
        -- Check custom textures
        if not texturePath and self.db.textures.custom then
            texturePath = self.db.textures.custom[textureName]
        end
        
        if not texturePath then
            print("|cFF4488FF[AzeriteMOP]|r Texture '" .. textureName .. "' not found")
            print("Use /az texture list to see available textures")
            return
        end
        
        self:SetTexture(textureKey, texturePath)
        
    elseif subCommand == "list" then
        local page = tonumber(args[3]) or 1
        local itemsPerPage = 15
        local textureList = self:GetTextureList()
        local totalPages = math.ceil(#textureList / itemsPerPage)
        
        page = math.max(1, math.min(page, totalPages))
        
        print("|cFF4488FF[AzeriteMOP]|r Available textures (Page " .. page .. "/" .. totalPages .. "):")
        
        local startIdx = (page - 1) * itemsPerPage + 1
        local endIdx = math.min(startIdx + itemsPerPage - 1, #textureList)
        
        for i = startIdx, endIdx do
            local texture = textureList[i]
            print("  " .. texture.name)
        end
        
        if self.db.textures.custom and next(self.db.textures.custom) then
            print("|cFFFFFF00Custom textures:|r")
            for name, _ in pairs(self.db.textures.custom) do
                print("  " .. name)
            end
        end
        
        if totalPages > 1 then
            print("Use /az texture list " .. (page + 1) .. " for next page")
        end
        
    elseif subCommand == "current" then
        print("|cFF4488FF[AzeriteMOP]|r Current texture settings:")
        print("  healthBar: " .. (self.db.textures.healthBar or "Default"))
        print("  powerBar: " .. (self.db.textures.powerBar or "Default"))
        print("  castBar: " .. (self.db.textures.castBar or "Default"))
        print("  barBackground: " .. (self.db.textures.barBackground or "Default"))
        print("  frameBackground: " .. (self.db.textures.frameBackground or "Default"))
        
    elseif subCommand == "reset" then
        self:ResetTextures()
        
    elseif subCommand == "custom" then
        local name = args[3]
        local path = args[4]
        
        if not name or not path then
            print("|cFF4488FF[AzeriteMOP]|r Usage: /az texture custom <name> <path>")
            print("  Example: /az texture custom MyTexture Interface\\AddOns\\MyAddon\\MyTexture")
            return
        end
        
        self:AddCustomTexture(name, path)
        
    elseif subCommand == "apply" then
        self:ApplyAllTextures()
        print("|cFF4488FF[AzeriteMOP]|r All textures reapplied")
        
    else
        print("|cFF4488FF[AzeriteMOP]|r Texture commands:")
        print("  /az texture set <key> <name> - Set a texture")
        print("  /az texture list [page] - List available textures")
        print("  /az texture current - Show current texture settings")
        print("  /az texture reset - Reset all textures to defaults")
        print("  /az texture custom <name> <path> - Add custom texture")
        print("  /az texture apply - Reapply all textures")
        print("")
        print("Texture keys:")
        print("  healthBar - Health bar texture")
        print("  powerBar - Power/mana bar texture")
        print("  castBar - Cast bar texture")
        print("  barBackground - Bar background texture")
        print("  frameBackground - Frame background texture")
    end
end

function AzeriteMOP:HandleColorCommand(args)
    local subCommand = string.lower(args[2] or "")
    
    if subCommand == "set" then
        local colorKey = args[3]
        local r = tonumber(args[4])
        local g = tonumber(args[5])
        local b = tonumber(args[6])
        
        if not colorKey or not r or not g or not b then
            print("|cFF4488FF[AzeriteMOP]|r Usage: /az color set <colorKey> <r> <g> <b>")
            print("  RGB values should be 0-255 or 0.0-1.0")
            print("  Example: /az color set playerHealth 0 255 0")
            return
        end
        
        -- Convert 0-255 to 0-1 if needed
        if r > 1 then r = r / 255 end
        if g > 1 then g = g / 255 end
        if b > 1 then b = b / 255 end
        
        if self:SetColor(colorKey, r, g, b) then
            local colorStr = string.format("|cFF%02X%02X%02X", r*255, g*255, b*255)
            print(string.format("|cFF4488FF[AzeriteMOP]|r %s set to %s■|r", colorKey, colorStr))
        end
    elseif subCommand == "list" then
        local category = string.lower(args[3] or "")
        self:ListColors(category)
    elseif subCommand == "reset" then
        local category = string.lower(args[3] or "all")
        self:ResetColors(category)
    elseif subCommand == "picker" then
        -- Simple color picker using RGB values
        print("|cFF4488FF[AzeriteMOP]|r Color Reference:")
        local samples = {
            { name = "Red", r = 255, g = 0, b = 0 },
            { name = "Green", r = 0, g = 255, b = 0 },
            { name = "Blue", r = 0, g = 0, b = 255 },
            { name = "Yellow", r = 255, g = 255, b = 0 },
            { name = "Cyan", r = 0, g = 255, b = 255 },
            { name = "Magenta", r = 255, g = 0, b = 255 },
            { name = "Orange", r = 255, g = 165, b = 0 },
            { name = "Purple", r = 128, g = 0, b = 128 },
            { name = "Pink", r = 255, g = 192, b = 203 },
            { name = "Brown", r = 139, g = 69, b = 19 },
            { name = "Gray", r = 128, g = 128, b = 128 },
            { name = "White", r = 255, g = 255, b = 255 },
            { name = "Black", r = 0, g = 0, b = 0 }
        }
        for _, sample in ipairs(samples) do
            local colorStr = string.format("|cFF%02X%02X%02X", sample.r, sample.g, sample.b)
            print(string.format("  %s%s|r - RGB(%d, %d, %d)", colorStr, sample.name, sample.r, sample.g, sample.b))
        end
    elseif subCommand == "class" then
        local enable = string.lower(args[3] or "")
        if enable == "on" then
            self.db.colors.useClassColors = true
            print("|cFF4488FF[AzeriteMOP]|r Class colors enabled")
        elseif enable == "off" then
            self.db.colors.useClassColors = false
            print("|cFF4488FF[AzeriteMOP]|r Class colors disabled")
        else
            print("|cFF4488FF[AzeriteMOP]|r Class colors are " .. (self.db.colors.useClassColors and "enabled" or "disabled"))
            print("  Use: /az color class on/off")
        end
        -- Apply changes
        if self.TargetFrame then self.TargetFrame:UpdateColors() end
        if self.Nameplate then self.Nameplate:UpdateAllColors() end
    else
        print("|cFF4488FF[AzeriteMOP]|r Color commands:")
        print("  /az color set <key> <r> <g> <b> - Set a specific color")
        print("  /az color list [category] - List colors (player/target/castbar/nameplate)")
        print("  /az color reset [category|all] - Reset colors to defaults")
        print("  /az color picker - Show color reference")
        print("  /az color class on/off - Enable/disable class colors")
        print("")
        print("Common color keys:")
        print("  playerHealth, playerPower, playerText")
        print("  targetHealthHostile, targetHealthFriendly")
        print("  castBarNormal, castBarChannel")
        print("  nameplateHealthHostile, nameplateCastBar")
    end
end

function AzeriteMOP:HandleProfileCommand(args)
    local subCommand = string.lower(args[2] or "")
    
    if subCommand == "save" then
        local profileName = args[3]
        if not profileName then
            print("|cFF4488FF[AzeriteMOP]|r Usage: /az profile save <name>")
            return
        end
        self:SaveProfile(profileName)
    elseif subCommand == "load" then
        local profileName = args[3]
        if not profileName then
            print("|cFF4488FF[AzeriteMOP]|r Usage: /az profile load <name>")
            return
        end
        self:LoadProfile(profileName)
    elseif subCommand == "delete" then
        local profileName = args[3]
        if not profileName then
            print("|cFF4488FF[AzeriteMOP]|r Usage: /az profile delete <name>")
            return
        end
        self:DeleteProfile(profileName)
    elseif subCommand == "list" then
        self:ListProfiles()
    elseif subCommand == "current" then
        if self.db.profiles and self.db.profiles.current then
            print("|cFF4488FF[AzeriteMOP]|r Current profile: " .. self.db.profiles.current)
        else
            print("|cFF4488FF[AzeriteMOP]|r No profile system initialized")
        end
    elseif subCommand == "copy" then
        local fromProfile = args[3]
        local toProfile = args[4]
        if not fromProfile or not toProfile then
            print("|cFF4488FF[AzeriteMOP]|r Usage: /az profile copy <from> <to>")
            return
        end
        if self.db.profiles and self.db.profiles.list[fromProfile] then
            self.db.profiles.list[toProfile] = self:CopyTable(self.db.profiles.list[fromProfile])
            print("|cFF4488FF[AzeriteMOP]|r Profile '" .. fromProfile .. "' copied to '" .. toProfile .. "'")
        else
            print("|cFF4488FF[AzeriteMOP]|r Source profile '" .. fromProfile .. "' not found")
        end
    else
        print("|cFF4488FF[AzeriteMOP]|r Profile commands:")
        print("  /az profile save <name> - Save current settings to profile")
        print("  /az profile load <name> - Load a saved profile")
        print("  /az profile delete <name> - Delete a saved profile")
        print("  /az profile list - List all saved profiles")
        print("  /az profile current - Show current profile")
        print("  /az profile copy <from> <to> - Copy a profile")
    end
end

function AzeriteMOP:HandleGlobalScaleCommand(args)
    local subCommand = string.lower(args[2] or "")
    
    if subCommand == "set" then
        local scale = tonumber(args[3])
        if not scale then
            print("|cFF4488FF[AzeriteMOP]|r Usage: /az globalscale set <0.5-2.0>")
            return
        end
        
        scale = math.max(0.5, math.min(2.0, scale))
        self.db.global.uiScale = scale
        self.db.global.useGlobalScale = true
        
        -- Apply to all frames
        self:ApplyGlobalScale()
        
        print("|cFF4488FF[AzeriteMOP]|r Global UI scale set to " .. scale)
    elseif subCommand == "on" then
        self.db.global.useGlobalScale = true
        self:ApplyGlobalScale()
        print("|cFF4488FF[AzeriteMOP]|r Global UI scale enabled (scale: " .. self.db.global.uiScale .. ")")
    elseif subCommand == "off" then
        self.db.global.useGlobalScale = false
        self:RestoreIndividualScales()
        print("|cFF4488FF[AzeriteMOP]|r Global UI scale disabled - using individual frame scales")
    elseif subCommand == "status" then
        print("|cFF4488FF[AzeriteMOP]|r Global UI Scale:")
        print("  Enabled: " .. tostring(self.db.global.useGlobalScale))
        print("  Scale: " .. self.db.global.uiScale)
    else
        print("|cFF4488FF[AzeriteMOP]|r Global scale commands:")
        print("  /az globalscale set <0.5-2.0> - Set and enable global scale")
        print("  /az globalscale on - Enable global scale")
        print("  /az globalscale off - Disable global scale")
        print("  /az globalscale status - Show current settings")
    end
end

function AzeriteMOP:ApplyGlobalScale()
    if not self.db.global.useGlobalScale then
        return
    end
    
    local scale = self.db.global.uiScale
    
    -- Apply to player frame
    if self.PlayerFrame and self.PlayerFrame.frame then
        self.PlayerFrame.frame:SetScale(scale)
    end
    
    -- Apply to target frame
    if self.TargetFrame and self.TargetFrame.frame then
        self.TargetFrame.frame:SetScale(scale)
    end
    
    -- Apply to nameplates if they exist
    if self.Nameplate and self.Nameplate.ApplyGlobalScale then
        self.Nameplate:ApplyGlobalScale(scale)
    end
end

-- Profile System Functions
function AzeriteMOP:GetCurrentSettings()
    -- Return a deep copy of current settings (excluding profiles themselves)
    local settings = {}
    
    if self.db then
        settings.playerFrame = self:CopyTable(self.db.playerFrame or {})
        settings.targetFrame = self:CopyTable(self.db.targetFrame or {})
        settings.explorerMode = self:CopyTable(self.db.explorerMode or {})
        settings.chatFrame = self:CopyTable(self.db.chatFrame or {})
        settings.nameplate = self:CopyTable(self.db.nameplate or {})
        settings.global = self:CopyTable(self.db.global or {})
        settings.colors = self:CopyTable(self.db.colors or {})
        settings.textures = self:CopyTable(self.db.textures or {})
    end
    
    return settings
end

function AzeriteMOP:CopyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[self:CopyTable(orig_key)] = self:CopyTable(orig_value)
        end
    else
        copy = orig
    end
    return copy
end

function AzeriteMOP:SaveProfile(profileName)
    if not profileName or profileName == "" then
        print("|cFF4488FF[AzeriteMOP]|r Invalid profile name")
        return false
    end
    
    -- Initialize profiles if needed
    if not self.db.profiles then
        self.db.profiles = {
            current = "Default",
            list = {}
        }
    end
    
    -- Save current settings to the profile
    self.db.profiles.list[profileName] = self:GetCurrentSettings()
    print("|cFF4488FF[AzeriteMOP]|r Profile '" .. profileName .. "' saved")
    return true
end

function AzeriteMOP:LoadProfile(profileName)
    if not self.db.profiles or not self.db.profiles.list[profileName] then
        print("|cFF4488FF[AzeriteMOP]|r Profile '" .. profileName .. "' not found")
        return false
    end
    
    local profile = self.db.profiles.list[profileName]
    
    -- Apply the profile settings
    self.db.playerFrame = self:CopyTable(profile.playerFrame or {})
    self.db.targetFrame = self:CopyTable(profile.targetFrame or {})
    self.db.explorerMode = self:CopyTable(profile.explorerMode or {})
    self.db.chatFrame = self:CopyTable(profile.chatFrame or {})
    self.db.nameplate = self:CopyTable(profile.nameplate or {})
    self.db.global = self:CopyTable(profile.global or {})
    self.db.colors = self:CopyTable(profile.colors or {})
    self.db.textures = self:CopyTable(profile.textures or {})
    
    -- Update current profile
    self.db.profiles.current = profileName
    
    -- Apply changes to UI
    self:ApplyProfileSettings()
    
    print("|cFF4488FF[AzeriteMOP]|r Profile '" .. profileName .. "' loaded")
    return true
end

function AzeriteMOP:DeleteProfile(profileName)
    if profileName == "Default" then
        print("|cFF4488FF[AzeriteMOP]|r Cannot delete the Default profile")
        return false
    end
    
    if not self.db.profiles or not self.db.profiles.list[profileName] then
        print("|cFF4488FF[AzeriteMOP]|r Profile '" .. profileName .. "' not found")
        return false
    end
    
    -- If deleting current profile, switch to Default
    if self.db.profiles.current == profileName then
        self:LoadProfile("Default")
    end
    
    self.db.profiles.list[profileName] = nil
    print("|cFF4488FF[AzeriteMOP]|r Profile '" .. profileName .. "' deleted")
    return true
end

function AzeriteMOP:CreatePresetProfiles()
    -- Create some preset profiles for common use cases
    
    -- Compact profile - smaller UI for more screen space
    local compact = {
        playerFrame = { 
            enabled = true, 
            scale = 0.8, 
            locked = true,
            position = { "CENTER", UIParent, "CENTER", -200, -150 }
        },
        targetFrame = { 
            enabled = true, 
            scale = 0.8, 
            locked = true,
            position = { "CENTER", UIParent, "CENTER", 200, -150 }
        },
        nameplate = { 
            enabled = true, 
            scale = 0.9,
            width = 100,
            height = 10,
            fontSize = 9
        },
        global = { uiScale = 0.85, useGlobalScale = true },
        explorerMode = { enabled = true, stationaryDelay = 15 },
        chatFrame = { enabled = true, fadeChat = true, hideEditBox = true }
    }
    
    -- Large profile - bigger UI for visibility
    local large = {
        playerFrame = { 
            enabled = true, 
            scale = 1.3, 
            locked = true,
            position = { "CENTER", UIParent, "CENTER", -250, -180 }
        },
        targetFrame = { 
            enabled = true, 
            scale = 1.3, 
            locked = true,
            position = { "CENTER", UIParent, "CENTER", 250, -180 }
        },
        nameplate = { 
            enabled = true, 
            scale = 1.2,
            width = 140,
            height = 14,
            fontSize = 12
        },
        global = { uiScale = 1.2, useGlobalScale = true },
        explorerMode = { enabled = false },
        chatFrame = { enabled = true, fadeChat = false, hideEditBox = false }
    }
    
    -- PvP profile - optimized for PvP
    local pvp = {
        playerFrame = { 
            enabled = true, 
            scale = 1.0, 
            locked = true,
            position = { "CENTER", UIParent, "CENTER", -150, -100 }
        },
        targetFrame = { 
            enabled = true, 
            scale = 1.1, 
            locked = true,
            position = { "CENTER", UIParent, "CENTER", 150, -100 }
        },
        nameplate = { 
            enabled = true, 
            scale = 1.0,
            width = 120,
            height = 12,
            fontSize = 10,
            showCastbar = true,
            classColors = true,
            threatColors = false
        },
        global = { uiScale = 1.0, useGlobalScale = false },
        explorerMode = { enabled = false },
        chatFrame = { enabled = true, fadeChat = false, hideEditBox = true }
    }
    
    -- Raiding profile - clean UI for raiding
    local raid = {
        playerFrame = { 
            enabled = true, 
            scale = 0.9, 
            locked = true,
            position = { "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 300, 300 }
        },
        targetFrame = { 
            enabled = true, 
            scale = 0.9, 
            locked = true,
            position = { "BOTTOM", UIParent, "BOTTOM", 0, 250 }
        },
        nameplate = { 
            enabled = true, 
            scale = 0.8,
            width = 100,
            height = 10,
            fontSize = 9
        },
        global = { uiScale = 0.9, useGlobalScale = true },
        explorerMode = { enabled = false },
        chatFrame = { enabled = true, fadeChat = true, hideEditBox = true }
    }
    
    -- Only create presets if they don't exist
    if not self.db.profiles.list["Compact"] then
        self.db.profiles.list["Compact"] = compact
    end
    if not self.db.profiles.list["Large"] then
        self.db.profiles.list["Large"] = large
    end
    if not self.db.profiles.list["PvP"] then
        self.db.profiles.list["PvP"] = pvp
    end
    if not self.db.profiles.list["Raid"] then
        self.db.profiles.list["Raid"] = raid
    end
end

function AzeriteMOP:ListProfiles()
    if not self.db.profiles or not self.db.profiles.list then
        print("|cFF4488FF[AzeriteMOP]|r No profiles found")
        return
    end
    
    local presets = { "Default", "Compact", "Large", "PvP", "Raid" }
    local presetLookup = {}
    for _, name in ipairs(presets) do
        presetLookup[name] = true
    end
    
    print("|cFF4488FF[AzeriteMOP]|r Available profiles:")
    
    -- Show preset profiles first
    print("  |cFFFFFF00Presets:|r")
    for _, name in ipairs(presets) do
        if self.db.profiles.list[name] then
            local current = ""
            if self.db.profiles.current == name then
                current = " |cFF00FF00(current)|r"
            end
            print("    - " .. name .. current)
        end
    end
    
    -- Show custom profiles
    local hasCustom = false
    for name, _ in pairs(self.db.profiles.list) do
        if not presetLookup[name] then
            if not hasCustom then
                print("  |cFFFFFF00Custom:|r")
                hasCustom = true
            end
            local current = ""
            if self.db.profiles.current == name then
                current = " |cFF00FF00(current)|r"
            end
            print("    - " .. name .. current)
        end
    end
end

function AzeriteMOP:ApplyProfileSettings()
    -- Reapply all settings to the UI
    
    -- Update frame positions and scales
    if self.PlayerFrame and self.PlayerFrame.frame then
        local pos = self.db.playerFrame.position
        if pos and pos[1] then
            self.PlayerFrame.frame:ClearAllPoints()
            self.PlayerFrame.frame:SetPoint(pos[1], UIParent, pos[3] or "CENTER", pos[4] or 0, pos[5] or -150)
        end
        
        local scale = self.db.playerFrame.scale or 1.0
        if self.db.global and self.db.global.useGlobalScale then
            scale = self.db.global.uiScale or 1.0
        end
        self.PlayerFrame.frame:SetScale(scale)
        
        -- Update locked state
        local isLocked = self.db.playerFrame.locked
        self.PlayerFrame.frame:SetMovable(not isLocked)
        self.PlayerFrame.frame:EnableMouse(not isLocked)
    end
    
    if self.TargetFrame and self.TargetFrame.frame then
        local pos = self.db.targetFrame.position
        if pos and pos[1] then
            self.TargetFrame.frame:ClearAllPoints()
            self.TargetFrame.frame:SetPoint(pos[1], UIParent, pos[3] or "CENTER", pos[4] or 0, pos[5] or 150)
        end
        
        if self.TargetFrame.UpdateScaling then
            self.TargetFrame:UpdateScaling()
        end
        
        -- Update locked state
        local isLocked = self.db.targetFrame.locked
        self.TargetFrame.frame:SetMovable(not isLocked)
        self.TargetFrame.frame:EnableMouse(not isLocked)
    end
    
    -- Apply global scale if enabled
    if self.db.global and self.db.global.useGlobalScale then
        self:ApplyGlobalScale()
    end
    
    -- Reinitialize modules if needed
    if self.ExplorerMode and self.ExplorerMode.Initialize then
        -- Explorer mode will check its own enabled state
        if self.db.explorerMode.enabled then
            self.ExplorerMode:ForceEnable()
        else
            self.ExplorerMode:ForceDisable()
        end
    end
end

-- Texture System Functions
function AzeriteMOP:GetTextureList()
    -- List of built-in WoW textures
    return {
        -- Status bar textures
        { name = "Blizzard", path = "Interface\\TargetingFrame\\UI-StatusBar" },
        { name = "Solid", path = "Interface\\Buttons\\WHITE8X8" },
        { name = "Smooth", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Smooth" },
        { name = "Minimalist", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Minimalist" },
        { name = "Flat", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Flat" },
        { name = "Gradient", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Gradient" },
        
        -- Additional Blizzard textures
        { name = "Frost", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Frost" },
        { name = "Healbot", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Healbot" },
        { name = "LiteStep", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\LiteStep" },
        { name = "Otravi", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Otravi" },
        { name = "Perl", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Perl" },
        { name = "Smooth v2", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Smoothv2" },
        { name = "Striped", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Striped" },
        { name = "Aluminium", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Aluminium" },
        { name = "BantoBar", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\BantoBar" },
        { name = "Bars", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Bars" },
        { name = "Button", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Button" },
        { name = "Charcoal", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Charcoal" },
        { name = "Cilo", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Cilo" },
        { name = "Cloud", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Cloud" },
        { name = "Comet", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Comet" },
        { name = "Dabs", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Dabs" },
        { name = "DarkBottom", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\DarkBottom" },
        { name = "Diagonal", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Diagonal" },
        { name = "Empty", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Empty" },
        { name = "Falken", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Falken" },
        { name = "Fifths", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Fifths" },
        { name = "Fourths", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Fourths" },
        { name = "Glamour", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Glamour" },
        { name = "Glamour2", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Glamour2" },
        { name = "Glamour3", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Glamour3" },
        { name = "Glamour4", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Glamour4" },
        { name = "Glamour5", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Glamour5" },
        { name = "Glamour6", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Glamour6" },
        { name = "Glamour7", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Glamour7" },
        { name = "Glass", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Glass" },
        { name = "Glaze", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Glaze" },
        { name = "Gloss", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Gloss" },
        { name = "Graphite", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Graphite" },
        { name = "Grid", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Grid" },
        { name = "Hatched", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Hatched" },
        { name = "Lyfe", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Lyfe" },
        { name = "Melli", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Melli" },
        { name = "MelliDark", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\MelliDark" },
        { name = "MelliDarkRough", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\MelliDarkRough" },
        { name = "Minimalist", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Minimalist" },
        { name = "Norman", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Norman" },
        { name = "Outline", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Outline" },
        { name = "Pip", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Pip" },
        { name = "Rain", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Rain" },
        { name = "Rocks", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Rocks" },
        { name = "Round", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Round" },
        { name = "Ruben", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Ruben" },
        { name = "Runes", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Runes" },
        { name = "Skewed", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Skewed" },
        { name = "Smudge", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Smudge" },
        { name = "Steel", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Steel" },
        { name = "Striped", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Striped" },
        { name = "Tube", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Tube" },
        { name = "Water", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Water" },
        { name = "Wglass", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Wglass" },
        { name = "Wisps", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Wisps" },
        { name = "Xeon", path = "Interface\\AddOns\\AzeriteMOP\\Textures\\Xeon" }
    }
end

function AzeriteMOP:SetTexture(textureKey, texturePath)
    if not self.db.textures then
        self.db.textures = {}
    end
    
    -- Validate texture key
    local validKeys = {
        "healthBar", "powerBar", "castBar",
        "barBackground", "frameBackground", "frameBorder"
    }
    
    local isValid = false
    for _, key in ipairs(validKeys) do
        if key == textureKey then
            isValid = true
            break
        end
    end
    
    if not isValid then
        print("|cFF4488FF[AzeriteMOP]|r Invalid texture key: " .. textureKey)
        print("Valid keys: healthBar, powerBar, castBar, barBackground, frameBackground, frameBorder")
        return false
    end
    
    self.db.textures[textureKey] = texturePath
    
    -- Apply texture changes
    self:ApplyTextureChanges(textureKey)
    
    print("|cFF4488FF[AzeriteMOP]|r " .. textureKey .. " texture updated")
    return true
end

function AzeriteMOP:GetTexture(textureKey)
    if not self.db.textures or not self.db.textures[textureKey] then
        -- Return default texture
        return "Interface\\TargetingFrame\\UI-StatusBar"
    end
    return self.db.textures[textureKey]
end

function AzeriteMOP:ApplyTextureChanges(textureKey)
    -- Apply texture changes to UI elements
    if textureKey == "healthBar" then
        if self.PlayerFrame and self.PlayerFrame.healthBar then
            self.PlayerFrame.healthBar:SetStatusBarTexture(self:GetTexture("healthBar"))
        end
        if self.TargetFrame and self.TargetFrame.healthBar then
            self.TargetFrame.healthBar:SetStatusBarTexture(self:GetTexture("healthBar"))
        end
        if self.Nameplate then
            self.Nameplate:UpdateAllTextures()
        end
    elseif textureKey == "powerBar" then
        if self.PlayerFrame and self.PlayerFrame.powerBar then
            self.PlayerFrame.powerBar:SetStatusBarTexture(self:GetTexture("powerBar"))
        end
        if self.TargetFrame and self.TargetFrame.powerBar then
            self.TargetFrame.powerBar:SetStatusBarTexture(self:GetTexture("powerBar"))
        end
    elseif textureKey == "castBar" then
        if self.TargetFrame and self.TargetFrame.castBar then
            self.TargetFrame.castBar:SetStatusBarTexture(self:GetTexture("castBar"))
        end
        if self.Nameplate then
            self.Nameplate:UpdateAllTextures()
        end
    elseif textureKey == "barBackground" then
        if self.PlayerFrame then
            self.PlayerFrame:UpdateTextures()
        end
        if self.TargetFrame then
            self.TargetFrame:UpdateTextures()
        end
    elseif textureKey == "frameBackground" then
        if self.PlayerFrame then
            self.PlayerFrame:UpdateTextures()
        end
        if self.TargetFrame then
            self.TargetFrame:UpdateTextures()
        end
    end
end

function AzeriteMOP:ApplyAllTextures()
    -- Apply all textures to all frames
    if self.PlayerFrame then
        self.PlayerFrame:UpdateTextures()
    end
    if self.TargetFrame then
        self.TargetFrame:UpdateTextures()
    end
    if self.Nameplate then
        self.Nameplate:UpdateAllTextures()
    end
end

function AzeriteMOP:ResetTextures()
    self.db.textures = {
        healthBar = "Interface\\TargetingFrame\\UI-StatusBar",
        powerBar = "Interface\\TargetingFrame\\UI-StatusBar",
        castBar = "Interface\\TargetingFrame\\UI-StatusBar",
        barBackground = "Interface\\DialogFrame\\UI-DialogBox-Background",
        frameBackground = "Interface\\DialogFrame\\UI-DialogBox-Background",
        frameBorder = "Interface\\Tooltips\\UI-Tooltip-Border",
        custom = {}
    }
    
    self:ApplyAllTextures()
    print("|cFF4488FF[AzeriteMOP]|r All textures reset to defaults")
end

function AzeriteMOP:AddCustomTexture(name, path)
    if not self.db.textures.custom then
        self.db.textures.custom = {}
    end
    
    self.db.textures.custom[name] = path
    print("|cFF4488FF[AzeriteMOP]|r Custom texture '" .. name .. "' added")
end

-- Color System Functions
function AzeriteMOP:SetColor(colorKey, r, g, b)
    if not self.db.colors then
        self.db.colors = {}
    end
    
    if not self.db.colors[colorKey] then
        print("|cFF4488FF[AzeriteMOP]|r Unknown color key: " .. colorKey)
        return false
    end
    
    -- If r is nil, reset to default
    if r == nil then
        -- Get default color based on key
        local defaults = {
            playerHealth = { r = 0.0, g = 0.8, b = 0.0 },
            playerHealthBg = { r = 0.1, g = 0.1, b = 0.1 },
            playerPower = { r = 0.0, g = 0.5, b = 1.0 },
            playerPowerBg = { r = 0.1, g = 0.1, b = 0.2 },
            playerText = { r = 1.0, g = 1.0, b = 1.0 },
            playerLevelText = { r = 1.0, g = 0.82, b = 0.0 },
            targetHealthFriendly = { r = 0.0, g = 1.0, b = 0.0 },
            targetHealthNeutral = { r = 1.0, g = 1.0, b = 0.0 },
            targetHealthHostile = { r = 1.0, g = 0.0, b = 0.0 },
            targetHealthBg = { r = 0.1, g = 0.1, b = 0.1 },
            targetPower = { r = 0.0, g = 0.5, b = 1.0 },
            targetPowerBg = { r = 0.1, g = 0.1, b = 0.2 },
            targetText = { r = 1.0, g = 1.0, b = 1.0 },
            targetLevelText = { r = 1.0, g = 0.82, b = 0.0 },
            castBarNormal = { r = 1.0, g = 0.7, b = 0.0 },
            castBarChannel = { r = 0.0, g = 1.0, b = 0.0 },
            castBarInterrupted = { r = 1.0, g = 0.0, b = 0.0 },
            castBarBg = { r = 0.1, g = 0.1, b = 0.1 },
            castBarText = { r = 1.0, g = 1.0, b = 1.0 },
            castBarTimeText = { r = 0.8, g = 0.8, b = 0.8 },
            -- Nameplate colors
            nameplateHealthFriendly = { r = 0.0, g = 1.0, b = 0.0 },
            nameplateHealthNeutral = { r = 1.0, g = 1.0, b = 0.0 },
            nameplateHealthHostile = { r = 1.0, g = 0.0, b = 0.0 },
            nameplateHealthBg = { r = 0.1, g = 0.1, b = 0.1 },
            nameplateCastBar = { r = 1.0, g = 0.7, b = 0.0 },
            nameplateCastBarBg = { r = 0.1, g = 0.1, b = 0.1 },
            nameplateText = { r = 1.0, g = 1.0, b = 1.0 },
            nameplateLevelText = { r = 1.0, g = 0.82, b = 0.0 }
        }
        
        if defaults[colorKey] then
            self.db.colors[colorKey] = defaults[colorKey]
        end
    else
        -- Clamp values between 0 and 1
        r = math.max(0, math.min(1, r))
        g = math.max(0, math.min(1, g))
        b = math.max(0, math.min(1, b))
        
        self.db.colors[colorKey] = { r = r, g = g, b = b }
    end
    
    -- Apply the color change immediately
    self:ApplyColorChanges(colorKey)
    
    return true
end

function AzeriteMOP:GetColor(colorKey)
    if not self.db.colors or not self.db.colors[colorKey] then
        return 1.0, 1.0, 1.0  -- Default to white
    end
    
    local color = self.db.colors[colorKey]
    return color.r, color.g, color.b
end

function AzeriteMOP:ApplyColorChanges(colorKey)
    -- Apply color changes to specific UI elements
    if string.find(colorKey, "player") then
        if self.PlayerFrame then
            self.PlayerFrame:UpdateColors()
        end
    elseif string.find(colorKey, "target") then
        if self.TargetFrame then
            self.TargetFrame:UpdateColors()
        end
    elseif string.find(colorKey, "nameplate") then
        if self.Nameplate then
            self.Nameplate:UpdateAllColors()
        end
    elseif string.find(colorKey, "cast") then
        -- Update cast bars on all frames
        if self.PlayerFrame then
            self.PlayerFrame:UpdateColors()
        end
        if self.TargetFrame then
            self.TargetFrame:UpdateColors()
        end
        if self.Nameplate then
            self.Nameplate:UpdateAllColors()
        end
    end
end

function AzeriteMOP:ResetColors(category)
    -- Reset colors to defaults
    local defaults = {
        player = {
            playerHealth = { r = 0.0, g = 0.8, b = 0.0 },
            playerHealthBg = { r = 0.1, g = 0.1, b = 0.1 },
            playerPower = { r = 0.0, g = 0.5, b = 1.0 },
            playerPowerBg = { r = 0.1, g = 0.1, b = 0.2 },
            playerText = { r = 1.0, g = 1.0, b = 1.0 },
            playerLevelText = { r = 1.0, g = 0.82, b = 0.0 }
        },
        target = {
            targetHealthFriendly = { r = 0.0, g = 1.0, b = 0.0 },
            targetHealthNeutral = { r = 1.0, g = 1.0, b = 0.0 },
            targetHealthHostile = { r = 1.0, g = 0.0, b = 0.0 },
            targetHealthBg = { r = 0.1, g = 0.1, b = 0.1 },
            targetPower = { r = 0.0, g = 0.5, b = 1.0 },
            targetPowerBg = { r = 0.1, g = 0.1, b = 0.2 },
            targetText = { r = 1.0, g = 1.0, b = 1.0 },
            targetLevelText = { r = 1.0, g = 0.82, b = 0.0 }
        },
        castbar = {
            castBarNormal = { r = 1.0, g = 0.7, b = 0.0 },
            castBarChannel = { r = 0.0, g = 1.0, b = 0.0 },
            castBarInterruptible = { r = 1.0, g = 0.7, b = 0.0 },
            castBarNotInterruptible = { r = 0.7, g = 0.7, b = 0.7 },
            castBarBg = { r = 0.1, g = 0.1, b = 0.1 },
            castBarText = { r = 1.0, g = 1.0, b = 1.0 },
            castBarTimeText = { r = 1.0, g = 1.0, b = 0.0 }
        },
        nameplate = {
            nameplateHealthFriendly = { r = 0.0, g = 1.0, b = 0.0 },
            nameplateHealthNeutral = { r = 1.0, g = 1.0, b = 0.0 },
            nameplateHealthHostile = { r = 1.0, g = 0.0, b = 0.0 },
            nameplateHealthBg = { r = 0.1, g = 0.1, b = 0.1 },
            nameplateCastBar = { r = 1.0, g = 0.7, b = 0.0 },
            nameplateCastBarBg = { r = 0.1, g = 0.1, b = 0.1 },
            nameplateNameText = { r = 1.0, g = 1.0, b = 1.0 },
            nameplateLevelText = { r = 1.0, g = 0.82, b = 0.0 }
        }
    }
    
    if category == "all" then
        for cat, colors in pairs(defaults) do
            for key, color in pairs(colors) do
                self.db.colors[key] = color
            end
        end
        print("|cFF4488FF[AzeriteMOP]|r All colors reset to defaults")
    elseif defaults[category] then
        for key, color in pairs(defaults[category]) do
            self.db.colors[key] = color
        end
        print("|cFF4488FF[AzeriteMOP]|r " .. category .. " colors reset to defaults")
    else
        print("|cFF4488FF[AzeriteMOP]|r Unknown category. Use: player, target, castbar, nameplate, or all")
        return
    end
    
    -- Apply changes
    if self.PlayerFrame then self.PlayerFrame:UpdateColors() end
    if self.TargetFrame then self.TargetFrame:UpdateColors() end
    if self.Nameplate then self.Nameplate:UpdateAllColors() end
end

function AzeriteMOP:ListColors(category)
    if not self.db.colors then
        print("|cFF4488FF[AzeriteMOP]|r No colors configured")
        return
    end
    
    local categories = {
        player = "Player Frame",
        target = "Target Frame",
        castbar = "Cast Bars",
        nameplate = "Nameplates"
    }
    
    if category and categories[category] then
        print("|cFF4488FF[AzeriteMOP]|r " .. categories[category] .. " Colors:")
        for key, color in pairs(self.db.colors) do
            if string.find(key, category) or (category == "castbar" and string.find(key, "castBar")) then
                local r, g, b = color.r * 255, color.g * 255, color.b * 255
                local colorStr = string.format("|cFF%02X%02X%02X", r, g, b)
                print(string.format("  %s: %s■|r RGB(%.0f, %.0f, %.0f)", key, colorStr, r, g, b))
            end
        end
    else
        print("|cFF4488FF[AzeriteMOP]|r Available color categories:")
        for key, name in pairs(categories) do
            print("  " .. key .. " - " .. name)
        end
        print("Use: /az color list <category> to see specific colors")
    end
end

function AzeriteMOP:RestoreIndividualScales()
    -- Restore player frame scale
    if self.PlayerFrame and self.PlayerFrame.frame then
        self.PlayerFrame.frame:SetScale(self.db.playerFrame.scale or 1.0)
    end
    
    -- Restore target frame scale
    if self.TargetFrame and self.TargetFrame.frame then
        self.TargetFrame.frame:SetScale(self.db.targetFrame.scale or 1.0)
    end
    
    -- Restore nameplate scales
    if self.Nameplate and self.Nameplate.RestoreIndividualScales then
        self.Nameplate:RestoreIndividualScales()
    end
end

function AzeriteMOP:UpdateAllColors()
    -- Update colors for all modules
    if self.PlayerFrame and self.PlayerFrame.UpdateColors then
        self.PlayerFrame:UpdateColors()
    end
    if self.TargetFrame and self.TargetFrame.UpdateColors then
        self.TargetFrame:UpdateColors()
    end
    if self.Nameplate and self.Nameplate.UpdateAllColors then
        self.Nameplate:UpdateAllColors()
    end
end

function AzeriteMOP:UpdateAllTextures()
    -- Update textures for all modules
    if self.PlayerFrame and self.PlayerFrame.UpdateTextures then
        self.PlayerFrame:UpdateTextures()
    end
    if self.TargetFrame and self.TargetFrame.UpdateTextures then
        self.TargetFrame:UpdateTextures()
    end
    if self.Nameplate and self.Nameplate.UpdateAllTextures then
        self.Nameplate:UpdateAllTextures()
    end
end

function AzeriteMOP:HandleScaleCommand(args)
    local frameType = string.lower(args[2] or "all")
    local scale = tonumber(args[3])
    
    -- Check if global scale is enabled
    if self.db.global and self.db.global.useGlobalScale then
        print("|cFF4488FF[AzeriteMOP]|r Global scale is enabled. Use /az globalscale off to disable it first.")
        return
    end
    
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
    print("  |cFFFFD700/az settings|r - Open the settings menu GUI")
    print("  |cFFFFFF00Frame Commands:|r")
    print("  /az lock - Toggle frame lock (movable/immovable)")
    print("  /az scale [player|target] [0.5-2.0] - Scale frames individually")
    print("  /az globalscale set [0.5-2.0] - Set global UI scale for all frames")
    print("  /az globalscale on/off - Enable/disable global scaling")
    print("  /az fontscale [player|target|all] [0.5-3.0] - Scale fonts")
    print("  /az resetfonts [player|target|all] - Reset fonts to default size")
    print("  /az reset - Reset all frame positions and scales")
    print("  |cFFFFFF00Explorer Mode:|r")
    print("  /az explorer on - Enable explorer mode")
    print("  /az explorer off - Disable explorer mode")
    print("  /az explorer setdelay <seconds> - Set UI hide delay")
    print("  |cFFFFFF00Chat Commands:|r")
    print("  /az chat toggle - Toggle chat enhancements")
    print("  /az chat copy - Open copy chat window")
    print("  |cFFFFFF00Color Customization:|r")
    print("  /az color set <key> <r> <g> <b> - Set a color (RGB 0-255)")
    print("  /az color list [category] - List available colors")
    print("  /az color reset [category|all] - Reset to defaults")
    print("  /az color picker - Show color reference")
    print("  |cFFFFFF00Profile System:|r")
    print("  /az profile save <name> - Save current settings as profile")
    print("  /az profile load <name> - Load a saved profile")
    print("  /az profile list - List all profiles")
    print("  /az profile delete <name> - Delete a profile")
    print("  |cFFFFFF00Database:|r")
    print("  /az resetdb - Reset all settings to defaults")
    print("  /az help - Show this help")
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
    -- AzeriteMOP:Debug("Explorer mode active state set to: " .. tostring(active))
end

function AzeriteMOP:GetExplorerModeActive()
    self:EnsureDatabase()
    return self.db.explorerMode.isActive or false
end

function AzeriteMOP:SetExplorerModeEnabled(enabled)
    self:EnsureDatabase()
    self.db.explorerMode.enabled = enabled
    -- AzeriteMOP:Debug("Explorer mode enabled state set to: " .. tostring(enabled))
end

function AzeriteMOP:GetExplorerModeEnabled()
    self:EnsureDatabase()
    return self.db.explorerMode.enabled or false
end

-- Safety check
if not AzeriteMOP:IsMoPClassic() then
    error("AzeriteMOP: This addon is designed for MoP Classic (5.4.x) only!")
end