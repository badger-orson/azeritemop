-- AzeriteMOP Explorer Mode Module
-- Automatically hides UI during exploration for immersive experience

local ADDON_NAME, Addon = ...
local AzeriteMOP = Addon.AzeriteMOP

-- Create ExplorerMode module
AzeriteMOP.ExplorerMode = {}
local ExplorerMode = AzeriteMOP.ExplorerMode

-- Constants
local UPDATE_INTERVAL = 0.2
local DEFAULT_STATIONARY_DELAY = 30.0
local DEFAULT_MOVEMENT_THRESHOLD = 0.00001  -- Much lower threshold for tiny distance values

-- UI Element Groups
local UI_ELEMENTS = {
    chat = {
        "ChatFrame1", "ChatFrame1Tab", "ChatFrame1EditBox", "ChatFrame1ButtonFrame"
    },
    microMenu = {
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton", 
        "CollectionsMicroButton", "MainMenuMicroButton", "HelpMicroButton", 
        "StoreMicroButton", "EJMicroButton", "PVPMicroButton", "LFGMicroButton"
    },
    actionBars = {
        "MainMenuBar", "PetActionBarFrame", "StanceBarFrame",
        "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft"
    },
    quest = {
        "QuestLogFrame", "WatchFrame", "QuestWatchFrame", "ObjectiveTrackerFrame"
    }
}

-- State
ExplorerMode.isActive = false
ExplorerMode.isMoving = false
ExplorerMode.stationaryTimer = 0
ExplorerMode.lastUpdateTime = 0
ExplorerMode.lastPosition = {x = 0, y = 0}
ExplorerMode.movementCounter = 0
ExplorerMode.lastPlayerX = 0
ExplorerMode.lastPlayerY = 0
ExplorerMode.commandActive = false  -- Track when command is being typed
ExplorerMode.questLogManuallyOpened = false  -- Track when quest log is manually opened

-- Initialize database
if AzeriteMOP and not AzeriteMOP.db then
    AzeriteMOP.db = {}
end

if AzeriteMOP and AzeriteMOP.db and not AzeriteMOP.db.explorerMode then
    AzeriteMOP.db.explorerMode = {
        enabled = true,
        hideChatFrame = true,
        stationaryDelay = DEFAULT_STATIONARY_DELAY,
        movementThreshold = DEFAULT_MOVEMENT_THRESHOLD
    }
end

function ExplorerMode:Initialize()
    self:SetupUpdateFrame()
    self:SetupChatHooks()
    self:InitializePosition()
end

function ExplorerMode:SetupUpdateFrame()
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame:SetScript("OnUpdate", function(_, elapsed)
        self:OnUpdate(elapsed)
    end)
    
    -- Register events
    self.updateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.updateFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.updateFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.updateFrame:RegisterEvent("PLAYER_LOGIN")
    self.updateFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    
    self.updateFrame:SetScript("OnEvent", function(_, event, ...)
        self:OnEvent(event, ...)
    end)
end

function ExplorerMode:SetupChatHooks()
    -- Hook chat frames to prevent showing during explorer mode
    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and not chatFrame._originalShow then
            chatFrame._originalShow = chatFrame.Show
            chatFrame.Show = function(self, ...)
                if not ExplorerMode.isActive then
                    return chatFrame._originalShow(self, ...)
                end
            end
        end
        
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        if chatTab and not chatTab._originalShow then
            chatTab._originalShow = chatTab.Show
            chatTab.Show = function(self, ...)
                if not ExplorerMode.isActive then
                    return chatTab._originalShow(self, ...)
                end
            end
        end
    end
    
    -- Hook chat input for command detection
    local chatEditBox = _G["ChatFrame1EditBox"]
    if chatEditBox and not chatEditBox._originalOnTextChanged then
        chatEditBox._originalOnTextChanged = chatEditBox:GetScript("OnTextChanged")
        chatEditBox:SetScript("OnTextChanged", function(self, userInput)
            if ExplorerMode.isActive then
                AzeriteMOP:Debug("Text changed - showing chat")
                ExplorerMode:ShowChatForCommand()
            end
            if chatEditBox._originalOnTextChanged then
                chatEditBox._originalOnTextChanged(self, userInput)
            end
        end)
        
        -- Also hook the Show method to ensure chat is visible when edit box is shown
        if not chatEditBox._originalShow then
            chatEditBox._originalShow = chatEditBox.Show
            chatEditBox.Show = function(self, ...)
                if ExplorerMode.isActive then
                    AzeriteMOP:Debug("Chat edit box shown - showing chat")
                    ExplorerMode:ShowChatForCommand()
                end
                return chatEditBox._originalShow(self, ...)
            end
        end
        
        -- Hook OnEditFocusGained to show chat when edit box gets focus
        if not chatEditBox._originalOnEditFocusGained then
            chatEditBox._originalOnEditFocusGained = chatEditBox:GetScript("OnEditFocusGained")
            chatEditBox:SetScript("OnEditFocusGained", function(self)
                if ExplorerMode.isActive then
                    AzeriteMOP:Debug("Chat edit box gained focus - showing chat")
                    ExplorerMode:ShowChatForCommand()
                end
                if chatEditBox._originalOnEditFocusGained then
                    chatEditBox._originalOnEditFocusGained(self)
                end
            end)
        end
        
        -- Hook the OnEditFocusLost to reset command flag
        if not chatEditBox._originalOnEditFocusLost then
            chatEditBox._originalOnEditFocusLost = chatEditBox:GetScript("OnEditFocusLost")
            chatEditBox:SetScript("OnEditFocusLost", function(self)
                AzeriteMOP:Debug("Chat edit box lost focus - resetting flag")
                ExplorerMode.commandActive = false
                if chatEditBox._originalOnEditFocusLost then
                    chatEditBox._originalOnEditFocusLost(self)
                end
            end)
        end
    end
    
    -- Hook quest log frame to detect manual opening
    self:SetupQuestLogHooks()
end

function ExplorerMode:SetupQuestLogHooks()
    -- Hook QuestLogFrame to detect manual opening
    local questLogFrame = _G["QuestLogFrame"]
    if questLogFrame and not questLogFrame._originalShow then
        questLogFrame._originalShow = questLogFrame.Show
        questLogFrame.Show = function(self, ...)
            if ExplorerMode.isActive then
                AzeriteMOP:Debug("Quest log manually opened - allowing it to stay open")
                ExplorerMode.questLogManuallyOpened = true
                -- Reset the flag after a delay
                C_Timer.After(10.0, function()
                    ExplorerMode.questLogManuallyOpened = false
                    AzeriteMOP:Debug("Quest log manual open timeout - hiding re-enabled")
                end)
            end
            return questLogFrame._originalShow(self, ...)
        end
    end
    
    -- Hook WatchFrame as well
    local watchFrame = _G["WatchFrame"]
    if watchFrame and not watchFrame._originalShow then
        watchFrame._originalShow = watchFrame.Show
        watchFrame.Show = function(self, ...)
            if ExplorerMode.isActive then
                AzeriteMOP:Debug("Watch frame manually opened - allowing it to stay open")
                ExplorerMode.questLogManuallyOpened = true
                -- Reset the flag after a delay
                C_Timer.After(10.0, function()
                    ExplorerMode.questLogManuallyOpened = false
                    AzeriteMOP:Debug("Watch frame manual open timeout - hiding re-enabled")
                end)
            end
            return watchFrame._originalShow(self, ...)
        end
    end
end

function ExplorerMode:InitializePosition()
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local position = C_Map.GetPlayerMapPosition(mapID, "player")
        if position then
            self.lastPosition.x = position.x
            self.lastPosition.y = position.y
            self.lastPlayerX = position.x
            self.lastPlayerY = position.y
        end
    end
end

function ExplorerMode:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        self:InitializePosition()
        self:CheckExplorerMode()
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:EnableExplorerMode()
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:CheckExplorerMode()
    elseif event == "PLAYER_TARGET_CHANGED" then
        if self.isActive then
            self:EnsureFramesVisible()
        end
    end
end

function ExplorerMode:OnUpdate(elapsed)
    if not AzeriteMOP.db.explorerMode.enabled then return end
    
    local currentTime = GetTime()
    if currentTime - self.lastUpdateTime < UPDATE_INTERVAL then return end
    
    -- Combat check - if in combat, keep UI hidden regardless of movement
    if UnitAffectingCombat("player") then
        if not self.isActive then
            AzeriteMOP:Debug("Combat detected, enabling explorer mode")
            self:EnableExplorerMode()
        end
        -- Reset stationary timer while in combat
        self.stationaryTimer = 0
        self.lastUpdateTime = currentTime
        return
    end
    
    -- Not in combat - handle movement detection
    if self.isActive then
        self:EnsureFramesVisible()
        self:EnsureUIHidden()
    end
    
    -- Movement detection - simplified: just check if position changed
    local mapID = C_Map.GetBestMapForUnit("player")
    local position = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    
    if position then
        -- Simple check: has position changed?
        local positionChanged = (position.x ~= self.lastPlayerX) or (position.y ~= self.lastPlayerY)
        
        if positionChanged then
            -- Position changed = player is moving
            if not self.isMoving then
                self.isMoving = true
                self.stationaryTimer = 0
                AzeriteMOP:Debug("Position changed - enabling explorer mode")
                self:EnableExplorerMode()
            end
            -- Ensure frames stay visible while moving
            if self.isMoving and self.isActive then
                self:EnsureFramesVisible()
            end
        else
            -- Position hasn't changed = player is stationary
            if self.isMoving then
                self.isMoving = false
                AzeriteMOP:Debug("Position unchanged - player stopped moving")
            end
            
            -- Only increment stationary timer when not in combat and not moving
            self.stationaryTimer = self.stationaryTimer + UPDATE_INTERVAL
            
            if self.stationaryTimer >= AzeriteMOP.db.explorerMode.stationaryDelay and self.isActive then
                AzeriteMOP:Debug("Stationary delay reached - disabling explorer mode")
                self:DisableExplorerMode()
            end
        end
        
        self.lastPlayerX = position.x
        self.lastPlayerY = position.y
        self.lastPosition.x = position.x
        self.lastPosition.y = position.y
    else
        AzeriteMOP:Debug("Could not get player position, using fallback")
        -- Fallback: assume moving if position unavailable
        if not self.isMoving then
            self.isMoving = true
            self.stationaryTimer = 0
            AzeriteMOP:Debug("Player started moving (fallback), enabling explorer mode")
            self:EnableExplorerMode()
        end
    end
    
    self.lastUpdateTime = currentTime
end

function ExplorerMode:EnableExplorerMode()
    if self.isActive then return end
    
    AzeriteMOP:Debug("Enabling Explorer Mode")
    self.isActive = true
    self:HideUIElements()
    self:EnsureFramesVisible()
    
    C_Timer.After(0.1, function()
        self:EnsureFramesVisible()
    end)
end

function ExplorerMode:DisableExplorerMode()
    if not self.isActive then return end
    
    AzeriteMOP:Debug("Disabling Explorer Mode")
    self.isActive = false
    self:ShowUIElements()
    self:EnsureFramesVisible()
end

function ExplorerMode:HideUIElements()
    AzeriteMOP:Debug("Hiding UI Elements")
    if AzeriteMOP.db.explorerMode.hideChatFrame then
        self:HideChatFrames()
    end
    self:HideMicroMenuAndActionBars()
end

function ExplorerMode:ShowUIElements()
    AzeriteMOP:Debug("Showing UI Elements")
    if AzeriteMOP.db.explorerMode.hideChatFrame then
        self:ShowChatFrames()
    end
    self:ShowMicroMenuAndActionBars()
end

function ExplorerMode:EnsureUIHidden()
    AzeriteMOP:Debug("Ensuring UI Hidden")
    if AzeriteMOP.db.explorerMode.hideChatFrame then
        self:HideChatFrames()
    end
    self:HideMicroMenuAndActionBars()
end

function ExplorerMode:HideChatFrames()
    AzeriteMOP:Debug("Hiding chat frames...")
    
    -- Don't hide chat if a command is active
    if self.commandActive then
        AzeriteMOP:Debug("Command active - not hiding chat frames")
        return
    end
    
    -- Hide main chat frame and related elements
    for _, elementName in ipairs(UI_ELEMENTS.chat) do
        local element = _G[elementName]
        if element then
            element:Hide()
            AzeriteMOP:Debug("  Hidden " .. elementName)
        else
            AzeriteMOP:Debug("  " .. elementName .. " not found")
        end
    end
    
    -- Hide all chat frames
    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame:IsShown() then
            chatFrame:Hide()
            AzeriteMOP:Debug("  Hidden ChatFrame" .. i)
        end
        
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        if chatTab and chatTab:IsShown() then
            chatTab:Hide()
            AzeriteMOP:Debug("  Hidden ChatFrame" .. i .. "Tab")
        end
    end
end

function ExplorerMode:ShowChatFrames()
    AzeriteMOP:Debug("Showing chat frames...")
    -- Show main chat frame and related elements
    for _, elementName in ipairs(UI_ELEMENTS.chat) do
        local element = _G[elementName]
        if element then
            element:Show()
            AzeriteMOP:Debug("  Shown " .. elementName)
        else
            AzeriteMOP:Debug("  " .. elementName .. " not found")
        end
    end
end

function ExplorerMode:HideMicroMenuAndActionBars()
    AzeriteMOP:Debug("Hiding micro menu and action bars...")
    -- Hide micro menu buttons
    for _, buttonName in ipairs(UI_ELEMENTS.microMenu) do
        local button = _G[buttonName]
        if button and button:IsShown() then
            button:Hide()
            AzeriteMOP:Debug("  Hidden " .. buttonName)
        else
            AzeriteMOP:Debug("  " .. buttonName .. " not found or not shown")
        end
    end
    
    -- Hide action bars
    for _, barName in ipairs(UI_ELEMENTS.actionBars) do
        local bar = _G[barName]
        if bar and bar:IsShown() then
            bar:Hide()
            AzeriteMOP:Debug("  Hidden " .. barName)
        else
            AzeriteMOP:Debug("  " .. barName .. " not found or not shown")
        end
    end
    
    -- Hide quest frames
    for _, frameName in ipairs(UI_ELEMENTS.quest) do
        local frame = _G[frameName]
        if frame and frame:IsShown() then
            -- Don't hide quest frames if they were manually opened
            if not self.questLogManuallyOpened then
                frame:Hide()
                AzeriteMOP:Debug("  Hidden " .. frameName)
            else
                AzeriteMOP:Debug("  " .. frameName .. " manually opened - not hiding")
            end
        else
            AzeriteMOP:Debug("  " .. frameName .. " not found or not shown")
        end
    end
end

function ExplorerMode:ShowMicroMenuAndActionBars()
    AzeriteMOP:Debug("Showing micro menu and action bars...")
    -- Show micro menu buttons
    for _, buttonName in ipairs(UI_ELEMENTS.microMenu) do
        local button = _G[buttonName]
        if button then
            button:Show()
            AzeriteMOP:Debug("  Shown " .. buttonName)
        else
            AzeriteMOP:Debug("  " .. buttonName .. " not found")
        end
    end
    
    -- Show action bars
    for _, barName in ipairs(UI_ELEMENTS.actionBars) do
        local bar = _G[barName]
        if bar then
            bar:Show()
            AzeriteMOP:Debug("  Shown " .. barName)
        else
            AzeriteMOP:Debug("  " .. barName .. " not found")
        end
    end
    
    -- Don't show quest frames automatically - let user control them manually
    AzeriteMOP:Debug("  Quest frames not shown automatically - manual control only")
end

function ExplorerMode:EnsureFramesVisible()
    -- PlayerFrame
    if AzeriteMOP.PlayerFrame and AzeriteMOP.PlayerFrame.frame then
        local frame = AzeriteMOP.PlayerFrame.frame
        frame:Show()
        frame:SetParent(UIParent)
        frame:SetAlpha(1.0)
    end
    
    local playerFrame = _G["AzeriteMOPPlayerFrame"]
    if playerFrame then
        playerFrame:Show()
        playerFrame:SetParent(UIParent)
        playerFrame:SetAlpha(1.0)
    end
    
    -- TargetFrame
    if AzeriteMOP.TargetFrame and AzeriteMOP.TargetFrame.frame then
        local frame = AzeriteMOP.TargetFrame.frame
        if UnitExists("target") then
            frame:Show()
            frame:SetParent(UIParent)
            frame:SetAlpha(1.0)
        else
            frame:Hide()
        end
    end
    
    local targetFrame = _G["AzeriteMOPTargetFrame"]
    if targetFrame then
        if UnitExists("target") then
            targetFrame:Show()
            targetFrame:SetParent(UIParent)
            targetFrame:SetAlpha(1.0)
        else
            targetFrame:Hide()
        end
    end
end

function ExplorerMode:ShowChatForCommand()
    AzeriteMOP:Debug("ShowChatForCommand called")
    self.commandActive = true
    
    -- Show all chat frames when user is typing a command
    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame:Show()
            AzeriteMOP:Debug("  Shown ChatFrame" .. i)
        end
        
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        if chatTab then
            chatTab:Show()
            AzeriteMOP:Debug("  Shown ChatFrame" .. i .. "Tab")
        end
    end
    
    -- Also show the main chat elements
    for _, elementName in ipairs(UI_ELEMENTS.chat) do
        local element = _G[elementName]
        if element then
            element:Show()
            AzeriteMOP:Debug("  Shown " .. elementName)
        end
    end
end

function ExplorerMode:CheckExplorerMode()
    if not AzeriteMOP.db.explorerMode.enabled then
        self:DisableExplorerMode()
        return
    end
    
    -- If in combat, always enable explorer mode
    if UnitAffectingCombat("player") then
        AzeriteMOP:Debug("Combat detected in CheckExplorerMode, enabling explorer mode")
        self:EnableExplorerMode()
        return
    end
    
    -- Not in combat - check movement state
    if self.isMoving then
        AzeriteMOP:Debug("Player is moving, enabling explorer mode")
        self:EnableExplorerMode()
    else
        AzeriteMOP:Debug("Player is not moving, checking stationary timer")
        -- Don't disable immediately, let the timer handle it
    end
end

-- Public API
function ExplorerMode:SetEnabled(enabled)
    AzeriteMOP.db.explorerMode.enabled = enabled
    if not enabled then
        self:DisableExplorerMode()
    end
end

function ExplorerMode:IsEnabled()
    return AzeriteMOP.db.explorerMode.enabled
end

function ExplorerMode:IsActive()
    return self.isActive
end

function ExplorerMode:SetStationaryDelay(delay)
    AzeriteMOP.db.explorerMode.stationaryDelay = delay
    if AzeriteMOPDB and AzeriteMOPDB.explorerMode then
        AzeriteMOPDB.explorerMode.stationaryDelay = delay
    end
end

function ExplorerMode:SetMovementThreshold(threshold)
    AzeriteMOP.db.explorerMode.movementThreshold = threshold
end

-- Debug functions
function ExplorerMode:ScanVisibleFrames()
    AzeriteMOP:Debug("Scanning for visible frames...")
    
    -- Common frame names to check
    local frameNames = {
        "WatchFrame", "QuestLogFrame", "QuestWatchFrame", "ObjectiveTrackerFrame",
        "QuestObjectiveTracker", "QuestLogFrame", "QuestFrame", "QuestLogFrame",
        "ObjectiveTrackerFrame", "QuestObjectiveTracker", "QuestLogFrame"
    }
    
    for _, frameName in ipairs(frameNames) do
        local frame = _G[frameName]
        if frame and type(frame) == "table" and frame.IsShown then
            local success, isShown = pcall(function() return frame:IsShown() end)
            if success then
                AzeriteMOP:Debug("  " .. frameName .. " exists and is shown: " .. tostring(isShown))
            else
                AzeriteMOP:Debug("  " .. frameName .. " exists but IsShown failed")
            end
        else
            AzeriteMOP:Debug("  " .. frameName .. " does not exist")
        end
    end
    
    -- Also check for frames with "Quest" or "Objective" in the name
    AzeriteMOP:Debug("Scanning for quest/objective related frames...")
    for name, frame in pairs(_G) do
        if type(frame) == "table" and frame.IsShown and type(frame.IsShown) == "function" then
            local success, isShown = pcall(function() return frame:IsShown() end)
            if success and isShown then
                if string.find(name, "Quest") or string.find(name, "Objective") or string.find(name, "Watch") then
                    AzeriteMOP:Debug("  Found visible frame: " .. name)
                end
            end
        end
    end
end

function ExplorerMode:ForceEnable()
    self.isActive = true
    self.isMoving = true
    self.stationaryTimer = 0
    self:EnableExplorerMode()
end

function ExplorerMode:ForceDisable()
    self.isActive = false
    self.isMoving = false
    self.stationaryTimer = 0
    self:DisableExplorerMode()
end

function ExplorerMode:ResetStationaryDelay()
    self:SetStationaryDelay(DEFAULT_STATIONARY_DELAY)
end

function ExplorerMode:CheckDelayValue()
    AzeriteMOP:Debug("Stationary delay: " .. AzeriteMOP.db.explorerMode.stationaryDelay)
end

function ExplorerMode:ForceResetDatabase()
    AzeriteMOP.db.explorerMode = {
        enabled = true,
        hideChatFrame = true,
        stationaryDelay = DEFAULT_STATIONARY_DELAY,
        movementThreshold = DEFAULT_MOVEMENT_THRESHOLD
    }
    
    if AzeriteMOPDB then
        AzeriteMOPDB.explorerMode = AzeriteMOP.db.explorerMode
    end
end

function ExplorerMode:DebugInfo()
    AzeriteMOP:Debug("Explorer Mode Debug:")
    AzeriteMOP:Debug("  Enabled: " .. tostring(self:IsEnabled()))
    AzeriteMOP:Debug("  Active: " .. tostring(self.isActive))
    AzeriteMOP:Debug("  Moving: " .. tostring(self.isMoving))
    AzeriteMOP:Debug("  Stationary Timer: " .. self.stationaryTimer)
    AzeriteMOP:Debug("  Movement Counter: " .. self.movementCounter)
    AzeriteMOP:Debug("  Combat: " .. tostring(UnitAffectingCombat("player")))
    
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local position = C_Map.GetPlayerMapPosition(mapID, "player")
        if position then
            AzeriteMOP:Debug("  Position: " .. position.x .. ", " .. position.y)
        end
    end
end 