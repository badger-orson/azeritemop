-- AzeriteMOP Explorer Mode Module
-- Simple UI hiding for immersive experience

local ADDON_NAME, Addon = ...
local AzeriteMOP = Addon.AzeriteMOP

-- Create ExplorerMode module
AzeriteMOP.ExplorerMode = {}
local ExplorerMode = AzeriteMOP.ExplorerMode

-- Simple state tracking
ExplorerMode.isActive = false
ExplorerMode.chatFadeTimer = nil
ExplorerMode.chatActive = false
ExplorerMode.lastFocusTime = 0
ExplorerMode.watchFrameFadeTimer = nil

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
    AzeriteMOP:Debug("ExplorerMode: Initialize called")
    self:SetupSlashCommands()
    self:SetupChatHooks()
end

function ExplorerMode:SetupSlashCommands()
    -- Add simple test commands
    SLASH_EXPLORER_TEST1 = "/explorer"
    SlashCmdList["EXPLORER_TEST"] = function(msg)
        if msg == "hide" then
            AzeriteMOP:Debug("ExplorerMode: Hiding UI")
            self:HideUI()
        elseif msg == "show" then
            AzeriteMOP:Debug("ExplorerMode: Showing UI")
            self:ShowUI()
        elseif msg == "on" then
            AzeriteMOP:Debug("ExplorerMode: Enabling explorer mode")
            self.isActive = true
            self:HideUI()
        elseif msg == "off" then
            AzeriteMOP:Debug("ExplorerMode: Disabling explorer mode")
            self.isActive = false
            self:ShowUI()
        else
            print("ExplorerMode Commands:")
            print("/explorer hide - Hide UI")
            print("/explorer show - Show UI")
            print("/explorer on - Enable explorer mode")
            print("/explorer off - Disable explorer mode")
        end
    end
end

function ExplorerMode:SetupChatHooks()
    AzeriteMOP:Debug("ExplorerMode: Setting up chat hooks")
    
    local chatEditBox = _G["ChatFrame1EditBox"]
    if chatEditBox then
        AzeriteMOP:Debug("ExplorerMode: Found ChatFrame1EditBox")
        
        -- Store original functions
        chatEditBox._originalOnEditFocusGained = chatEditBox:GetScript("OnEditFocusGained")
        chatEditBox._originalOnEditFocusLost = chatEditBox:GetScript("OnEditFocusLost")
        chatEditBox._originalOnChar = chatEditBox:GetScript("OnChar")
        chatEditBox._originalOnKeyDown = chatEditBox:GetScript("OnKeyDown")
        
        -- Hook into focus gained (when chat is opened)
        chatEditBox:SetScript("OnEditFocusGained", function(self)
            local currentTime = GetTime()
            AzeriteMOP:Debug("ExplorerMode: Chat focus gained")
            if ExplorerMode.isActive and not ExplorerMode.chatActive and (currentTime - ExplorerMode.lastFocusTime) > 0.5 then
                ExplorerMode.chatActive = true
                ExplorerMode.lastFocusTime = currentTime
                ExplorerMode:ShowChat()
            end
            if chatEditBox._originalOnEditFocusGained then
                chatEditBox._originalOnEditFocusGained(self)
            end
        end)
        
        -- Hook into key down to detect Enter key
        chatEditBox:SetScript("OnKeyDown", function(self, key)
            if ExplorerMode.isActive and key == "ENTER" then
                local text = self:GetText()
                AzeriteMOP:Debug("ExplorerMode: Enter key pressed with text: " .. (text or "empty"))
                -- Trigger chat submission on any Enter key press
                ExplorerMode:OnChatSubmitted()
            end
            if chatEditBox._originalOnKeyDown then
                chatEditBox._originalOnKeyDown(self, key)
            end
        end)
        
        -- Hook into focus lost (when chat is submitted)
        chatEditBox:SetScript("OnEditFocusLost", function(self)
            AzeriteMOP:Debug("ExplorerMode: Chat focus lost")
            if ExplorerMode.isActive and ExplorerMode.chatActive then
                local text = self:GetText()
                AzeriteMOP:Debug("ExplorerMode: Chat focus lost with text: " .. (text or "empty"))
                -- Always trigger fade on focus lost (whether there's text or not)
                ExplorerMode:OnChatSubmitted()
                ExplorerMode.chatActive = false
            end
            if chatEditBox._originalOnEditFocusLost then
                chatEditBox._originalOnEditFocusLost(self)
            end
        end)
    else
        AzeriteMOP:Debug("ExplorerMode: ChatFrame1EditBox not found")
    end
end

function ExplorerMode:HideUI()
    AzeriteMOP:Debug("ExplorerMode: HideUI called")
    
    -- Hide chat frame
    local chatFrame1 = _G["ChatFrame1"]
    if chatFrame1 then
        AzeriteMOP:Debug("ExplorerMode: Hiding ChatFrame1")
        chatFrame1:Hide()
    else
        AzeriteMOP:Debug("ExplorerMode: ChatFrame1 not found")
    end
    
    -- Hide quest frame (WatchFrame) and set up mouse-over functionality
    local watchFrame = _G["WatchFrame"]
    if watchFrame then
        AzeriteMOP:Debug("ExplorerMode: Hiding WatchFrame")
        watchFrame:Hide()
        
        -- Set up mouse-over functionality for WatchFrame
        self:SetupWatchFrameMouseOver(watchFrame)
    else
        AzeriteMOP:Debug("ExplorerMode: WatchFrame not found")
    end
end

function ExplorerMode:ShowUI()
    AzeriteMOP:Debug("ExplorerMode: ShowUI called")
    
    -- Show chat frame
    local chatFrame1 = _G["ChatFrame1"]
    if chatFrame1 then
        AzeriteMOP:Debug("ExplorerMode: Showing ChatFrame1")
        chatFrame1:Show()
        chatFrame1:SetAlpha(1.0)
    else
        AzeriteMOP:Debug("ExplorerMode: ChatFrame1 not found")
    end
    
    -- Show quest frame (WatchFrame) and clean up overlay
    local watchFrame = _G["WatchFrame"]
    if watchFrame then
        AzeriteMOP:Debug("ExplorerMode: Showing WatchFrame")
        watchFrame:Show()
        watchFrame:SetAlpha(1.0)
        
        -- Clean up the overlay frame
        if self.watchFrameOverlay then
            AzeriteMOP:Debug("ExplorerMode: Cleaning up WatchFrame overlay")
            self.watchFrameOverlay:Hide()
            self.watchFrameOverlay = nil
        end
    else
        AzeriteMOP:Debug("ExplorerMode: WatchFrame not found")
    end
end

function ExplorerMode:SetupWatchFrameMouseOver(watchFrame)
    AzeriteMOP:Debug("ExplorerMode: Setting up WatchFrame mouse-over")
    
    -- Create an invisible overlay frame in the WatchFrame area
    local overlayFrame = CreateFrame("Frame", "ExplorerModeWatchFrameOverlay", UIParent)
    overlayFrame:SetFrameStrata("HIGH")
    overlayFrame:SetFrameLevel(watchFrame:GetFrameLevel() + 1)
    
    -- Position the overlay to match WatchFrame area (right side of screen)
    overlayFrame:SetPoint("TOPLEFT", UIParent, "TOPRIGHT", -200, -100)
    overlayFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -50, 200)
    
    -- Make it invisible but clickable
    overlayFrame:EnableMouse(true)
    
    -- Set up mouse enter (show WatchFrame)
    overlayFrame:SetScript("OnEnter", function(self)
        if ExplorerMode.isActive then
            AzeriteMOP:Debug("ExplorerMode: Mouse over WatchFrame area - showing")
            
            -- Cancel any existing fade timer
            if ExplorerMode.watchFrameFadeTimer then
                ExplorerMode.watchFrameFadeTimer:Cancel()
            end
            
            -- Show WatchFrame immediately
            watchFrame:Show()
            watchFrame:SetAlpha(1.0)
        end
    end)
    
    -- Set up mouse leave (fade out WatchFrame)
    overlayFrame:SetScript("OnLeave", function(self)
        if ExplorerMode.isActive then
            AzeriteMOP:Debug("ExplorerMode: Mouse left WatchFrame area - fading out")
            
            -- Cancel any existing fade timer
            if ExplorerMode.watchFrameFadeTimer then
                ExplorerMode.watchFrameFadeTimer:Cancel()
            end
            
            -- Fade out after 2 seconds
            ExplorerMode.watchFrameFadeTimer = C_Timer.NewTimer(2.0, function()
                if ExplorerMode.isActive then
                    AzeriteMOP:Debug("ExplorerMode: Fading out WatchFrame")
                    
                    -- Create a smooth fade animation
                    local fadeStart = GetTime()
                    local fadeDuration = 1.0 -- 1 second fade
                    
                    local fadeFrame = CreateFrame("Frame")
                    fadeFrame:SetScript("OnUpdate", function(_, elapsed)
                        local elapsed = GetTime() - fadeStart
                        local progress = elapsed / fadeDuration
                        
                        if progress >= 1.0 then
                            -- Fade complete, hide WatchFrame
                            AzeriteMOP:Debug("ExplorerMode: WatchFrame fade complete, hiding")
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

function ExplorerMode:ShowChat()
    AzeriteMOP:Debug("ExplorerMode: ShowChat called")
    
    -- Show the main chat frame
    local chatFrame1 = _G["ChatFrame1"]
    if chatFrame1 then
        AzeriteMOP:Debug("ExplorerMode: Showing ChatFrame1")
        chatFrame1:Show()
        chatFrame1:SetAlpha(1.0)
    end
    
    -- Show the chat edit box
    local chatEditBox = _G["ChatFrame1EditBox"]
    if chatEditBox then
        AzeriteMOP:Debug("ExplorerMode: Showing ChatFrame1EditBox")
        chatEditBox:Show()
        chatEditBox:SetAlpha(1.0)
    end
    
    -- Show chat tabs
    local chatTab1 = _G["ChatFrame1Tab"]
    if chatTab1 then
        AzeriteMOP:Debug("ExplorerMode: Showing ChatFrame1Tab")
        chatTab1:Show()
        chatTab1:SetAlpha(1.0)
    end
    
    -- Show chat background (but make it transparent)
    local chatBackground = _G["ChatFrame1Background"]
    if chatBackground then
        AzeriteMOP:Debug("ExplorerMode: Showing ChatFrame1Background (transparent)")
        chatBackground:Show()
        chatBackground:SetAlpha(0.0) -- Make background transparent
    end
end

function ExplorerMode:OnChatSubmitted()
    AzeriteMOP:Debug("ExplorerMode: OnChatSubmitted called")
    
    -- Cancel any existing fade timer
    if self.chatFadeTimer then
        self.chatFadeTimer:Cancel()
    end
    
    local chatFrame1 = _G["ChatFrame1"]
    if chatFrame1 then
        AzeriteMOP:Debug("ExplorerMode: Chat submitted - showing for 5 seconds")
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
            if self.isActive then
                AzeriteMOP:Debug("ExplorerMode: Starting fade out")
                
                -- Create a smooth fade animation
                local fadeStart = GetTime()
                local fadeDuration = 1.0 -- 1 second fade
                
                local fadeFrame = CreateFrame("Frame")
                fadeFrame:SetScript("OnUpdate", function(_, elapsed)
                    local elapsed = GetTime() - fadeStart
                    local progress = elapsed / fadeDuration
                    
                    if progress >= 1.0 then
                        -- Fade complete, hide all frames
                        AzeriteMOP:Debug("ExplorerMode: Fade complete, hiding frames")
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
