-- AzeriteMOP Explorer Mode Module
-- Simple UI hiding for immersive experience

local ADDON_NAME, Addon = ...
local AzeriteMOP = Addon.AzeriteMOP

-- Create ExplorerMode module
AzeriteMOP.ExplorerMode = {}
local ExplorerMode = AzeriteMOP.ExplorerMode

-- Simple state tracking
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
        elseif msg == "chat" then
            -- Toggle custom chat frame
            if AzeriteMOP.ChatFrame and AzeriteMOP.ChatFrame.Toggle then
                AzeriteMOP.ChatFrame:Toggle()
            else
                print("|cFF4488FF[AzeriteMOP]|r ChatFrame module not available")
            end
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
            print("/explorer chat - Toggle custom chat frame")
            print("/explorer status - Check current status")
            print("/explorer debug - Toggle debug frame borders")
        end
    end
end

function ExplorerMode:HideUI()
    -- AzeriteMOP:Debug("ExplorerMode: HideUI called")
    
    -- Show ChatFrame1 in explorer mode with 60% transparency
    local chatFrame1 = _G["ChatFrame1"]
    if chatFrame1 then
        -- AzeriteMOP:Debug("ExplorerMode: Showing ChatFrame1 in explorer mode with 60% transparency")
        pcall(function() 
            chatFrame1:Show()
            chatFrame1:SetAlpha(0.4) -- 60% transparent immediately
        end)
    else
        -- AzeriteMOP:Debug("ExplorerMode: ChatFrame1 not found")
    end
    
    -- Show default chat input box with 60% transparency
    local chatEditBox = _G["ChatFrame1EditBox"]
    if chatEditBox then
        pcall(function() 
            chatEditBox:Show()
            chatEditBox:SetAlpha(0.4) -- 60% transparent immediately
        end)
    end
    
    -- Show chat frame tab with 60% transparency
    local chatTab = _G["ChatFrame1Tab"]
    if chatTab then
        pcall(function() 
            chatTab:Show()
            chatTab:SetAlpha(0.4) -- 60% transparent immediately
        end)
    end
    
    -- Ensure ChatFrame styling is applied
    if AzeriteMOP.ChatFrame then
        C_Timer.After(0.1, function()
            if AzeriteMOP.ChatFrame.Initialize then
                AzeriteMOP.ChatFrame:Initialize()
            end
        end)
    end
    
    -- Set up ChatFrame1 fade-out system
    self:SetupChatFrameFadeOut()
    
    -- Hide quest frame (WatchFrame) and set up mouse-over functionality
    local watchFrame = _G["WatchFrame"]
    if watchFrame then
        -- AzeriteMOP:Debug("ExplorerMode: Hiding WatchFrame")
        pcall(function() watchFrame:Hide() end)
        
        -- Set up mouse-over functionality for WatchFrame
        pcall(function() self:SetupWatchFrameMouseOver(watchFrame) end)
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
            pcall(function() button:Hide() end)
        else
            -- AzeriteMOP:Debug("ExplorerMode: " .. buttonName .. " not found")
        end
    end
    
    -- Set up mouse-over functionality for MicroMenu
    self:SetupMicroMenuMouseOver()
end

function ExplorerMode:ShowUI()
    -- AzeriteMOP:Debug("ExplorerMode: ShowUI called")
    
    -- Show default chat frame and input box with 60% transparency
    local chatFrame1 = _G["ChatFrame1"]
    if chatFrame1 then
        -- AzeriteMOP:Debug("ExplorerMode: Showing ChatFrame1 with 60% transparency")
        pcall(function() 
            chatFrame1:Show()
            chatFrame1:SetAlpha(0.4) -- 60% transparent immediately
        end)
        
        -- Re-apply chat frame styling after showing
        if AzeriteMOP.ChatFrame then
            C_Timer.After(0.1, function()
                -- Re-initialize chat frame styling
                if AzeriteMOP.ChatFrame.Initialize then
                    AzeriteMOP.ChatFrame:Initialize()
                end
            end)
        end
    else
        -- AzeriteMOP:Debug("ExplorerMode: ChatFrame1 not found")
    end
    
    -- Show default chat input box with 60% transparency
    local chatEditBox = _G["ChatFrame1EditBox"]
    if chatEditBox then
        pcall(function() 
            chatEditBox:Show()
            chatEditBox:SetAlpha(0.4) -- 60% transparent immediately
        end)
    end
    
    -- Show chat frame tab with 60% transparency
    local chatTab = _G["ChatFrame1Tab"]
    if chatTab then
        pcall(function() 
            chatTab:Show()
            chatTab:SetAlpha(0.4) -- 60% transparent immediately
        end)
    end
    
    -- Show quest frame (WatchFrame) and clean up overlay
    local watchFrame = _G["WatchFrame"]
    if watchFrame then
        -- AzeriteMOP:Debug("ExplorerMode: Showing WatchFrame")
        pcall(function() 
            watchFrame:Show()
            watchFrame:SetAlpha(1.0)
        end)
        
            -- Clean up the overlay frame
    if self.watchFrameOverlay then
        -- AzeriteMOP:Debug("ExplorerMode: Cleaning up WatchFrame overlay")
        pcall(function() 
            self.watchFrameOverlay:Hide()
            self.watchFrameOverlay = nil
        end)
    end
    
    -- Clean up chat frame keyboard frame
    if self.chatKeyboardFrame then
        -- AzeriteMOP:Debug("ExplorerMode: Cleaning up ChatFrame keyboard frame")
        pcall(function() 
            self.chatKeyboardFrame:Hide()
            self.chatKeyboardFrame = nil
        end)
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
            pcall(function() 
                button:Show()
                button:SetAlpha(1.0)
            end)
        else
            -- AzeriteMOP:Debug("ExplorerMode: " .. buttonName .. " not found")
        end
    end
    
    -- Clean up the MicroMenu overlay frame
    if self.microMenuOverlay then
        -- AzeriteMOP:Debug("ExplorerMode: Cleaning up MicroMenu overlay")
        pcall(function() 
            self.microMenuOverlay:Hide()
            self.microMenuOverlay = nil
        end)
    end
    
    -- Clean up the ChatFrame overlay frame
    if self.chatFrameOverlay then
        -- AzeriteMOP:Debug("ExplorerMode: Cleaning up ChatFrame overlay")
        pcall(function() 
            self.chatFrameOverlay:Hide()
            self.chatFrameOverlay = nil
        end)
    end
    
    -- Clean up the ChatFrame keyboard frame
    if self.chatKeyboardFrame then
        -- AzeriteMOP:Debug("ExplorerMode: Cleaning up ChatFrame keyboard frame")
        pcall(function() 
            self.chatKeyboardFrame:Hide()
            self.chatKeyboardFrame = nil
        end)
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

function ExplorerMode:SetupChatFrameFadeOut()
    -- AzeriteMOP:Debug("ExplorerMode: Setting up ChatFrame1 fade-out (no mouse over)")
    
    local chatFrame1 = _G["ChatFrame1"]
    if not chatFrame1 then
        -- AzeriteMOP:Debug("ExplorerMode: ChatFrame1 not found for fade setup")
        return
    end
    
    -- Set up edit box transparency hooks
    local chatEditBox = _G["ChatFrame1EditBox"]
    if chatEditBox then
        self:SetupEditBoxTransparency(chatEditBox)
    end
    
    -- Set up keyboard detection for Enter key
    self:SetupChatFrameKeyboard()
    
    -- Initial fade to 60% transparent after a delay
    C_Timer.After(3.0, function()
        if ExplorerMode:GetIsActive() then
            -- AzeriteMOP:Debug("ExplorerMode: Initial ChatFrame1 fade to 60% transparent")
            self:FadeOutChatFrame()
        end
    end)
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
    
    -- ChatFrame no longer has overlay (removed mouse over events)
end

function ExplorerMode:SetupEditBoxTransparency(chatEditBox)
    if not chatEditBox then return end
    
    -- Hook the edit box to maintain 60% transparency even when focused
    if not chatEditBox.azeriteTransparencyHooked then
        chatEditBox:HookScript("OnEditFocusGained", function(self)
            -- AzeriteMOP:Debug("ExplorerMode: Edit box focused - maintaining 60% transparency")
            self:SetAlpha(0.4) -- Keep 60% transparent even when focused
        end)
        
        chatEditBox:HookScript("OnEditFocusLost", function(self)
            -- AzeriteMOP:Debug("ExplorerMode: Edit box unfocused - maintaining 60% transparency")
            self:SetAlpha(0.4) -- Keep 60% transparent even when unfocused
        end)
        
        -- Add OnUpdate hook to continuously enforce transparency
        chatEditBox:HookScript("OnUpdate", function(self)
            if self:GetAlpha() > 0.4 then
                self:SetAlpha(0.4) -- Force 60% transparency
            end
        end)
        
        -- Also hook OnTextChanged to ensure transparency during typing
        chatEditBox:HookScript("OnTextChanged", function(self)
            if self:GetAlpha() > 0.4 then
                self:SetAlpha(0.4) -- Force 60% transparency
            end
        end)
        
        chatEditBox.azeriteTransparencyHooked = true
    end
end 

function ExplorerMode:SetupChatFrameKeyboard()
    -- AzeriteMOP:Debug("ExplorerMode: Setting up ChatFrame keyboard detection")
    
    -- Create a frame to handle keyboard events
    local keyboardFrame = CreateFrame("Frame", "ExplorerModeChatKeyboardFrame", UIParent)
    keyboardFrame:EnableKeyboard(true)
    keyboardFrame:SetPropagateKeyboardInput(true)
    
    keyboardFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ENTER" and ExplorerMode:GetIsActive() then
            -- AzeriteMOP:Debug("ExplorerMode: Enter key pressed - showing ChatFrame1")
            
            -- Cancel any existing fade timer
            if ExplorerMode.chatFrameFadeTimer then
                ExplorerMode.chatFrameFadeTimer:Cancel()
            end
            
            -- Show ChatFrame1 immediately
            ExplorerMode:ShowChatFrame()
        end
    end)
    
    -- Store reference to keyboard frame
    ExplorerMode.chatKeyboardFrame = keyboardFrame
end

function ExplorerMode:ShowChatFrame()
    local chatFrame1 = _G["ChatFrame1"]
    local chatEditBox = _G["ChatFrame1EditBox"]
    local chatTab = _G["ChatFrame1Tab"]
    
    if chatFrame1 then
        chatFrame1:Show()
        chatFrame1:SetAlpha(0.4) -- Always 60% transparent
        chatFrame1:SetFrameStrata("HIGH")
        chatFrame1:SetFrameLevel(1000)
    end
    
    if chatEditBox then
        chatEditBox:Show()
        chatEditBox:SetAlpha(0.4) -- Always 60% transparent
        
        -- Setup transparency hooks
        self:SetupEditBoxTransparency(chatEditBox)
        
        -- Force transparency after a short delay to override any WoW defaults
        C_Timer.After(0.1, function()
            if chatEditBox then
                chatEditBox:SetAlpha(0.4) -- Force 60% transparency
            end
        end)
        
        -- Also force transparency after a longer delay
        C_Timer.After(0.5, function()
            if chatEditBox then
                chatEditBox:SetAlpha(0.4) -- Force 60% transparency
            end
        end)
    end
    
    if chatTab then
        chatTab:Show()
        chatTab:SetAlpha(0.4) -- Always 60% transparent
    end
    
    -- Mark overlay as showing (if it exists)
    if ExplorerMode.chatFrameOverlay then
        ExplorerMode.chatFrameOverlay.isShowing = true
    end
end

function ExplorerMode:FadeOutChatFrame()
    local chatFrame1 = _G["ChatFrame1"]
    local chatEditBox = _G["ChatFrame1EditBox"]
    local chatTab = _G["ChatFrame1Tab"]
    
    if chatFrame1 then
        chatFrame1:SetAlpha(0.4) -- 60% transparent (40% opacity)
    end
    
    if chatEditBox then
        chatEditBox:SetAlpha(0.4) -- 60% transparent
    end
    
    if chatTab then
        chatTab:SetAlpha(0.4) -- 60% transparent
    end
    
    -- Mark overlay as not showing
    if ExplorerMode.chatFrameOverlay then
        ExplorerMode.chatFrameOverlay.isShowing = false
    end
end 
