-- AzeriteMOP Explorer Mode Module
-- Simple UI hiding for immersive experience

local ADDON_NAME, Addon = ...
local AzeriteMOP = Addon.AzeriteMOP

-- Create ExplorerMode module
AzeriteMOP.ExplorerMode = {}
local ExplorerMode = AzeriteMOP.ExplorerMode

-- Simple state tracking
ExplorerMode.chatFadeTimer = nil
ExplorerMode.chatActive = false
ExplorerMode.lastFocusTime = 0
ExplorerMode.watchFrameFadeTimer = nil
ExplorerMode.microMenuFadeTimer = nil
ExplorerMode.watchFrameCooldown = nil
ExplorerMode.microMenuCooldown = nil

-- Get active state from Core database
function ExplorerMode:GetIsActive()
    if AzeriteMOP and AzeriteMOP.GetExplorerModeActive then
        return AzeriteMOP:GetExplorerModeActive()
    elseif AzeriteMOP and AzeriteMOP.db and AzeriteMOP.db.explorerMode then
        -- Direct database access as fallback
        return AzeriteMOP.db.explorerMode.isActive or false
    else
        -- Fallback to local state if Core functions aren't available yet
        return ExplorerMode._localIsActive or false
    end
end

function ExplorerMode:SetIsActive(active)
    ExplorerMode._localIsActive = active
    if AzeriteMOP and AzeriteMOP.SetExplorerModeActive then
        AzeriteMOP:SetExplorerModeActive(active)
    end
end

-- Force enable/disable methods for Core.lua compatibility
function ExplorerMode:ForceEnable()
    -- AzeriteMOP:Debug("ExplorerMode: ForceEnable called")
    self:SetIsActive(true)
    self:HideUI()
end

function ExplorerMode:ForceDisable()
    -- AzeriteMOP:Debug("ExplorerMode: ForceDisable called")
    self:SetIsActive(false)
    self:ShowUI()
end

-- Initialize database
if AzeriteMOP and not AzeriteMOP.db then
    AzeriteMOP.db = {}
end

if AzeriteMOP and AzeriteMOP.db and not AzeriteMOP.db.explorerMode then
    AzeriteMOP.db.explorerMode = {
        enabled = true
    }
end

function ExplorerMode:Initialize()
    -- AzeriteMOP:Debug("ExplorerMode: Initialize called")
    self:SetupSlashCommands()
    self:SetupChatHooks()
    
    -- Wait a frame to ensure Core functions are available, then restore state
    C_Timer.After(0.1, function()
        -- Restore explorer mode state from saved variables
        if self:GetIsActive() then
            -- AzeriteMOP:Debug("ExplorerMode: Restoring active state from saved variables")
            self:HideUI()
        else
            -- AzeriteMOP:Debug("ExplorerMode: No active state to restore")
        end
    end)
end

function ExplorerMode:SetupSlashCommands()
    -- Add simple test commands
    SLASH_EXPLORER_TEST1 = "/explorer"
    SlashCmdList["EXPLORER_TEST"] = function(msg)
        if msg == "hide" then
            -- AzeriteMOP:Debug("ExplorerMode: Hiding UI")
            self:HideUI()
        elseif msg == "show" then
            -- AzeriteMOP:Debug("ExplorerMode: Showing UI")
            self:ShowUI()
        elseif msg == "on" then
            -- AzeriteMOP:Debug("ExplorerMode: Enabling explorer mode")
            self:SetIsActive(true)
            self:HideUI()
        elseif msg == "off" then
            -- AzeriteMOP:Debug("ExplorerMode: Disabling explorer mode")
            self:SetIsActive(false)
            self:ShowUI()
        elseif msg == "debug" then
            -- AzeriteMOP:Debug("ExplorerMode: Toggling debug frames")
            self:ToggleDebugFrames()
        elseif msg == "status" then
            -- AzeriteMOP:Debug("ExplorerMode: Checking status")
            local isActive = self:GetIsActive()
            print("|cFF4488FF[AzeriteMOP]|r Explorer mode active: " .. tostring(isActive))
            if AzeriteMOP and AzeriteMOP.db and AzeriteMOP.db.explorerMode then
                print("|cFF4488FF[AzeriteMOP]|r Database isActive: " .. tostring(AzeriteMOP.db.explorerMode.isActive))
            end
        else
            print("ExplorerMode Commands:")
            print("/explorer hide - Hide UI")
            print("/explorer show - Show UI")
            print("/explorer on - Enable explorer mode")
            print("/explorer off - Disable explorer mode")
            print("/explorer status - Check current status")
            print("/explorer debug - Toggle debug frame borders")
        end
    end
end

function ExplorerMode:SetupChatHooks()
    -- AzeriteMOP:Debug("ExplorerMode: Setting up chat hooks")
    
    local chatEditBox = _G["ChatFrame1EditBox"]
    if chatEditBox then
        -- AzeriteMOP:Debug("ExplorerMode: Found ChatFrame1EditBox")
        
        -- Store original functions
        chatEditBox._originalOnEditFocusGained = chatEditBox:GetScript("OnEditFocusGained")
        chatEditBox._originalOnEditFocusLost = chatEditBox:GetScript("OnEditFocusLost")
        chatEditBox._originalOnChar = chatEditBox:GetScript("OnChar")
        chatEditBox._originalOnKeyDown = chatEditBox:GetScript("OnKeyDown")
        
        -- Hook into focus gained (when chat is opened)
        chatEditBox:SetScript("OnEditFocusGained", function(self)
            local currentTime = GetTime()
            -- AzeriteMOP:Debug("ExplorerMode: Chat focus gained")
            -- Only trigger if user actually clicked on chat or pressed Enter
            if ExplorerMode:GetIsActive() and not ExplorerMode.chatActive and (currentTime - ExplorerMode.lastFocusTime) > 0.5 then
                -- Check if this is actual user interaction, not system messages
                local text = self:GetText()
                if text == "" or text == nil then
                    -- Only show chat if user is actually typing (empty text means fresh focus)
                    ExplorerMode.chatActive = true
                    ExplorerMode.lastFocusTime = currentTime
                    ExplorerMode:ShowChat()
                else
                    -- If text exists, it might be a system message - show briefly then fade
                    -- AzeriteMOP:Debug("ExplorerMode: Chat focus gained with existing text - showing briefly")
                    ExplorerMode.chatActive = true
                    ExplorerMode.lastFocusTime = currentTime
                    ExplorerMode:ShowChat()
                    -- Auto-fade after a short delay
                    C_Timer.After(2.0, function()
                        if ExplorerMode:GetIsActive() and ExplorerMode.chatActive then
                            ExplorerMode:OnChatSubmitted()
                        end
                    end)
                end
            end
            if chatEditBox._originalOnEditFocusGained then
                chatEditBox._originalOnEditFocusGained(self)
            end
        end)
        
        -- Hook into key down to detect Enter key
        chatEditBox:SetScript("OnKeyDown", function(self, key)
            if ExplorerMode:GetIsActive() and key == "ENTER" then
                local text = self:GetText()
                -- AzeriteMOP:Debug("ExplorerMode: Enter key pressed with text: " .. (text or "empty"))
                -- Only trigger if user is actually typing (not system messages)
                if ExplorerMode.chatActive then
                    ExplorerMode:OnChatSubmitted()
                end
            end
            if chatEditBox._originalOnKeyDown then
                chatEditBox._originalOnKeyDown(self, key)
            end
        end)
        
        -- Hook into focus lost (when chat is submitted)
        chatEditBox:SetScript("OnEditFocusLost", function(self)
            -- AzeriteMOP:Debug("ExplorerMode: Chat focus lost")
            if ExplorerMode:GetIsActive() and ExplorerMode.chatActive then
                local text = self:GetText()
                -- AzeriteMOP:Debug("ExplorerMode: Chat focus lost with text: " .. (text or "empty"))
                -- Only trigger fade if user was actually typing
                if text and text ~= "" then
                    ExplorerMode:OnChatSubmitted()
                else
                    -- If no text was entered, just hide chat immediately
                    ExplorerMode:ShowChat()
                    ExplorerMode:OnChatSubmitted()
                end
                ExplorerMode.chatActive = false
            end
            if chatEditBox._originalOnEditFocusLost then
                chatEditBox._originalOnEditFocusLost(self)
            end
        end)
    else
        -- AzeriteMOP:Debug("ExplorerMode: ChatFrame1EditBox not found")
    end
end

function ExplorerMode:HideUI()
    -- AzeriteMOP:Debug("ExplorerMode: HideUI called")
    
    -- Hide chat frame
    local chatFrame1 = _G["ChatFrame1"]
    if chatFrame1 then
        -- AzeriteMOP:Debug("ExplorerMode: Hiding ChatFrame1")
        chatFrame1:Hide()
    else
        -- AzeriteMOP:Debug("ExplorerMode: ChatFrame1 not found")
    end
    
    -- Hide quest frame (WatchFrame) and set up mouse-over functionality
    local watchFrame = _G["WatchFrame"]
    if watchFrame then
        -- AzeriteMOP:Debug("ExplorerMode: Hiding WatchFrame")
        watchFrame:Hide()
        
        -- Set up mouse-over functionality for WatchFrame
        self:SetupWatchFrameMouseOver(watchFrame)
    else
        -- AzeriteMOP:Debug("ExplorerMode: WatchFrame not found")
    end
    
    -- Hide MicroMenu buttons and set up mouse-over functionality
    local microButtons = {"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
                         "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton", 
                         "LFGMicroButton", "CollectionsMicroButton", "EJMicroButton", 
                         "PVPMicroButton", "MainMenuMicroButton", "StoreMicroButton", "HelpMicroButton"}
    for _, buttonName in ipairs(microButtons) do
        local button = _G[buttonName]
        if button then
            -- AzeriteMOP:Debug("ExplorerMode: Hiding " .. buttonName)
            button:Hide()
        else
            -- AzeriteMOP:Debug("ExplorerMode: " .. buttonName .. " not found")
        end
    end
    
    -- Set up mouse-over functionality for MicroMenu
    self:SetupMicroMenuMouseOver()
end

function ExplorerMode:ShowUI()
    -- AzeriteMOP:Debug("ExplorerMode: ShowUI called")
    
    -- Show chat frame
    local chatFrame1 = _G["ChatFrame1"]
    if chatFrame1 then
        -- AzeriteMOP:Debug("ExplorerMode: Showing ChatFrame1")
        chatFrame1:Show()
        chatFrame1:SetAlpha(1.0)
    else
        -- AzeriteMOP:Debug("ExplorerMode: ChatFrame1 not found")
    end
    
    -- Show quest frame (WatchFrame) and clean up overlay
    local watchFrame = _G["WatchFrame"]
    if watchFrame then
        -- AzeriteMOP:Debug("ExplorerMode: Showing WatchFrame")
        watchFrame:Show()
        watchFrame:SetAlpha(1.0)
        
        -- Clean up the overlay frame
        if self.watchFrameOverlay then
            -- AzeriteMOP:Debug("ExplorerMode: Cleaning up WatchFrame overlay")
            self.watchFrameOverlay:Hide()
            self.watchFrameOverlay = nil
        end
    else
        -- AzeriteMOP:Debug("ExplorerMode: WatchFrame not found")
    end
    
    -- Show MicroMenu buttons and clean up overlay
    local microButtons = {"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
                         "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton", 
                         "LFGMicroButton", "CollectionsMicroButton", "EJMicroButton", 
                         "PVPMicroButton", "MainMenuMicroButton", "StoreMicroButton", "HelpMicroButton"}
    for _, buttonName in ipairs(microButtons) do
        local button = _G[buttonName]
        if button then
            -- AzeriteMOP:Debug("ExplorerMode: Showing " .. buttonName)
            button:Show()
            button:SetAlpha(1.0)
        else
            -- AzeriteMOP:Debug("ExplorerMode: " .. buttonName .. " not found")
        end
    end
    
    -- Clean up the MicroMenu overlay frame
    if self.microMenuOverlay then
        -- AzeriteMOP:Debug("ExplorerMode: Cleaning up MicroMenu overlay")
        self.microMenuOverlay:Hide()
        self.microMenuOverlay = nil
    end
end

function ExplorerMode:SetupWatchFrameMouseOver(watchFrame)
    -- AzeriteMOP:Debug("ExplorerMode: Setting up WatchFrame mouse-over")
    
    -- Create an invisible overlay frame in the WatchFrame area
    local overlayFrame = CreateFrame("Frame", "ExplorerModeWatchFrameOverlay", UIParent)
    overlayFrame:SetFrameStrata("MEDIUM")
    overlayFrame:SetFrameLevel(watchFrame:GetFrameLevel() - 1)
    
    -- Position the overlay to match WatchFrame area (right side of screen) - more precise positioning
    overlayFrame:SetPoint("TOPLEFT", UIParent, "TOPRIGHT", -220, -20)
    overlayFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 150)
    
    -- Make it invisible but clickable
    overlayFrame:EnableMouse(true)
    
    -- Add a background texture for debugging
    local bgTexture = overlayFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints()
    bgTexture:SetColorTexture(0, 1, 0, 0.0) -- Green, fully transparent initially
    overlayFrame.bgTexture = bgTexture
    
    -- Set up mouse enter (show WatchFrame)
    overlayFrame:SetScript("OnEnter", function(self)
        -- AzeriteMOP:Debug("ExplorerMode: Mouse entered WatchFrame overlay area")
        local isActive = ExplorerMode:GetIsActive()
        -- AzeriteMOP:Debug("ExplorerMode: isActive = " .. tostring(isActive) .. ", isShowing = " .. tostring(self.isShowing) .. ", cooldown = " .. tostring(ExplorerMode.watchFrameCooldown ~= nil))
        
        if isActive and not self.isShowing and not ExplorerMode.watchFrameCooldown then
            -- AzeriteMOP:Debug("ExplorerMode: Mouse over WatchFrame area - showing")
            
            -- Cancel any existing fade timer
            if ExplorerMode.watchFrameFadeTimer then
                ExplorerMode.watchFrameFadeTimer:Cancel()
            end
            
            -- Show WatchFrame immediately and bring it to front
            watchFrame:Show()
            watchFrame:SetAlpha(1.0)
            watchFrame:SetFrameStrata("HIGH")
            watchFrame:SetFrameLevel(1000)
            
            -- Mark as showing
            self.isShowing = true
            
            -- Set cooldown to prevent rapid triggering
            ExplorerMode.watchFrameCooldown = C_Timer.NewTimer(0.5, function()
                ExplorerMode.watchFrameCooldown = nil
            end)
        else
            -- AzeriteMOP:Debug("ExplorerMode: Mouse over WatchFrame area - conditions not met")
        end
    end)
    
    -- Set up mouse leave (fade out WatchFrame)
    overlayFrame:SetScript("OnLeave", function(self)
        if ExplorerMode:GetIsActive() and self.isShowing and not ExplorerMode.watchFrameCooldown then
            -- AzeriteMOP:Debug("ExplorerMode: Mouse left WatchFrame area - fading out")
            
            -- Cancel any existing fade timer
            if ExplorerMode.watchFrameFadeTimer then
                ExplorerMode.watchFrameFadeTimer:Cancel()
            end
            
            -- Mark as not showing
            self.isShowing = false
            
            -- Set cooldown to prevent rapid triggering
            ExplorerMode.watchFrameCooldown = C_Timer.NewTimer(0.5, function()
                ExplorerMode.watchFrameCooldown = nil
            end)
            
            -- Fade out after 3 seconds
            ExplorerMode.watchFrameFadeTimer = C_Timer.NewTimer(3.0, function()
                if ExplorerMode:GetIsActive() then
                    -- AzeriteMOP:Debug("ExplorerMode: Fading out WatchFrame")
                    
                    -- Create a smooth fade animation
                    local fadeStart = GetTime()
                    local fadeDuration = 1.0 -- 1 second fade
                    
                    local fadeFrame = CreateFrame("Frame")
                    fadeFrame:SetScript("OnUpdate", function(_, elapsed)
                        local elapsed = GetTime() - fadeStart
                        local progress = elapsed / fadeDuration
                        
                        if progress >= 1.0 then
                            -- Fade complete, hide WatchFrame
                            -- AzeriteMOP:Debug("ExplorerMode: WatchFrame fade complete, hiding")
                            watchFrame:Hide()
                            fadeFrame:SetScript("OnUpdate", nil)
                            fadeFrame:Hide()
                        else
                            -- Fade in progress
                            local alpha = 1.0 - progress
                            watchFrame:SetAlpha(alpha)
                        end
                    end)
                end
                ExplorerMode.watchFrameFadeTimer = nil
            end)
        end
    end)
    
    -- Store reference to overlay frame
    ExplorerMode.watchFrameOverlay = overlayFrame
end

function ExplorerMode:SetupMicroMenuMouseOver()
    -- AzeriteMOP:Debug("ExplorerMode: Setting up MicroMenu mouse-over")
    
    -- Create an invisible overlay frame in the MicroMenu area (bottom-right)
    local overlayFrame = CreateFrame("Frame", "ExplorerModeMicroMenuOverlay", UIParent)
    overlayFrame:SetFrameStrata("MEDIUM")
    overlayFrame:SetFrameLevel(1)
    
    -- Position the overlay to match MicroMenu area (bottom-right corner) - double width
    overlayFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", -360, 60)
    overlayFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 10)
    
    -- Make it invisible but clickable
    overlayFrame:EnableMouse(true)
    
    -- Add a background texture for debugging
    local bgTexture = overlayFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints()
    bgTexture:SetColorTexture(1, 0, 0, 0.0) -- Red, fully transparent initially
    overlayFrame.bgTexture = bgTexture
    
    -- Set up mouse enter (show MicroMenu)
    overlayFrame:SetScript("OnEnter", function(self)
        -- AzeriteMOP:Debug("ExplorerMode: Mouse entered MicroMenu overlay area")
        local isActive = ExplorerMode:GetIsActive()
        -- AzeriteMOP:Debug("ExplorerMode: isActive = " .. tostring(isActive) .. ", isShowing = " .. tostring(self.isShowing) .. ", cooldown = " .. tostring(ExplorerMode.microMenuCooldown ~= nil))
        
        if isActive and not self.isShowing and not ExplorerMode.microMenuCooldown then
            -- AzeriteMOP:Debug("ExplorerMode: Mouse over MicroMenu area - showing")
            
            -- Cancel any existing fade timer
            if ExplorerMode.microMenuFadeTimer then
                ExplorerMode.microMenuFadeTimer:Cancel()
            end
            
            -- Show all MicroMenu buttons immediately and bring them to front
            local microButtons = {"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
                                 "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton", 
                                 "LFGMicroButton", "CollectionsMicroButton", "EJMicroButton", 
                                 "PVPMicroButton", "MainMenuMicroButton", "StoreMicroButton", "HelpMicroButton"}
            for _, buttonName in ipairs(microButtons) do
                local button = _G[buttonName]
                if button then
                    button:Show()
                    button:SetAlpha(1.0)
                    button:SetFrameStrata("HIGH")
                    button:SetFrameLevel(1000)
                end
            end
            
            -- Mark as showing
            self.isShowing = true
            
            -- Set cooldown to prevent rapid triggering
            ExplorerMode.microMenuCooldown = C_Timer.NewTimer(0.5, function()
                ExplorerMode.microMenuCooldown = nil
            end)
        else
            -- AzeriteMOP:Debug("ExplorerMode: Mouse over MicroMenu area - conditions not met")
        end
    end)
    
    -- Set up mouse leave (fade out MicroMenu)
    overlayFrame:SetScript("OnLeave", function(self)
        if ExplorerMode:GetIsActive() and self.isShowing and not ExplorerMode.microMenuCooldown then
            -- AzeriteMOP:Debug("ExplorerMode: Mouse left MicroMenu area - fading out")
            
            -- Cancel any existing fade timer
            if ExplorerMode.microMenuFadeTimer then
                ExplorerMode.microMenuFadeTimer:Cancel()
            end
            
            -- Mark as not showing
            self.isShowing = false
            
            -- Set cooldown to prevent rapid triggering
            ExplorerMode.microMenuCooldown = C_Timer.NewTimer(0.5, function()
                ExplorerMode.microMenuCooldown = nil
            end)
            
            -- Fade out after 3 seconds
            ExplorerMode.microMenuFadeTimer = C_Timer.NewTimer(3.0, function()
                if ExplorerMode:GetIsActive() then
                    -- AzeriteMOP:Debug("ExplorerMode: Fading out MicroMenu")
                    
                    -- Create a smooth fade animation
                    local fadeStart = GetTime()
                    local fadeDuration = 1.0 -- 1 second fade
                    
                    local fadeFrame = CreateFrame("Frame")
                    fadeFrame:SetScript("OnUpdate", function(_, elapsed)
                        local elapsed = GetTime() - fadeStart
                        local progress = elapsed / fadeDuration
                        
                        if progress >= 1.0 then
                            -- Fade complete, hide all MicroMenu buttons
                            -- AzeriteMOP:Debug("ExplorerMode: MicroMenu fade complete, hiding")
                            local microButtons = {"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
                                                 "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton", 
                                                 "LFGMicroButton", "CollectionsMicroButton", "EJMicroButton", 
                                                 "PVPMicroButton", "MainMenuMicroButton", "StoreMicroButton", "HelpMicroButton"}
                            for _, buttonName in ipairs(microButtons) do
                                local button = _G[buttonName]
                                if button then
                                    button:Hide()
                                end
                            end
                            fadeFrame:SetScript("OnUpdate", nil)
                            fadeFrame:Hide()
                        else
                            -- Fade in progress
                            local alpha = 1.0 - progress
                            local microButtons = {"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
                                                 "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton", 
                                                 "LFGMicroButton", "CollectionsMicroButton", "EJMicroButton", 
                                                 "PVPMicroButton", "MainMenuMicroButton", "StoreMicroButton", "HelpMicroButton"}
                            for _, buttonName in ipairs(microButtons) do
                                local button = _G[buttonName]
                                if button then
                                    button:SetAlpha(alpha)
                                end
                            end
                        end
                    end)
                end
                ExplorerMode.microMenuFadeTimer = nil
            end)
        end
    end)
    
    -- Store reference to overlay frame
    ExplorerMode.microMenuOverlay = overlayFrame
end

function ExplorerMode:ToggleDebugFrames()
    -- AzeriteMOP:Debug("ExplorerMode: ToggleDebugFrames called")
    
    -- Toggle WatchFrame overlay debug
    if self.watchFrameOverlay then
        if self.watchFrameOverlay.debugEnabled then
            -- AzeriteMOP:Debug("ExplorerMode: Hiding WatchFrame debug border")
            self.watchFrameOverlay:SetAlpha(0.0)
            if self.watchFrameOverlay.bgTexture then
                self.watchFrameOverlay.bgTexture:SetColorTexture(0, 1, 0, 0.0) -- Green, transparent
            end
            self.watchFrameOverlay.debugEnabled = false
        else
            -- AzeriteMOP:Debug("ExplorerMode: Showing WatchFrame debug border")
            self.watchFrameOverlay:SetAlpha(0.3) -- Make it slightly visible
            if self.watchFrameOverlay.bgTexture then
                self.watchFrameOverlay.bgTexture:SetColorTexture(0, 1, 0, 0.3) -- Green, semi-transparent
            end
            self.watchFrameOverlay.debugEnabled = true
        end
    end
    
    -- Toggle MicroMenu overlay debug
    if self.microMenuOverlay then
        if self.microMenuOverlay.debugEnabled then
            -- AzeriteMOP:Debug("ExplorerMode: Hiding MicroMenu debug border")
            self.microMenuOverlay:SetAlpha(0.0)
            if self.microMenuOverlay.bgTexture then
                self.microMenuOverlay.bgTexture:SetColorTexture(1, 0, 0, 0.0) -- Red, transparent
            end
            self.microMenuOverlay.debugEnabled = false
        else
            -- AzeriteMOP:Debug("ExplorerMode: Showing MicroMenu debug border")
            self.microMenuOverlay:SetAlpha(0.3) -- Make it slightly visible
            if self.microMenuOverlay.bgTexture then
                self.microMenuOverlay.bgTexture:SetColorTexture(1, 0, 0, 0.3) -- Red, semi-transparent
            end
            self.microMenuOverlay.debugEnabled = true
        end
    end
end

function ExplorerMode:ShowChat()
    -- AzeriteMOP:Debug("ExplorerMode: ShowChat called")
    
    -- Show the main chat frame
    local chatFrame1 = _G["ChatFrame1"]
    if chatFrame1 then
        -- AzeriteMOP:Debug("ExplorerMode: Showing ChatFrame1")
        chatFrame1:Show()
        chatFrame1:SetAlpha(1.0)
    end
    
    -- Show the chat edit box
    local chatEditBox = _G["ChatFrame1EditBox"]
    if chatEditBox then
        -- AzeriteMOP:Debug("ExplorerMode: Showing ChatFrame1EditBox")
        chatEditBox:Show()
        chatEditBox:SetAlpha(1.0)
    end
    
    -- Show chat tabs
    local chatTab1 = _G["ChatFrame1Tab"]
    if chatTab1 then
        -- AzeriteMOP:Debug("ExplorerMode: Showing ChatFrame1Tab")
        chatTab1:Show()
        chatTab1:SetAlpha(1.0)
    end
    
    -- Show chat background (but make it transparent)
    local chatBackground = _G["ChatFrame1Background"]
    if chatBackground then
        -- AzeriteMOP:Debug("ExplorerMode: Showing ChatFrame1Background (transparent)")
        chatBackground:Show()
        chatBackground:SetAlpha(0.0) -- Make background transparent
    end
end

function ExplorerMode:OnChatSubmitted()
    -- AzeriteMOP:Debug("ExplorerMode: OnChatSubmitted called")
    
    -- Cancel any existing fade timer
    if self.chatFadeTimer then
        self.chatFadeTimer:Cancel()
    end
    
    local chatFrame1 = _G["ChatFrame1"]
    if chatFrame1 then
        -- AzeriteMOP:Debug("ExplorerMode: Chat submitted - showing for 5 seconds")
        chatFrame1:Show()
        chatFrame1:SetAlpha(1.0)
        
        -- Show chat edit box
        local chatEditBox = _G["ChatFrame1EditBox"]
        if chatEditBox then
            chatEditBox:Show()
            chatEditBox:SetAlpha(1.0)
        end
        
        -- Show chat tabs
        local chatTab1 = _G["ChatFrame1Tab"]
        if chatTab1 then
            chatTab1:Show()
            chatTab1:SetAlpha(1.0)
        end
        
        -- Show chat background (but make it transparent)
        local chatBackground = _G["ChatFrame1Background"]
        if chatBackground then
            chatBackground:Show()
            chatBackground:SetAlpha(0.0) -- Make background transparent
        end
        
        -- Fade out after 5 seconds
        self.chatFadeTimer = C_Timer.NewTimer(5.0, function()
            if self:GetIsActive() then
                -- AzeriteMOP:Debug("ExplorerMode: Starting fade out")
                
                -- Create a smooth fade animation
                local fadeStart = GetTime()
                local fadeDuration = 1.0 -- 1 second fade
                
                local fadeFrame = CreateFrame("Frame")
                fadeFrame:SetScript("OnUpdate", function(_, elapsed)
                    local elapsed = GetTime() - fadeStart
                    local progress = elapsed / fadeDuration
                    
                    if progress >= 1.0 then
                        -- Fade complete, hide all frames
                        -- AzeriteMOP:Debug("ExplorerMode: Fade complete, hiding frames")
                        chatFrame1:Hide()
                        
                        local chatEditBox = _G["ChatFrame1EditBox"]
                        if chatEditBox then chatEditBox:Hide() end
                        
                        local chatTab1 = _G["ChatFrame1Tab"]
                        if chatTab1 then chatTab1:Hide() end
                        
                        local chatBackground = _G["ChatFrame1Background"]
                        if chatBackground then chatBackground:Hide() end
                        
                        fadeFrame:SetScript("OnUpdate", nil)
                        fadeFrame:Hide()
                    else
                        -- Fade in progress
                        local alpha = 1.0 - progress
                        chatFrame1:SetAlpha(alpha)
                        
                        local chatEditBox = _G["ChatFrame1EditBox"]
                        if chatEditBox then chatEditBox:SetAlpha(alpha) end
                        
                        local chatTab1 = _G["ChatFrame1Tab"]
                        if chatTab1 then chatTab1:SetAlpha(alpha) end
                        
                        local chatBackground = _G["ChatFrame1Background"]
                        if chatBackground then chatBackground:SetAlpha(0.0) end -- Keep background transparent
                    end
                end)
            end
            self.chatFadeTimer = nil
        end)
    end
end 
