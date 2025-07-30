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
    
    -- Remove top bar completely
    self:RemoveTopBar()
    
    -- Initialize position tracking
    self:InitializePositionTracking()
    
    -- Set up movement detection
    self:SetupMovementDetection()
    
    -- Register events
    self:RegisterEvents()
    
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

function ExplorerMode:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        self:InitializePositionTracking()
        self:CheckExplorerMode()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Combat started, keep explorer mode active if moving
        -- AzeriteMOP:Debug("ExplorerMode: Combat started, keeping explorer mode active")
        if self.isActive then
            self:ContinuouslyHideUI()
        end
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
    
    -- Check if player is in combat - keep explorer mode active during combat
    if UnitAffectingCombat("player") then
        -- Don't disable explorer mode during combat, just keep UI hidden
        if self.isActive then
            -- AzeriteMOP:Debug("ExplorerMode: Combat detected, keeping explorer mode active")
            self:ContinuouslyHideUI()
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
            -- Continuously hide UI elements to prevent them from reappearing
            self:ContinuouslyHideUI()
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
                    AzeriteMOP:Debug("ExplorerMode: Stationary delay reached (" .. self.stationaryTimer .. "s), disabling explorer mode")
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
    
    -- AzeriteMOP:Debug("Enabling Explorer Mode - Fading out UI")
    self.isActive = true
    
    -- Fade out UI elements
    if AzeriteMOP.db.explorerMode.hideChatFrame then
        self:FadeOutUI()
    end
    
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
    
    -- AzeriteMOP:Debug("Disabling Explorer Mode - Fading in UI")
    self.isActive = false
    
    -- Fade in UI elements
    if AzeriteMOP.db.explorerMode.hideChatFrame then
        self:FadeInUI()
    end
    
    -- Ensure PlayerFrame and TargetFrame stay visible
    self:EnsureFramesVisible()
end

-- Function to hide UI elements for explorer mode
function ExplorerMode:HideChatFrames()
    -- AzeriteMOP:Debug("Hiding UI elements for explorer mode...")
    
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
    
    -- Hide micromenu (character, spellbook, talents, etc.)
    local micromenuElements = {
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
        "LFDMicroButton", "CollectionsMicroButton", "EJMicroButton", 
        "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton"
    }
    for _, elementName in ipairs(micromenuElements) do
        local element = _G[elementName]
        if element then
            element:Hide()
            -- AzeriteMOP:Debug("Hidden " .. elementName)
        end
    end
    
    -- Hide level bar
    local levelBarElements = {
        "MainMenuBar", "MainMenuBarArtFrame", "MainMenuBarArtFrameBackground",
        "MainMenuBarArtFrameLeftCap", "MainMenuBarArtFrameRightCap",
        "MainMenuBarArtFrameBackground", "MainMenuBarArtFrameBorder"
    }
    for _, elementName in ipairs(levelBarElements) do
        local element = _G[elementName]
        if element then
            element:Hide()
            -- AzeriteMOP:Debug("Hidden " .. elementName)
        end
    end
    
    -- Hide minimap
    local minimapElements = {
        "MinimapCluster", "Minimap", "MinimapBackdrop", "MinimapBorder",
        "MinimapBorderTop", "MinimapZoomIn", "MinimapZoomOut",
        "MinimapNorthTag", "MinimapZoneTextButton", "GameTimeFrame"
    }
    for _, elementName in ipairs(minimapElements) do
        local element = _G[elementName]
        if element then
            element:Hide()
            -- AzeriteMOP:Debug("Hidden " .. elementName)
        end
    end
    
    -- Hide action bars
    local actionBarElements = {
        "ActionBarUpButton", "ActionBarDownButton", "MainMenuBar",
        "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight",
        "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7"
    }
    for _, elementName in ipairs(actionBarElements) do
        local element = _G[elementName]
        if element then
            element:Hide()
            -- AzeriteMOP:Debug("Hidden " .. elementName)
        end
    end
    
    -- Hide individual action bar buttons
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            button:Hide()
            -- AzeriteMOP:Debug("Hidden ActionButton" .. i)
        end
        
        local multiBarButton = _G["MultiBarBottomLeftButton" .. i]
        if multiBarButton then
            multiBarButton:Hide()
            -- AzeriteMOP:Debug("Hidden MultiBarBottomLeftButton" .. i)
        end
        
        local multiBarRightButton = _G["MultiBarBottomRightButton" .. i]
        if multiBarRightButton then
            multiBarRightButton:Hide()
            -- AzeriteMOP:Debug("Hidden MultiBarBottomRightButton" .. i)
        end
        
        local multiBarRightButton2 = _G["MultiBarRightButton" .. i]
        if multiBarRightButton2 then
            multiBarRightButton2:Hide()
            -- AzeriteMOP:Debug("Hidden MultiBarRightButton" .. i)
        end
        
        local multiBarLeftButton = _G["MultiBarLeftButton" .. i]
        if multiBarLeftButton then
            multiBarLeftButton:Hide()
            -- AzeriteMOP:Debug("Hidden MultiBarLeftButton" .. i)
        end
    end
end

-- Function to show UI elements for explorer mode
function ExplorerMode:ShowChatFrames()
    -- AzeriteMOP:Debug("Showing UI elements for explorer mode...")
    
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
    
    -- Show micromenu (character, spellbook, talents, etc.)
    local micromenuElements = {
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
        "LFDMicroButton", "CollectionsMicroButton", "EJMicroButton", 
        "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton"
    }
    for _, elementName in ipairs(micromenuElements) do
        local element = _G[elementName]
        if element then
            element:Show()
            -- AzeriteMOP:Debug("Shown " .. elementName)
        end
    end
    
    -- Show level bar
    local levelBarElements = {
        "MainMenuBar", "MainMenuBarArtFrame", "MainMenuBarArtFrameBackground",
        "MainMenuBarArtFrameLeftCap", "MainMenuBarArtFrameRightCap",
        "MainMenuBarArtFrameBackground", "MainMenuBarArtFrameBorder"
    }
    for _, elementName in ipairs(levelBarElements) do
        local element = _G[elementName]
        if element then
            element:Show()
            -- AzeriteMOP:Debug("Shown " .. elementName)
        end
    end
    
    -- Show minimap
    local minimapElements = {
        "MinimapCluster", "Minimap", "MinimapBackdrop", "MinimapBorder",
        "MinimapBorderTop", "MinimapZoomIn", "MinimapZoomOut",
        "MinimapNorthTag", "MinimapZoneTextButton", "GameTimeFrame"
    }
    for _, elementName in ipairs(minimapElements) do
        local element = _G[elementName]
        if element then
            element:Show()
            -- AzeriteMOP:Debug("Shown " .. elementName)
        end
    end
    
    -- Show action bars
    local actionBarElements = {
        "ActionBarUpButton", "ActionBarDownButton", "MainMenuBar",
        "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight",
        "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7"
    }
    for _, elementName in ipairs(actionBarElements) do
        local element = _G[elementName]
        if element then
            element:Show()
            -- AzeriteMOP:Debug("Shown " .. elementName)
        end
    end
    
    -- Show individual action bar buttons
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            button:Show()
            -- AzeriteMOP:Debug("Shown ActionButton" .. i)
        end
        
        local multiBarButton = _G["MultiBarBottomLeftButton" .. i]
        if multiBarButton then
            multiBarButton:Show()
            -- AzeriteMOP:Debug("Shown MultiBarBottomLeftButton" .. i)
        end
        
        local multiBarRightButton = _G["MultiBarBottomRightButton" .. i]
        if multiBarRightButton then
            multiBarRightButton:Show()
            -- AzeriteMOP:Debug("Shown MultiBarBottomRightButton" .. i)
        end
        
        local multiBarRightButton2 = _G["MultiBarRightButton" .. i]
        if multiBarRightButton2 then
            multiBarRightButton2:Show()
            -- AzeriteMOP:Debug("Shown MultiBarRightButton" .. i)
        end
        
        local multiBarLeftButton = _G["MultiBarLeftButton" .. i]
        if multiBarLeftButton then
            multiBarLeftButton:Show()
            -- AzeriteMOP:Debug("Shown MultiBarLeftButton" .. i)
        end
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

-- Function to remove top bar completely
function ExplorerMode:RemoveTopBar()
    -- Remove top bar elements completely
    local topBarElements = {
        "TopBar", "TopBarFrame", "TopBarContainer", "TopBarBackground",
        "TopBarLeft", "TopBarRight", "TopBarCenter", "TopBarArt",
        "TopBarBorder", "TopBarBorderLeft", "TopBarBorderRight"
    }
    for _, elementName in ipairs(topBarElements) do
        local element = _G[elementName]
        if element then
            element:SetParent(nil)
            element:Hide()
            AzeriteMOP:Debug("Removed top bar element: " .. elementName)
        end
    end
    
    -- Also try to remove any top bar by name variations
    for i = 1, 10 do
        local topBar = _G["TopBar" .. i]
        if topBar then
            topBar:SetParent(nil)
            topBar:Hide()
            AzeriteMOP:Debug("Removed top bar by index: " .. i)
        end
    end
    
    -- Check for any other potential top bar elements
    local additionalTopBarElements = {
        "TopBarContainer", "TopBarBackground", "TopBarArt", "TopBarBorder",
        "TopBarLeft", "TopBarRight", "TopBarCenter", "TopBarFrame",
        "TopBarContainerLeft", "TopBarContainerRight", "TopBarContainerCenter"
    }
    for _, elementName in ipairs(additionalTopBarElements) do
        local element = _G[elementName]
        if element then
            element:SetParent(nil)
            element:Hide()
            AzeriteMOP:Debug("Removed additional top bar element: " .. elementName)
        end
    end
end

-- Function to fade out UI elements
function ExplorerMode:FadeOutUI()
    -- Fade out chat frames
    local chatElements = {
        "ChatFrame1", "ChatFrame1Tab", "ChatFrame1EditBox", "ChatFrame1ButtonFrame"
    }
    for _, elementName in ipairs(chatElements) do
        local element = _G[elementName]
        if element then
            element:SetAlpha(0)
            element:Hide()
        end
    end
    
    -- Fade out any other visible chat frames
    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame:SetAlpha(0)
            chatFrame:Hide()
        end
        
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        if chatTab then
            chatTab:SetAlpha(0)
            chatTab:Hide()
        end
    end
    
    -- Fade out micromenu
    local micromenuElements = {
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
        "LFDMicroButton", "CollectionsMicroButton", "EJMicroButton", 
        "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton",
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
        "LFDMicroButton", "CollectionsMicroButton", "EJMicroButton",
        "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton",
        "MicroButtonAndBagsBar", "MicroButtonContainer", "MicroButtonContainerLeft",
        "MicroButtonContainerRight", "MicroButtonContainerCenter",
        -- MoP specific buttons
        "PVPMicroButton", "LFGMicroButton", "GroupFinderMicroButton",
        "DungeonFinderMicroButton", "RaidFinderMicroButton"
    }
    for _, elementName in ipairs(micromenuElements) do
        local element = _G[elementName]
        if element then
            element:SetAlpha(0)
            element:Hide()
        end
    end
    
    -- Fade out level bar
    local levelBarElements = {
        "MainMenuBar", "MainMenuBarArtFrame", "MainMenuBarArtFrameBackground",
        "MainMenuBarArtFrameLeftCap", "MainMenuBarArtFrameRightCap",
        "MainMenuBarArtFrameBackground", "MainMenuBarArtFrameBorder"
    }
    for _, elementName in ipairs(levelBarElements) do
        local element = _G[elementName]
        if element then
            element:SetAlpha(0)
            element:Hide()
        end
    end
    
    -- Fade out minimap
    local minimapElements = {
        "MinimapCluster", "Minimap", "MinimapBackdrop", "MinimapBorder",
        "MinimapBorderTop", "MinimapZoomIn", "MinimapZoomOut",
        "MinimapNorthTag", "MinimapZoneTextButton", "GameTimeFrame"
    }
    for _, elementName in ipairs(minimapElements) do
        local element = _G[elementName]
        if element then
            element:SetAlpha(0)
            element:Hide()
        end
    end
    
    -- Fade out objectives/quest tracker
    local objectiveElements = {
        "ObjectiveTrackerFrame", "ObjectiveTrackerBlocksFrame", "ObjectiveTrackerHeader",
        "QuestObjectiveTracker", "AchievementObjectiveTracker", "ScenarioObjectiveTracker",
        "WorldQuestObjectiveTracker", "BonusObjectiveTracker", "QuestTimerFrame",
        "QuestTimerFrameText", "QuestTimerFrameTimeText"
    }
    for _, elementName in ipairs(objectiveElements) do
        local element = _G[elementName]
        if element then
            element:SetAlpha(0)
            element:Hide()
        end
    end
    
    -- Fade out action bars
    local actionBarElements = {
        "ActionBarUpButton", "ActionBarDownButton", "MainMenuBar",
        "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight",
        "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7"
    }
    for _, elementName in ipairs(actionBarElements) do
        local element = _G[elementName]
        if element then
            element:SetAlpha(0)
            element:Hide()
        end
    end
    
    -- Fade out individual action bar buttons
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            button:SetAlpha(0)
            button:Hide()
        end
        
        local multiBarButton = _G["MultiBarBottomLeftButton" .. i]
        if multiBarButton then
            multiBarButton:SetAlpha(0)
            multiBarButton:Hide()
        end
        
        local multiBarRightButton = _G["MultiBarBottomRightButton" .. i]
        if multiBarRightButton then
            multiBarRightButton:SetAlpha(0)
            multiBarRightButton:Hide()
        end
        
        local multiBarRightButton2 = _G["MultiBarRightButton" .. i]
        if multiBarRightButton2 then
            multiBarRightButton2:SetAlpha(0)
            multiBarRightButton2:Hide()
        end
        
        local multiBarLeftButton = _G["MultiBarLeftButton" .. i]
        if multiBarLeftButton then
            multiBarLeftButton:SetAlpha(0)
            multiBarLeftButton:Hide()
        end
    end
end

-- Function to fade in UI elements
function ExplorerMode:FadeInUI()
    -- Fade in chat frames
    local chatElements = {
        "ChatFrame1", "ChatFrame1Tab", "ChatFrame1EditBox", "ChatFrame1ButtonFrame"
    }
    for _, elementName in ipairs(chatElements) do
        local element = _G[elementName]
        if element then
            element:Show()
            element:SetAlpha(1)
        end
    end
    
    -- Only show main chat frame, not extra chat frames
    -- (Removed extra chat frame showing logic as requested)
    
    -- Fade in micromenu
    local micromenuElements = {
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
        "LFDMicroButton", "CollectionsMicroButton", "EJMicroButton", 
        "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton",
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
        "LFDMicroButton", "CollectionsMicroButton", "EJMicroButton",
        "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton",
        "MicroButtonAndBagsBar", "MicroButtonContainer", "MicroButtonContainerLeft",
        "MicroButtonContainerRight", "MicroButtonContainerCenter",
        -- MoP specific buttons
        "PVPMicroButton", "LFGMicroButton", "GroupFinderMicroButton",
        "DungeonFinderMicroButton", "RaidFinderMicroButton"
    }
    for _, elementName in ipairs(micromenuElements) do
        local element = _G[elementName]
        if element then
            element:Show()
            element:SetAlpha(1)
        end
    end
    
    -- Fade in level bar
    local levelBarElements = {
        "MainMenuBar", "MainMenuBarArtFrame", "MainMenuBarArtFrameBackground",
        "MainMenuBarArtFrameLeftCap", "MainMenuBarArtFrameRightCap",
        "MainMenuBarArtFrameBackground", "MainMenuBarArtFrameBorder"
    }
    for _, elementName in ipairs(levelBarElements) do
        local element = _G[elementName]
        if element then
            element:Show()
            element:SetAlpha(1)
        end
    end
    
    -- Fade in minimap
    local minimapElements = {
        "MinimapCluster", "Minimap", "MinimapBackdrop", "MinimapBorder",
        "MinimapBorderTop", "MinimapZoomIn", "MinimapZoomOut",
        "MinimapNorthTag", "MinimapZoneTextButton", "GameTimeFrame"
    }
    for _, elementName in ipairs(minimapElements) do
        local element = _G[elementName]
        if element then
            element:Show()
            element:SetAlpha(1)
        end
    end
    
    -- Fade in objectives/quest tracker
    local objectiveElements = {
        "ObjectiveTrackerFrame", "ObjectiveTrackerBlocksFrame", "ObjectiveTrackerHeader",
        "QuestObjectiveTracker", "AchievementObjectiveTracker", "ScenarioObjectiveTracker",
        "WorldQuestObjectiveTracker", "BonusObjectiveTracker", "QuestTimerFrame",
        "QuestTimerFrameText", "QuestTimerFrameTimeText"
    }
    for _, elementName in ipairs(objectiveElements) do
        local element = _G[elementName]
        if element then
            element:Show()
            element:SetAlpha(1)
        end
    end
    
    -- Fade in action bars
    local actionBarElements = {
        "ActionBarUpButton", "ActionBarDownButton", "MainMenuBar",
        "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight",
        "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7"
    }
    for _, elementName in ipairs(actionBarElements) do
        local element = _G[elementName]
        if element then
            element:Show()
            element:SetAlpha(1)
        end
    end
    
    -- Fade in individual action bar buttons
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            button:Show()
            button:SetAlpha(1)
        end
        
        local multiBarButton = _G["MultiBarBottomLeftButton" .. i]
        if multiBarButton then
            multiBarButton:Show()
            multiBarButton:SetAlpha(1)
        end
        
        local multiBarRightButton = _G["MultiBarBottomRightButton" .. i]
        if multiBarRightButton then
            multiBarRightButton:Show()
            multiBarRightButton:SetAlpha(1)
        end
        
        local multiBarRightButton2 = _G["MultiBarRightButton" .. i]
        if multiBarRightButton2 then
            multiBarRightButton2:Show()
            multiBarRightButton2:SetAlpha(1)
        end
        
        local multiBarLeftButton = _G["MultiBarLeftButton" .. i]
        if multiBarLeftButton then
            multiBarLeftButton:Show()
            multiBarLeftButton:SetAlpha(1)
        end
    end
end

-- Function to continuously hide UI elements to prevent them from reappearing
function ExplorerMode:ContinuouslyHideUI()
    -- Hide chat frames continuously
    local chatElements = {
        "ChatFrame1", "ChatFrame1Tab", "ChatFrame1EditBox", "ChatFrame1ButtonFrame"
    }
    for _, elementName in ipairs(chatElements) do
        local element = _G[elementName]
        if element and element:IsShown() then
            element:SetAlpha(0)
            element:Hide()
            -- AzeriteMOP:Debug("Continuously hidden " .. elementName)
        end
    end
    
    -- Hide any other visible chat frames
    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame:IsShown() then
            chatFrame:Hide()
        end
        
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        if chatTab and chatTab:IsShown() then
            chatTab:Hide()
        end
    end
    
    -- Hide micromenu continuously
    local micromenuElements = {
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", 
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
        "LFDMicroButton", "CollectionsMicroButton", "EJMicroButton", 
        "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton",
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
        "LFDMicroButton", "CollectionsMicroButton", "EJMicroButton",
        "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton",
        "MicroButtonAndBagsBar", "MicroButtonContainer", "MicroButtonContainerLeft",
        "MicroButtonContainerRight", "MicroButtonContainerCenter",
        -- MoP specific buttons
        "PVPMicroButton", "LFGMicroButton", "GroupFinderMicroButton",
        "DungeonFinderMicroButton", "RaidFinderMicroButton"
    }
    for _, elementName in ipairs(micromenuElements) do
        local element = _G[elementName]
        if element and element:IsShown() then
            element:Hide()
        end
    end
    
    -- Hide level bar continuously
    local levelBarElements = {
        "MainMenuBar", "MainMenuBarArtFrame", "MainMenuBarArtFrameBackground",
        "MainMenuBarArtFrameLeftCap", "MainMenuBarArtFrameRightCap",
        "MainMenuBarArtFrameBackground", "MainMenuBarArtFrameBorder"
    }
    for _, elementName in ipairs(levelBarElements) do
        local element = _G[elementName]
        if element and element:IsShown() then
            element:Hide()
        end
    end
    
    -- Hide minimap continuously
    local minimapElements = {
        "MinimapCluster", "Minimap", "MinimapBackdrop", "MinimapBorder",
        "MinimapBorderTop", "MinimapZoomIn", "MinimapZoomOut",
        "MinimapNorthTag", "MinimapZoneTextButton", "GameTimeFrame"
    }
    for _, elementName in ipairs(minimapElements) do
        local element = _G[elementName]
        if element and element:IsShown() then
            element:Hide()
        end
    end
    
    -- Hide objectives/quest tracker continuously
    local objectiveElements = {
        "ObjectiveTrackerFrame", "ObjectiveTrackerBlocksFrame", "ObjectiveTrackerHeader",
        "QuestObjectiveTracker", "AchievementObjectiveTracker", "ScenarioObjectiveTracker",
        "WorldQuestObjectiveTracker", "BonusObjectiveTracker", "QuestTimerFrame",
        "QuestTimerFrameText", "QuestTimerFrameTimeText"
    }
    for _, elementName in ipairs(objectiveElements) do
        local element = _G[elementName]
        if element and element:IsShown() then
            element:SetAlpha(0)
            element:Hide()
        end
    end
    
    -- Hide action bars continuously
    local actionBarElements = {
        "ActionBarUpButton", "ActionBarDownButton", "MainMenuBar",
        "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight",
        "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7"
    }
    for _, elementName in ipairs(actionBarElements) do
        local element = _G[elementName]
        if element and element:IsShown() then
            element:Hide()
        end
    end
    
    -- Hide individual action bar buttons continuously
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button and button:IsShown() then
            button:Hide()
        end
        
        local multiBarButton = _G["MultiBarBottomLeftButton" .. i]
        if multiBarButton and multiBarButton:IsShown() then
            multiBarButton:Hide()
        end
        
        local multiBarRightButton = _G["MultiBarBottomRightButton" .. i]
        if multiBarRightButton and multiBarRightButton:IsShown() then
            multiBarRightButton:Hide()
        end
        
        local multiBarRightButton2 = _G["MultiBarRightButton" .. i]
        if multiBarRightButton2 and multiBarRightButton2:IsShown() then
            multiBarRightButton2:Hide()
        end
        
        local multiBarLeftButton = _G["MultiBarLeftButton" .. i]
        if multiBarLeftButton and multiBarLeftButton:IsShown() then
            multiBarLeftButton:Hide()
        end
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

-- Function to check for any extra frames being created
function ExplorerMode:CheckForExtraFrames()
    AzeriteMOP:Debug("Checking for extra frames...")
    
    -- Check for any frames with AzeriteMOP in the name
    for name, frame in pairs(_G) do
        if type(frame) == "table" and frame.GetName and frame:GetName() and 
           string.find(frame:GetName(), "AzeriteMOP") and 
           frame:GetName() ~= "AzeriteMOPPlayerFrame" and 
           frame:GetName() ~= "AzeriteMOPTargetFrame" then
            AzeriteMOP:Debug("Found extra frame: " .. frame:GetName())
        end
    end
    
    -- Check for any unnamed frames that might be ours
    AzeriteMOP:Debug("Frame check completed")
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