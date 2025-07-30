-- AzeriteMOP Explorer Mode Module
-- Automatically hides chat during exploration for immersive experience

local ADDON_NAME, Addon = ...
local AzeriteMOP = Addon.AzeriteMOP

-- Create ExplorerMode module
AzeriteMOP.ExplorerMode = {}
local ExplorerMode = AzeriteMOP.ExplorerMode

-- Constants
local MOVEMENT_THRESHOLD = 0.0001 -- Very small threshold for walking
local STATIONARY_DELAY = 2.0 -- Seconds to wait before showing UI when stationary
local UPDATE_INTERVAL = 0.2 -- How often to check for movement

-- State variables
ExplorerMode.isActive = false
ExplorerMode.isMoving = false
ExplorerMode.lastPosition = {x = 0, y = 0}
ExplorerMode.stationaryTimer = 0

-- Ensure database exists immediately when module loads
if AzeriteMOP then
    if not AzeriteMOP.db then
        AzeriteMOP.db = {}
    end
    if not AzeriteMOP.db.explorerMode then
        AzeriteMOP.db.explorerMode = {
            enabled = true,
            hideChatFrame = true,
            stationaryDelay = 2.0,
            movementThreshold = 0.0001
        }
    end
    -- AzeriteMOP:Debug("ExplorerMode module: Database initialized")
end

function ExplorerMode:Initialize()
    -- AzeriteMOP:Debug("Initializing Explorer Mode...")
    
    -- Ensure database is available
    if not AzeriteMOP.db then
        -- AzeriteMOP:Debug("Initialize: Creating AzeriteMOP.db")
        AzeriteMOP.db = {}
    end
    
    if not AzeriteMOP.db.explorerMode then
        -- AzeriteMOP:Debug("Initialize: Creating explorerMode in database")
        AzeriteMOP.db.explorerMode = {
            enabled = true,
            hideChatFrame = true,
            stationaryDelay = 2.0,
            movementThreshold = 0.0001
        }
    end
    
    -- Initialize position tracking
    self:InitializePositionTracking()
    
    -- Set up movement detection
    self:SetupMovementDetection()
    
    -- Register events
    self:RegisterEvents()
    
    -- Set up chat frame hooks to prevent them from being shown
    self:SetupChatFrameHooks()
    
    -- AzeriteMOP:Debug("Explorer Mode initialized!")
end

function ExplorerMode:InitializePositionTracking()
    -- Get initial player position using GetPlayerMapPosition
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local position = C_Map.GetPlayerMapPosition(mapID, "player")
        if position then
            self.lastPosition.x = position.x
            self.lastPosition.y = position.y
            -- AzeriteMOP:Debug("ExplorerMode: Initial position set to " .. position.x .. ", " .. position.y)
        else
            -- AzeriteMOP:Debug("ExplorerMode: Could not get initial position")
        end
    else
        -- AzeriteMOP:Debug("ExplorerMode: Could not get map ID")
    end
    
    -- Fallback: Initialize with default values if position tracking fails
    if not self.lastPosition.x or not self.lastPosition.y then
        self.lastPosition.x = 0
        self.lastPosition.y = 0
        -- AzeriteMOP:Debug("ExplorerMode: Using fallback position values")
    end
end

function ExplorerMode:SetupMovementDetection()
    -- Create update frame for movement detection
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame:SetScript("OnUpdate", function(frame, elapsed)
        self:OnUpdate(elapsed)
    end)
end

function ExplorerMode:RegisterEvents()
    -- Register events for combat and other state changes
    self.updateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.updateFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Combat start
    self.updateFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Combat end
    self.updateFrame:RegisterEvent("PLAYER_LOGIN")
    self.updateFrame:RegisterEvent("PLAYER_TARGET_CHANGED") -- Target changed
    
    self.updateFrame:SetScript("OnEvent", function(frame, event, ...)
        ExplorerMode:OnEvent(event, ...)
    end)
end

function ExplorerMode:SetupChatFrameHooks()
    -- Hook into chat frames to prevent them from being shown while explorer mode is active
    local chatFrames = {"ChatFrame1", "ChatFrame1Tab", "ChatFrame1EditBox", "ChatFrame1ButtonFrame"}
    
    for _, frameName in ipairs(chatFrames) do
        local frame = _G[frameName]
        if frame then
            -- Store original Show method
            if not frame._originalShow then
                frame._originalShow = frame.Show
            end
            
            -- Override Show method
            frame.Show = function(self, ...)
                if ExplorerMode.isActive then
                    -- Don't show if explorer mode is active
                    return
                else
                    -- Call original Show method
                    return frame._originalShow(self, ...)
                end
            end
        end
    end
    
    -- Also hook into other chat frames
    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and not chatFrame._originalShow then
            chatFrame._originalShow = chatFrame.Show
            chatFrame.Show = function(self, ...)
                if ExplorerMode.isActive then
                    return
                else
                    return chatFrame._originalShow(self, ...)
                end
            end
        end
        
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        if chatTab and not chatTab._originalShow then
            chatTab._originalShow = chatTab.Show
            chatTab.Show = function(self, ...)
                if ExplorerMode.isActive then
                    return
                else
                    return chatTab._originalShow(self, ...)
                end
            end
        end
    end
end

function ExplorerMode:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        self:InitializePositionTracking()
        self:CheckExplorerMode()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Combat started, disable explorer mode
        -- AzeriteMOP:Debug("ExplorerMode: Combat started, disabling explorer mode")
        self:DisableExplorerMode()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended, check if we should enable explorer mode
        -- AzeriteMOP:Debug("ExplorerMode: Combat ended, checking explorer mode")
        self:CheckExplorerMode()
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- Target changed, ensure TargetFrame visibility is correct
        if self.isActive then
            self:EnsureFramesVisible()
        end
    end
end

function ExplorerMode:OnUpdate(elapsed)
    -- Only update if explorer mode is enabled
    if not AzeriteMOP.db.explorerMode.enabled then
        return
    end
    
    -- Check if player is in combat
    if UnitAffectingCombat("player") then
        if self.isActive then
            -- AzeriteMOP:Debug("ExplorerMode: Combat detected, disabling explorer mode")
            self:DisableExplorerMode()
        end
        return
    end
    
    -- Use a much simpler movement detection
    if not self.lastUpdateTime then
        self.lastUpdateTime = GetTime()
        self.lastPlayerX = 0
        self.lastPlayerY = 0
        self.movementCounter = 0
    end
    
    local currentTime = GetTime()
    local timeDiff = currentTime - self.lastUpdateTime
    
    -- Check movement every 0.2 seconds (more frequent)
    if timeDiff >= 0.2 then
        -- Ensure frames are visible if explorer mode is active
        if self.isActive then
            self:EnsureFramesVisible()
            -- Also ensure chat frames stay hidden
            self:EnsureChatFramesHidden()
        end
        -- Try to get player position
        local mapID = C_Map.GetBestMapForUnit("player")
        local position = nil
        
        if mapID then
            position = C_Map.GetPlayerMapPosition(mapID, "player")
        end
        
        if position then
            -- Calculate movement distance
            local dx = position.x - self.lastPlayerX
            local dy = position.y - self.lastPlayerY
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- Use a much lower threshold for normal walking
            local threshold = 0.0001 -- Extremely small threshold for walking
            local isMoving = distance > threshold
            
            -- AzeriteMOP:Debug("ExplorerMode: Position " .. position.x .. ", " .. position.y .. " | Distance: " .. distance .. " | Moving: " .. tostring(isMoving))
            
            if isMoving then
                self.movementCounter = self.movementCounter + 1
                if self.movementCounter >= 1 then -- Only need 1 detection for walking
                    if not self.isMoving then
                        self.isMoving = true
                        self.stationaryTimer = 0
                        -- AzeriteMOP:Debug("ExplorerMode: Player started moving, enabling explorer mode")
                        self:EnableExplorerMode()
                        -- Ensure frames are visible when starting to move
                        self:EnsureFramesVisible()
                    end
                end
                -- Ensure frames stay visible while moving
                if self.isMoving and self.isActive then
                    self:EnsureFramesVisible()
                end
            else
                self.movementCounter = 0
                if self.isMoving then
                    self.isMoving = false
                    -- AzeriteMOP:Debug("ExplorerMode: Player stopped moving")
                end
                
                -- Increment stationary timer
                self.stationaryTimer = self.stationaryTimer + timeDiff
                
                -- Check if we should disable explorer mode
                local delay = AzeriteMOP.db.explorerMode.stationaryDelay
                if self.stationaryTimer >= delay and self.isActive then
                    -- AzeriteMOP:Debug("ExplorerMode: Stationary delay reached, disabling explorer mode")
                    self:DisableExplorerMode()
                end
            end
            
            -- Update last position
            self.lastPlayerX = position.x
            self.lastPlayerY = position.y
        else
            -- Fallback: Use a time-based movement detection
            -- AzeriteMOP:Debug("ExplorerMode: Could not get position, using fallback detection")
            
            -- Assume player is moving if we can't get position
            if not self.isMoving then
                self.isMoving = true
                self.stationaryTimer = 0
                -- AzeriteMOP:Debug("ExplorerMode: Player started moving (fallback), enabling explorer mode")
                self:EnableExplorerMode()
            end
        end
        
        self.lastUpdateTime = currentTime
    end
end

function ExplorerMode:EnableExplorerMode()
    if self.isActive then
        return
    end
    
    -- AzeriteMOP:Debug("Enabling Explorer Mode - Hiding UI elements")
    self.isActive = true
    
    -- Hide chat frames
    if AzeriteMOP.db.explorerMode.hideChatFrame then
        self:HideChatFrames()
    end
    
    -- Hide micro menu and action bars
    self:HideMicroMenuAndActionBars()
    
    -- Ensure PlayerFrame and TargetFrame stay visible
    self:EnsureFramesVisible()
    
    -- Force a small delay to ensure frames are shown after UI is hidden
    C_Timer.After(0.1, function()
        self:EnsureFramesVisible()
    end)
end

function ExplorerMode:DisableExplorerMode()
    if not self.isActive then
        return
    end
    
    -- AzeriteMOP:Debug("Disabling Explorer Mode - Showing UI elements")
    self.isActive = false
    
    -- Show chat frames
    if AzeriteMOP.db.explorerMode.hideChatFrame then
        self:ShowChatFrames()
    end
    
    -- Show micro menu and action bars
    self:ShowMicroMenuAndActionBars()
    
    -- Ensure PlayerFrame and TargetFrame stay visible
    self:EnsureFramesVisible()
end

-- Function to hide only chat frames
function ExplorerMode:HideChatFrames()
    -- AzeriteMOP:Debug("Hiding chat frames...")
    
    -- Hide main chat frame and related elements - be more specific
    local chatElements = {
        "ChatFrame1", "ChatFrame1Tab", "ChatFrame1EditBox", "ChatFrame1ButtonFrame"
    }
    for _, elementName in ipairs(chatElements) do
        local element = _G[elementName]
        if element then
            element:Hide()
            -- AzeriteMOP:Debug("Hidden " .. elementName)
        end
    end
    
    -- Don't hide the parent container as it might contain other UI elements
    -- Instead, just hide the specific chat elements
    
    -- Also hide any other visible chat frames
    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame:IsShown() then
            chatFrame:Hide()
            -- AzeriteMOP:Debug("Hidden visible ChatFrame" .. i)
        end
        
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        if chatTab and chatTab:IsShown() then
            chatTab:Hide()
            -- AzeriteMOP:Debug("Hidden visible ChatFrame" .. i .. "Tab")
        end
    end
end

-- Function to hide micro menu and action bars
function ExplorerMode:HideMicroMenuAndActionBars()
    -- AzeriteMOP:Debug("Hiding micro menu and action bars...")
    
    -- Hide micro menu buttons (Character, Spellbook, Talents, etc.)
    local microMenuButtons = {
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton", 
        "CollectionsMicroButton", "MainMenuMicroButton", 
        "HelpMicroButton", "StoreMicroButton", "EJMicroButton",
        "PVPMicroButton", "GroupFinderMicroButton"
    }
    
    for _, buttonName in ipairs(microMenuButtons) do
        local button = _G[buttonName]
        if button and button:IsShown() then
            button:Hide()
            -- AzeriteMOP:Debug("Hidden " .. buttonName)
        end
    end
    
    -- Hide micro menu bar container
    local microMenuBar = _G["MainMenuBar"]
    if microMenuBar and microMenuBar:IsShown() then
        microMenuBar:Hide()
        -- AzeriteMOP:Debug("Hidden MainMenuBar")
    end
    
    -- Hide action bars (ActionBar1, ActionBar2, etc.)
    for i = 1, 6 do
        local actionBar = _G["ActionBar" .. i]
        if actionBar and actionBar:IsShown() then
            actionBar:Hide()
            -- AzeriteMOP:Debug("Hidden ActionBar" .. i)
        end
        
        -- Also try MultiBar frames
        local multiBar = _G["MultiBar" .. i]
        if multiBar and multiBar:IsShown() then
            multiBar:Hide()
            -- AzeriteMOP:Debug("Hidden MultiBar" .. i)
        end
    end
    
    -- Hide specific MoP action bar elements
    local mopActionBars = {
        "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
        "ActionBar1", "ActionBar2", "ActionBar3", "ActionBar4"
    }
    
    for _, barName in ipairs(mopActionBars) do
        local bar = _G[barName]
        if bar and bar:IsShown() then
            bar:Hide()
            -- AzeriteMOP:Debug("Hidden " .. barName)
        end
    end
    
    -- Hide pet action bar
    local petActionBar = _G["PetActionBarFrame"]
    if petActionBar and petActionBar:IsShown() then
        petActionBar:Hide()
        -- AzeriteMOP:Debug("Hidden PetActionBarFrame")
    end
    
    -- Hide stance bar
    local stanceBar = _G["StanceBarFrame"]
    if stanceBar and stanceBar:IsShown() then
        stanceBar:Hide()
        -- AzeriteMOP:Debug("Hidden StanceBarFrame")
    end
    
    -- Hide bonus action bar
    local bonusActionBar = _G["BonusActionBarFrame"]
    if bonusActionBar and bonusActionBar:IsShown() then
        bonusActionBar:Hide()
        -- AzeriteMOP:Debug("Hidden BonusActionBarFrame")
    end
    
    -- Hide objective tracker frame (try multiple possible names for MoP)
    local objectiveTracker = _G["ObjectiveTrackerFrame"] or _G["WatchFrame"] or _G["QuestWatchFrame"]
    if objectiveTracker and objectiveTracker:IsShown() then
        objectiveTracker:Hide()
        -- AzeriteMOP:Debug("Hidden objective tracker frame")
    end
    
    -- Also try hiding individual quest watch elements
    local watchFrame = _G["WatchFrame"]
    if watchFrame and watchFrame:IsShown() then
        watchFrame:Hide()
        -- AzeriteMOP:Debug("Hidden WatchFrame")
    end
    
    local questWatchFrame = _G["QuestWatchFrame"]
    if questWatchFrame and questWatchFrame:IsShown() then
        questWatchFrame:Hide()
        -- AzeriteMOP:Debug("Hidden QuestWatchFrame")
    end
end

-- Function to show only chat frames
function ExplorerMode:ShowChatFrames()
    -- AzeriteMOP:Debug("Showing chat frames...")
    
    -- Show main chat frame and related elements
    local chatElements = {
        "ChatFrame1", "ChatFrame1Tab", "ChatFrame1EditBox", "ChatFrame1ButtonFrame"
    }
    for _, elementName in ipairs(chatElements) do
        local element = _G[elementName]
        if element then
            element:Show()
            -- AzeriteMOP:Debug("Shown " .. elementName)
        end
    end
    
    -- Don't show the parent container as we didn't hide it
    -- This prevents interfering with other UI elements
end

-- Function to show micro menu and action bars
function ExplorerMode:ShowMicroMenuAndActionBars()
    -- AzeriteMOP:Debug("Showing micro menu and action bars...")
    
    -- Show micro menu buttons (Character, Spellbook, Talents, etc.)
    local microMenuButtons = {
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton", 
        "CollectionsMicroButton", "MainMenuMicroButton", 
        "HelpMicroButton", "StoreMicroButton", "EJMicroButton",
        "PVPMicroButton", "GroupFinderMicroButton"
    }
    
    for _, buttonName in ipairs(microMenuButtons) do
        local button = _G[buttonName]
        if button then
            button:Show()
            -- AzeriteMOP:Debug("Shown " .. buttonName)
        end
    end
    
    -- Show micro menu bar container
    local microMenuBar = _G["MainMenuBar"]
    if microMenuBar then
        microMenuBar:Show()
        -- AzeriteMOP:Debug("Shown MainMenuBar")
    end
    
    -- Show action bars (ActionBar1, ActionBar2, etc.)
    for i = 1, 6 do
        local actionBar = _G["ActionBar" .. i]
        if actionBar then
            actionBar:Show()
            -- AzeriteMOP:Debug("Shown ActionBar" .. i)
        end
        
        -- Also try MultiBar frames
        local multiBar = _G["MultiBar" .. i]
        if multiBar then
            multiBar:Show()
            -- AzeriteMOP:Debug("Shown MultiBar" .. i)
        end
    end
    
    -- Show specific MoP action bar elements
    local mopActionBars = {
        "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
        "ActionBar1", "ActionBar2", "ActionBar3", "ActionBar4"
    }
    
    for _, barName in ipairs(mopActionBars) do
        local bar = _G[barName]
        if bar then
            bar:Show()
            -- AzeriteMOP:Debug("Shown " .. barName)
        end
    end
    
    -- Show pet action bar
    local petActionBar = _G["PetActionBarFrame"]
    if petActionBar then
        petActionBar:Show()
        -- AzeriteMOP:Debug("Shown PetActionBarFrame")
    end
    
    -- Show stance bar
    local stanceBar = _G["StanceBarFrame"]
    if stanceBar then
        stanceBar:Show()
        -- AzeriteMOP:Debug("Shown StanceBarFrame")
    end
    
    -- Show bonus action bar
    local bonusActionBar = _G["BonusActionBarFrame"]
    if bonusActionBar then
        bonusActionBar:Show()
        -- AzeriteMOP:Debug("Shown BonusActionBarFrame")
    end
    
    -- Show objective tracker frame (try multiple possible names for MoP)
    local objectiveTracker = _G["ObjectiveTrackerFrame"] or _G["WatchFrame"] or _G["QuestWatchFrame"]
    if objectiveTracker then
        objectiveTracker:Show()
        -- AzeriteMOP:Debug("Shown objective tracker frame")
    end
    
    -- Also try showing individual quest watch elements
    local watchFrame = _G["WatchFrame"]
    if watchFrame then
        watchFrame:Show()
        -- AzeriteMOP:Debug("Shown WatchFrame")
    end
    
    local questWatchFrame = _G["QuestWatchFrame"]
    if questWatchFrame then
        questWatchFrame:Show()
        -- AzeriteMOP:Debug("Shown QuestWatchFrame")
    end
end

-- Function to ensure chat frames stay hidden
function ExplorerMode:EnsureChatFramesHidden()
    -- AzeriteMOP:Debug("Ensuring chat frames stay hidden...")
    
    -- Hide main chat frame and related elements - be more specific
    local chatElements = {
        "ChatFrame1", "ChatFrame1Tab", "ChatFrame1EditBox", "ChatFrame1ButtonFrame"
    }
    for _, elementName in ipairs(chatElements) do
        local element = _G[elementName]
        if element and element:IsShown() then
            element:Hide()
            -- AzeriteMOP:Debug("Re-hidden " .. elementName)
        end
    end
    
    -- Also hide any other visible chat frames
    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame:IsShown() then
            chatFrame:Hide()
            -- AzeriteMOP:Debug("Re-hidden visible ChatFrame" .. i)
        end
        
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        if chatTab and chatTab:IsShown() then
            chatTab:Hide()
            -- AzeriteMOP:Debug("Re-hidden visible ChatFrame" .. i .. "Tab")
        end
    end
    
    -- Also ensure micro menu and action bars stay hidden
    self:EnsureMicroMenuAndActionBarsHidden()
end

-- Function to ensure micro menu and action bars stay hidden
function ExplorerMode:EnsureMicroMenuAndActionBarsHidden()
    -- AzeriteMOP:Debug("Ensuring micro menu and action bars stay hidden...")
    
    -- Hide micro menu buttons (Character, Spellbook, Talents, etc.)
    local microMenuButtons = {
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton", 
        "CollectionsMicroButton", "MainMenuMicroButton", 
        "HelpMicroButton", "StoreMicroButton", "EJMicroButton",
        "PVPMicroButton", "GroupFinderMicroButton"
    }
    
    for _, buttonName in ipairs(microMenuButtons) do
        local button = _G[buttonName]
        if button and button:IsShown() then
            button:Hide()
            -- AzeriteMOP:Debug("Re-hidden " .. buttonName)
        end
    end
    
    -- Hide micro menu bar container
    local microMenuBar = _G["MainMenuBar"]
    if microMenuBar and microMenuBar:IsShown() then
        microMenuBar:Hide()
        -- AzeriteMOP:Debug("Re-hidden MainMenuBar")
    end
    
    -- Hide action bars (ActionBar1, ActionBar2, etc.)
    for i = 1, 6 do
        local actionBar = _G["ActionBar" .. i]
        if actionBar and actionBar:IsShown() then
            actionBar:Hide()
            -- AzeriteMOP:Debug("Re-hidden ActionBar" .. i)
        end
        
        -- Also try MultiBar frames
        local multiBar = _G["MultiBar" .. i]
        if multiBar and multiBar:IsShown() then
            multiBar:Hide()
            -- AzeriteMOP:Debug("Re-hidden MultiBar" .. i)
        end
    end
    
    -- Hide specific MoP action bar elements
    local mopActionBars = {
        "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
        "ActionBar1", "ActionBar2", "ActionBar3", "ActionBar4"
    }
    
    for _, barName in ipairs(mopActionBars) do
        local bar = _G[barName]
        if bar and bar:IsShown() then
            bar:Hide()
            -- AzeriteMOP:Debug("Re-hidden " .. barName)
        end
    end
    
    -- Hide pet action bar
    local petActionBar = _G["PetActionBarFrame"]
    if petActionBar and petActionBar:IsShown() then
        petActionBar:Hide()
        -- AzeriteMOP:Debug("Re-hidden PetActionBarFrame")
    end
    
    -- Hide stance bar
    local stanceBar = _G["StanceBarFrame"]
    if stanceBar and stanceBar:IsShown() then
        stanceBar:Hide()
        -- AzeriteMOP:Debug("Re-hidden StanceBarFrame")
    end
    
    -- Hide bonus action bar
    local bonusActionBar = _G["BonusActionBarFrame"]
    if bonusActionBar and bonusActionBar:IsShown() then
        bonusActionBar:Hide()
        -- AzeriteMOP:Debug("Re-hidden BonusActionBarFrame")
    end
    
    -- Hide objective tracker frame (try multiple possible names for MoP)
    local objectiveTracker = _G["ObjectiveTrackerFrame"] or _G["WatchFrame"] or _G["QuestWatchFrame"]
    if objectiveTracker and objectiveTracker:IsShown() then
        objectiveTracker:Hide()
        -- AzeriteMOP:Debug("Re-hidden objective tracker frame")
    end
    
    -- Also try hiding individual quest watch elements
    local watchFrame = _G["WatchFrame"]
    if watchFrame and watchFrame:IsShown() then
        watchFrame:Hide()
        -- AzeriteMOP:Debug("Re-hidden WatchFrame")
    end
    
    local questWatchFrame = _G["QuestWatchFrame"]
    if questWatchFrame and questWatchFrame:IsShown() then
        questWatchFrame:Hide()
        -- AzeriteMOP:Debug("Re-hidden QuestWatchFrame")
    end
end

-- Function to ensure PlayerFrame and TargetFrame stay visible
function ExplorerMode:EnsureFramesVisible()
    -- AzeriteMOP:Debug("EnsureFramesVisible called")
    
    -- Ensure PlayerFrame is visible - try multiple access methods
    if AzeriteMOP and AzeriteMOP.PlayerFrame and AzeriteMOP.PlayerFrame.frame then
        local frame = AzeriteMOP.PlayerFrame.frame
        frame:Show()
        frame:SetParent(UIParent) -- Ensure it's parented to UIParent
        frame:SetShown(true) -- Force visibility
        frame:SetAlpha(1.0) -- Ensure full opacity
        -- AzeriteMOP:Debug("Ensured PlayerFrame is visible")
    end
    
    -- Also try to show frame by name as backup
    local playerFrame = _G["AzeriteMOPPlayerFrame"]
    if playerFrame then
        playerFrame:Show()
        playerFrame:SetParent(UIParent) -- Ensure it's parented to UIParent
        playerFrame:SetShown(true) -- Force visibility
        playerFrame:SetAlpha(1.0) -- Ensure full opacity
        -- AzeriteMOP:Debug("Showed PlayerFrame by name")
    end
    
    -- Only show TargetFrame if there's a target selected
    if AzeriteMOP and AzeriteMOP.TargetFrame and AzeriteMOP.TargetFrame.frame then
        local frame = AzeriteMOP.TargetFrame.frame
        if UnitExists("target") then
            frame:Show()
            frame:SetParent(UIParent) -- Ensure it's parented to UIParent
            frame:SetShown(true) -- Force visibility
            frame:SetAlpha(1.0) -- Ensure full opacity
            -- AzeriteMOP:Debug("Ensured TargetFrame is visible (target exists)")
        else
            frame:Hide()
            -- AzeriteMOP:Debug("Hidden TargetFrame (no target selected)")
        end
    end
    
    -- Also try to show target frame by name as backup
    local targetFrame = _G["AzeriteMOPTargetFrame"]
    if targetFrame then
        if UnitExists("target") then
            targetFrame:Show()
            targetFrame:SetParent(UIParent) -- Ensure it's parented to UIParent
            targetFrame:SetShown(true) -- Force visibility
            targetFrame:SetAlpha(1.0) -- Ensure full opacity
            -- AzeriteMOP:Debug("Showed TargetFrame by name (target exists)")
        else
            targetFrame:Hide()
            -- AzeriteMOP:Debug("Hidden TargetFrame by name (no target)")
        end
    end
    
    -- Also ensure any child elements of the frames are visible
    if AzeriteMOP and AzeriteMOP.PlayerFrame and AzeriteMOP.PlayerFrame.frame then
        local frame = AzeriteMOP.PlayerFrame.frame
        for i = 1, frame:GetNumChildren() do
            local child = select(i, frame:GetChildren())
            if child and child.Show then
                child:Show()
            end
        end
    end
    
    if AzeriteMOP and AzeriteMOP.TargetFrame and AzeriteMOP.TargetFrame.frame then
        local frame = AzeriteMOP.TargetFrame.frame
        if UnitExists("target") then
            for i = 1, frame:GetNumChildren() do
                local child = select(i, frame:GetChildren())
                if child and child.Show then
                    child:Show()
                end
            end
        end
    end
end

function ExplorerMode:CheckExplorerMode()
    -- Check if explorer mode should be active based on current conditions
    if not AzeriteMOP.db.explorerMode.enabled then
        self:DisableExplorerMode()
        return
    end
    
    if UnitAffectingCombat("player") then
        self:DisableExplorerMode()
        return
    end
    
    -- If moving, enable explorer mode
    if self.isMoving then
        self:EnableExplorerMode()
    end
end

-- Public API functions
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
end

function ExplorerMode:SetMovementThreshold(threshold)
    AzeriteMOP.db.explorerMode.movementThreshold = threshold
end

-- Force enable explorer mode for testing
function ExplorerMode:ForceEnable()
    -- AzeriteMOP:Debug("Force enabling Explorer Mode")
    self.isActive = true
    self.isMoving = true
    self.stationaryTimer = 0
    self:EnableExplorerMode()
end

-- Force disable explorer mode for testing
function ExplorerMode:ForceDisable()
    -- AzeriteMOP:Debug("Force disabling Explorer Mode")
    self.isActive = false
    self.isMoving = false
    self.stationaryTimer = 0
    self:DisableExplorerMode()
end

-- Force show frames for testing
function ExplorerMode:ForceShowFrames()
    AzeriteMOP:Debug("Force showing frames...")
    self:EnsureFramesVisible()
    AzeriteMOP:Debug("Force show frames completed")
end

-- Debug function to find frame names
function ExplorerMode:FindFrameNames()
    AzeriteMOP:Debug("Searching for frame names...")
    
    -- Check for objective tracker frames
    AzeriteMOP:Debug("Objective Tracker Frames:")
    local trackerFrames = {"ObjectiveTrackerFrame", "WatchFrame", "QuestWatchFrame", "QuestLogFrame"}
    for _, frameName in ipairs(trackerFrames) do
        local frame = _G[frameName]
        if frame then
            AzeriteMOP:Debug("  " .. frameName .. " exists: " .. tostring(frame:IsShown()))
        else
            AzeriteMOP:Debug("  " .. frameName .. " does not exist")
        end
    end
    
    -- Check for micro menu buttons
    AzeriteMOP:Debug("Micro Menu Buttons:")
    local microButtons = {"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton", 
        "CollectionsMicroButton", "MainMenuMicroButton", "HelpMicroButton", 
        "StoreMicroButton", "EJMicroButton", "PVPMicroButton", "GroupFinderMicroButton",
        "LFDMicroButton", "DungeonFinderMicroButton"}
    for _, buttonName in ipairs(microButtons) do
        local button = _G[buttonName]
        if button then
            AzeriteMOP:Debug("  " .. buttonName .. " exists: " .. tostring(button:IsShown()))
        else
            AzeriteMOP:Debug("  " .. buttonName .. " does not exist")
        end
    end
end

-- Debug function
function ExplorerMode:DebugInfo()
    AzeriteMOP:Debug("Explorer Mode Debug Info:")
    AzeriteMOP:Debug("  Enabled: " .. tostring(self:IsEnabled()))
    AzeriteMOP:Debug("  Active: " .. tostring(self.isActive))
    AzeriteMOP:Debug("  Moving: " .. tostring(self.isMoving))
    AzeriteMOP:Debug("  Stationary Timer: " .. self.stationaryTimer)
    AzeriteMOP:Debug("  Last Position: " .. self.lastPosition.x .. ", " .. self.lastPosition.y)
    AzeriteMOP:Debug("  Combat: " .. tostring(UnitAffectingCombat("player")))
    
    -- Test position tracking
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local position = C_Map.GetPlayerMapPosition(mapID, "player")
        if position then
            AzeriteMOP:Debug("  Current Position: " .. position.x .. ", " .. position.y)
        else
            AzeriteMOP:Debug("  Could not get current position")
        end
    else
        AzeriteMOP:Debug("  Could not get map ID")
    end
    
    -- Test frame visibility
    AzeriteMOP:Debug("  Frame Visibility Test:")
    AzeriteMOP:Debug("    PlayerFrame exists: " .. tostring(AzeriteMOP and AzeriteMOP.PlayerFrame and AzeriteMOP.PlayerFrame.frame ~= nil))
    AzeriteMOP:Debug("    TargetFrame exists: " .. tostring(AzeriteMOP and AzeriteMOP.TargetFrame and AzeriteMOP.TargetFrame.frame ~= nil))
    
    if AzeriteMOP and AzeriteMOP.PlayerFrame and AzeriteMOP.PlayerFrame.frame then
        local frame = AzeriteMOP.PlayerFrame.frame
        AzeriteMOP:Debug("    PlayerFrame visible: " .. tostring(frame:IsShown()))
        AzeriteMOP:Debug("    PlayerFrame alpha: " .. frame:GetAlpha())
        AzeriteMOP:Debug("    PlayerFrame parent: " .. tostring(frame:GetParent() and frame:GetParent():GetName() or "nil"))
    end
    
    if AzeriteMOP and AzeriteMOP.TargetFrame and AzeriteMOP.TargetFrame.frame then
        local frame = AzeriteMOP.TargetFrame.frame
        AzeriteMOP:Debug("    TargetFrame visible: " .. tostring(frame:IsShown()))
        AzeriteMOP:Debug("    TargetFrame alpha: " .. frame:GetAlpha())
        AzeriteMOP:Debug("    TargetFrame parent: " .. tostring(frame:GetParent() and frame:GetParent():GetName() or "nil"))
    end
    
    -- Test chat frame visibility
    AzeriteMOP:Debug("  Chat Frame Visibility Test:")
    local testFrames = {"ChatFrame1", "ChatFrame1EditBox", "ChatFrame1ButtonFrame"}
    for _, frameName in ipairs(testFrames) do
        local frame = _G[frameName]
        if frame then
            AzeriteMOP:Debug("    " .. frameName .. ": " .. tostring(frame:IsShown()))
        else
            AzeriteMOP:Debug("    " .. frameName .. ": Not found")
        end
    end
end 