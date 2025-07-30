-- AzeriteMOP Explorer Mode Module
-- Automatically hides UI elements during exploration for immersive experience

local ADDON_NAME, Addon = ...
local AzeriteMOP = Addon.AzeriteMOP

-- Create ExplorerMode module
AzeriteMOP.ExplorerMode = {}
local ExplorerMode = AzeriteMOP.ExplorerMode

-- Constants
local MOVEMENT_THRESHOLD = 0.1 -- Minimum movement to trigger explorer mode
local STATIONARY_DELAY = 2.0 -- Seconds to wait before showing UI when stationary
local UPDATE_INTERVAL = 0.1 -- How often to check for movement

-- State variables
ExplorerMode.isActive = false
ExplorerMode.isMoving = false
ExplorerMode.lastPosition = {x = 0, y = 0}
ExplorerMode.stationaryTimer = 0
ExplorerMode.hiddenFrames = {}

-- Ensure database exists immediately when module loads
if AzeriteMOP then
    if not AzeriteMOP.db then
        AzeriteMOP.db = {}
    end
    if not AzeriteMOP.db.explorerMode then
        AzeriteMOP.db.explorerMode = {
            enabled = true,
            hideQuestLog = true,
            hideChatFrame = true,
            hideMinimap = false,
            hideActionBars = false,
            stationaryDelay = 2.0,
            movementThreshold = 0.1
        }
    end
    AzeriteMOP:Debug("ExplorerMode module: Database initialized")
end

-- Function to scan for all visible frames (for debugging)
function ExplorerMode:ScanVisibleFrames()
    AzeriteMOP:Debug("Scanning for visible frames...")
    local visibleFrames = {}
    
    -- Common frame names to check
    local frameNames = {
        "ChatFrame1", "ChatFrame2", "ChatFrame3", "ChatFrame4", "ChatFrame5", "ChatFrame6", "ChatFrame7",
        "ChatFrame1EditBox", "ChatFrame1ButtonFrame", "ChatFrame1Tab", "ChatFrame2Tab", "ChatFrame3Tab",
        "QuestLogFrame", "ObjectiveTrackerFrame", "WatchFrame", "QuestWatchFrame",
        "MinimapCluster", "Minimap", "MinimapBackdrop",
        "ActionButton1", "ActionButton2", "ActionButton3", "ActionButton4", "ActionButton5",
        "ActionButton6", "ActionButton7", "ActionButton8", "ActionButton9", "ActionButton10",
        "MultiBarBottomLeftButton1", "MultiBarBottomRightButton1", "MultiBarRightButton1", "MultiBarLeftButton1"
    }
    
    for _, frameName in ipairs(frameNames) do
        local frame = _G[frameName]
        if frame and frame:IsShown() then
            table.insert(visibleFrames, frameName)
        end
    end
    
    AzeriteMOP:Debug("Visible frames found: " .. table.concat(visibleFrames, ", "))
    return visibleFrames
end

-- Function to hide all chat-related frames
function ExplorerMode:HideAllChatFrames()
    AzeriteMOP:Debug("Attempting to hide all chat-related frames...")
    
    -- Hide main chat frames
    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame:Hide()
            AzeriteMOP:Debug("Hidden ChatFrame" .. i)
        end
        
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        if chatTab then
            chatTab:Hide()
            AzeriteMOP:Debug("Hidden ChatFrame" .. i .. "Tab")
        end
    end
    
    -- Hide chat edit boxes
    for i = 1, 10 do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then
            editBox:Hide()
            AzeriteMOP:Debug("Hidden ChatFrame" .. i .. "EditBox")
        end
    end
    
    -- Hide specific chat elements
    local chatElements = {
        "ChatFrame1EditBox", "ChatFrame1ButtonFrame", "ChatFrame1Tab",
        "ChatFrameMenuButton", "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton",
        "ChatFrame1", "ChatFrame2", "ChatFrame3", "ChatFrame4", "ChatFrame5", "ChatFrame6", "ChatFrame7"
    }
    
    for _, elementName in ipairs(chatElements) do
        local element = _G[elementName]
        if element then
            element:Hide()
            AzeriteMOP:Debug("Hidden " .. elementName)
        end
    end
    
    -- Try to hide the chat container and all its parents
    if ChatFrame1 then
        local parent = ChatFrame1:GetParent()
        if parent then
            parent:Hide()
            AzeriteMOP:Debug("Hidden ChatFrame1 parent")
            
            -- Try to hide grandparents too
            local grandparent = parent:GetParent()
            if grandparent then
                grandparent:Hide()
                AzeriteMOP:Debug("Hidden ChatFrame1 grandparent")
            end
        end
    end
    
    -- Try to hide the entire chat system using UIParent
    local chatSystem = _G["ChatFrame1"] or _G["ChatFrame"]
    if chatSystem then
        -- Try to hide the entire chat system
        chatSystem:SetParent(nil)
        AzeriteMOP:Debug("Set ChatFrame1 parent to nil")
    end
    
    -- Try to hide any chat-related containers
    local chatContainers = {"ChatFrameContainer", "ChatFrame1Container", "ChatFrame2Container"}
    for _, containerName in ipairs(chatContainers) do
        local container = _G[containerName]
        if container then
            container:Hide()
            AzeriteMOP:Debug("Hidden " .. containerName)
        end
    end
    
    -- Force hide any visible chat frames by setting alpha to 0
    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame:SetAlpha(0)
            AzeriteMOP:Debug("Set ChatFrame" .. i .. " alpha to 0")
        end
    end
end

-- Function to show all chat-related frames
function ExplorerMode:ShowAllChatFrames()
    AzeriteMOP:Debug("Attempting to show all chat-related frames...")
    
    -- Show main chat frames
    for i = 1, 10 do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame:Show()
            AzeriteMOP:Debug("Shown ChatFrame" .. i)
        end
        
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        if chatTab then
            chatTab:Show()
            AzeriteMOP:Debug("Shown ChatFrame" .. i .. "Tab")
        end
    end
    
    -- Show chat edit boxes
    for i = 1, 10 do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then
            editBox:Show()
            AzeriteMOP:Debug("Shown ChatFrame" .. i .. "EditBox")
        end
    end
    
    -- Show specific chat elements
    local chatElements = {
        "ChatFrame1EditBox", "ChatFrame1ButtonFrame", "ChatFrame1Tab",
        "ChatFrameMenuButton", "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton"
    }
    
    for _, elementName in ipairs(chatElements) do
        local element = _G[elementName]
        if element then
            element:Show()
            AzeriteMOP:Debug("Shown " .. elementName)
        end
    end
    
    -- Show the chat container
    if ChatFrame1 then
        local parent = ChatFrame1:GetParent()
        if parent then
            parent:Show()
            AzeriteMOP:Debug("Shown ChatFrame1 parent")
        end
        
        -- Show grandparents too
        local grandparent = parent and parent:GetParent()
        if grandparent then
            grandparent:Show()
            AzeriteMOP:Debug("Shown ChatFrame1 grandparent")
        end
    end
end

function ExplorerMode:Initialize()
    AzeriteMOP:Debug("Initializing Explorer Mode...")
    
    -- Ensure database is available
    if not AzeriteMOP.db then
        AzeriteMOP:Debug("Initialize: Creating AzeriteMOP.db")
        AzeriteMOP.db = {}
    end
    
    if not AzeriteMOP.db.explorerMode then
        AzeriteMOP:Debug("Initialize: Creating explorerMode in database")
        AzeriteMOP.db.explorerMode = {
            enabled = true,
            hideQuestLog = true,
            hideChatFrame = true,
            hideMinimap = false,
            hideActionBars = false,
            stationaryDelay = 2.0,
            movementThreshold = 0.1
        }
    end
    
    -- Initialize position tracking
    self:InitializePositionTracking()
    
    -- Set up movement detection
    self:SetupMovementDetection()
    
    -- Register events
    self:RegisterEvents()
    
    -- Store original UI states
    self:StoreOriginalStates()
    
    AzeriteMOP:Debug("Explorer Mode initialized!")
end

function ExplorerMode:InitializePositionTracking()
    -- Get initial player position using GetPlayerMapPosition
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local position = C_Map.GetPlayerMapPosition(mapID, "player")
        if position then
            self.lastPosition.x = position.x
            self.lastPosition.y = position.y
            AzeriteMOP:Debug("ExplorerMode: Initial position set to " .. position.x .. ", " .. position.y)
        else
            AzeriteMOP:Debug("ExplorerMode: Could not get initial position")
        end
    else
        AzeriteMOP:Debug("ExplorerMode: Could not get map ID")
    end
    
    -- Fallback: Initialize with default values if position tracking fails
    if not self.lastPosition.x or not self.lastPosition.y then
        self.lastPosition.x = 0
        self.lastPosition.y = 0
        AzeriteMOP:Debug("ExplorerMode: Using fallback position values")
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
    
    self.updateFrame:SetScript("OnEvent", function(frame, event, ...)
        ExplorerMode:OnEvent(event, ...)
    end)
end

function ExplorerMode:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        self:InitializePositionTracking()
        self:CheckExplorerMode()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Combat started, disable explorer mode
        AzeriteMOP:Debug("ExplorerMode: Combat started, disabling explorer mode")
        self:DisableExplorerMode()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended, check if we should enable explorer mode
        AzeriteMOP:Debug("ExplorerMode: Combat ended, checking explorer mode")
        self:CheckExplorerMode()
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
            AzeriteMOP:Debug("ExplorerMode: Combat detected, disabling explorer mode")
            self:DisableExplorerMode()
        end
        return
    end
    
    -- Use a simpler, more reliable movement detection for MoP Classic
    if not self.lastUpdateTime then
        self.lastUpdateTime = GetTime()
        self.lastPlayerX = 0
        self.lastPlayerY = 0
    end
    
    local currentTime = GetTime()
    local timeDiff = currentTime - self.lastUpdateTime
    
    -- Check movement every 0.5 seconds
    if timeDiff >= 0.5 then
        -- Get current player position using GetPlayerMapPosition
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
            
            -- Check if player is moving
            local threshold = AzeriteMOP.db.explorerMode.movementThreshold
            local isMoving = distance > threshold
            
            AzeriteMOP:Debug("ExplorerMode: Position " .. position.x .. ", " .. position.y .. " | Distance: " .. distance .. " | Moving: " .. tostring(isMoving))
            
            if isMoving then
                -- Player is moving
                if not self.isMoving then
                    self.isMoving = true
                    self.stationaryTimer = 0
                    AzeriteMOP:Debug("ExplorerMode: Player started moving, enabling explorer mode")
                    self:EnableExplorerMode()
                end
            else
                -- Player is stationary
                if self.isMoving then
                    self.isMoving = false
                    AzeriteMOP:Debug("ExplorerMode: Player stopped moving")
                end
                
                -- Increment stationary timer
                self.stationaryTimer = self.stationaryTimer + timeDiff
                
                -- Check if we should disable explorer mode
                local delay = AzeriteMOP.db.explorerMode.stationaryDelay
                if self.stationaryTimer >= delay and self.isActive then
                    AzeriteMOP:Debug("ExplorerMode: Stationary delay reached, disabling explorer mode")
                    self:DisableExplorerMode()
                end
            end
            
            -- Update last position
            self.lastPlayerX = position.x
            self.lastPlayerY = position.y
        else
            -- Fallback: Use a time-based movement detection
            AzeriteMOP:Debug("ExplorerMode: Could not get position, using fallback detection")
            
            -- Assume player is moving if we can't get position (they're probably not standing still)
            if not self.isMoving then
                self.isMoving = true
                self.stationaryTimer = 0
                AzeriteMOP:Debug("ExplorerMode: Player started moving (fallback), enabling explorer mode")
                self:EnableExplorerMode()
            end
        end
        
        self.lastUpdateTime = currentTime
    end
end

function ExplorerMode:StoreOriginalStates()
    -- Store original visibility states of UI elements
    self.hiddenFrames = {}
    
    -- Quest Log - try multiple possible frame names
    local questFrames = {"QuestLogFrame", "ObjectiveTrackerFrame", "WatchFrame", "QuestWatchFrame"}
    for _, frameName in ipairs(questFrames) do
        local frame = _G[frameName]
        if frame then
            self.hiddenFrames[frameName] = {
                frame = frame,
                originalShown = frame:IsShown()
            }
            AzeriteMOP:Debug("ExplorerMode: Found quest frame: " .. frameName)
        end
    end
    
    -- Chat Frame - try multiple possible frame names
    local chatFrames = {"ChatFrame1", "ChatFrame", "ChatFrame1EditBox", "ChatFrame1ButtonFrame"}
    for _, frameName in ipairs(chatFrames) do
        local frame = _G[frameName]
        if frame then
            self.hiddenFrames[frameName] = {
                frame = frame,
                originalShown = frame:IsShown()
            }
            AzeriteMOP:Debug("ExplorerMode: Found chat frame: " .. frameName)
        end
    end
    
    -- Minimap (optional)
    if AzeriteMOP.db.explorerMode.hideMinimap and MinimapCluster then
        self.hiddenFrames.minimap = {
            frame = MinimapCluster,
            originalShown = MinimapCluster:IsShown()
        }
        AzeriteMOP:Debug("ExplorerMode: Found minimap frame")
    end
    
    -- Action Bars (optional)
    if AzeriteMOP.db.explorerMode.hideActionBars then
        -- Store action bar frames
        for i = 1, 10 do
            local actionBar = _G["ActionButton" .. i]
            if actionBar then
                self.hiddenFrames["actionBar" .. i] = {
                    frame = actionBar,
                    originalShown = actionBar:IsShown()
                }
            end
        end
        AzeriteMOP:Debug("ExplorerMode: Found action bar frames")
    end
end

function ExplorerMode:EnableExplorerMode()
    if self.isActive then
        return
    end
    
    AzeriteMOP:Debug("Enabling Explorer Mode")
    self.isActive = true
    
    -- Hide quest log and objectives using multiple methods
    if AzeriteMOP.db.explorerMode.hideQuestLog then
        -- Method 1: Try to hide specific frames
        local questFrames = {"QuestLogFrame", "ObjectiveTrackerFrame", "WatchFrame", "QuestWatchFrame"}
        for _, frameName in ipairs(questFrames) do
            local frame = _G[frameName]
            if frame then
                frame:Hide()
                AzeriteMOP:Debug("ExplorerMode: Hidden " .. frameName)
            end
        end
        
        -- Method 2: Try to hide quest log using ShowUIPanel/ShowUIPanel
        if QuestLogFrame then
            HideUIPanel(QuestLogFrame)
            AzeriteMOP:Debug("ExplorerMode: Used HideUIPanel on QuestLogFrame")
        end
        
        -- Method 3: Try to hide objectives using ObjectiveTracker
        if ObjectiveTrackerFrame then
            ObjectiveTrackerFrame:Hide()
            AzeriteMOP:Debug("ExplorerMode: Hidden ObjectiveTrackerFrame")
        end
        
        -- Method 4: Try to hide watch frame
        if WatchFrame then
            WatchFrame:Hide()
            AzeriteMOP:Debug("ExplorerMode: Hidden WatchFrame")
        end
        
        -- Method 5: Hide quest objective markers (white triangles)
        local questMarkers = {"QuestPOIFrame", "QuestPOIButton", "QuestPOIButton1", "QuestPOIButton2"}
        for _, markerName in ipairs(questMarkers) do
            local marker = _G[markerName]
            if marker then
                marker:Hide()
                AzeriteMOP:Debug("ExplorerMode: Hidden " .. markerName)
            end
        end
        
        -- Method 6: Try to hide quest-related UI elements
        local questUI = {"QuestLogFrame", "QuestLogFrame", "QuestLogFrame", "QuestLogFrame"}
        for _, uiName in ipairs(questUI) do
            local ui = _G[uiName]
            if ui then
                ui:Hide()
                AzeriteMOP:Debug("ExplorerMode: Hidden " .. uiName)
            end
        end
        
        -- Method 7: Hide any POI (Points of Interest) frames
        for i = 1, 50 do
            local poiFrame = _G["QuestPOIButton" .. i]
            if poiFrame then
                poiFrame:Hide()
                AzeriteMOP:Debug("ExplorerMode: Hidden QuestPOIButton" .. i)
            end
        end
        
        -- Method 8: Try to hide the entire quest system
        if QuestLogFrame then
            QuestLogFrame:SetParent(nil)
            AzeriteMOP:Debug("ExplorerMode: Set QuestLogFrame parent to nil")
        end
    end
    
    -- Hide chat frame using comprehensive method
    if AzeriteMOP.db.explorerMode.hideChatFrame then
        self:HideAllChatFrames()
    end
    
    -- Hide minimap (optional)
    if AzeriteMOP.db.explorerMode.hideMinimap and MinimapCluster then
        MinimapCluster:Hide()
        AzeriteMOP:Debug("ExplorerMode: Hidden MinimapCluster")
    end
    
    -- Hide action bars (optional)
    if AzeriteMOP.db.explorerMode.hideActionBars then
        for i = 1, 10 do
            local actionBar = _G["ActionButton" .. i]
            if actionBar then
                actionBar:Hide()
            end
        end
        AzeriteMOP:Debug("ExplorerMode: Hidden action bars")
    end
end

function ExplorerMode:DisableExplorerMode()
    if not self.isActive then
        return
    end
    
    AzeriteMOP:Debug("Disabling Explorer Mode")
    self.isActive = false
    
    -- Show quest log and objectives
    if AzeriteMOP.db.explorerMode.hideQuestLog then
        local questFrames = {"QuestLogFrame", "ObjectiveTrackerFrame", "WatchFrame", "QuestWatchFrame"}
        for _, frameName in ipairs(questFrames) do
            local frame = _G[frameName]
            if frame then
                frame:Show()
                AzeriteMOP:Debug("ExplorerMode: Shown " .. frameName)
            end
        end
        
        -- Show quest log using ShowUIPanel
        if QuestLogFrame then
            ShowUIPanel(QuestLogFrame)
            AzeriteMOP:Debug("ExplorerMode: Used ShowUIPanel on QuestLogFrame")
        end
        
        -- Show objectives
        if ObjectiveTrackerFrame then
            ObjectiveTrackerFrame:Show()
            AzeriteMOP:Debug("ExplorerMode: Shown ObjectiveTrackerFrame")
        end
        
        -- Show watch frame
        if WatchFrame then
            WatchFrame:Show()
            AzeriteMOP:Debug("ExplorerMode: Shown WatchFrame")
        end
    end
    
    -- Show chat frame using comprehensive method
    if AzeriteMOP.db.explorerMode.hideChatFrame then
        self:ShowAllChatFrames()
    end
    
    -- Show minimap (optional)
    if AzeriteMOP.db.explorerMode.hideMinimap and MinimapCluster then
        MinimapCluster:Show()
        AzeriteMOP:Debug("ExplorerMode: Shown MinimapCluster")
    end
    
    -- Show action bars (optional)
    if AzeriteMOP.db.explorerMode.hideActionBars then
        for i = 1, 10 do
            local actionBar = _G["ActionButton" .. i]
            if actionBar then
                actionBar:Show()
            end
        end
        AzeriteMOP:Debug("ExplorerMode: Shown action bars")
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
    AzeriteMOP:Debug("Force enabling Explorer Mode")
    self.isActive = true
    self.isMoving = true
    self.stationaryTimer = 0
    self:EnableExplorerMode()
end

-- Force disable explorer mode for testing
function ExplorerMode:ForceDisable()
    AzeriteMOP:Debug("Force disabling Explorer Mode")
    self.isActive = false
    self.isMoving = false
    self.stationaryTimer = 0
    self:DisableExplorerMode()
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
    local testFrames = {"ChatFrame1", "QuestLogFrame", "ObjectiveTrackerFrame", "WatchFrame", "ChatFrame1EditBox", "ChatFrame1ButtonFrame"}
    for _, frameName in ipairs(testFrames) do
        local frame = _G[frameName]
        if frame then
            AzeriteMOP:Debug("    " .. frameName .. ": " .. tostring(frame:IsShown()))
        else
            AzeriteMOP:Debug("    " .. frameName .. ": Not found")
        end
    end
    
    -- Test chat tabs
    AzeriteMOP:Debug("  Chat Tab Visibility Test:")
    for i = 1, 5 do
        local chatTab = _G["ChatFrame" .. i .. "Tab"]
        if chatTab then
            AzeriteMOP:Debug("    ChatFrame" .. i .. "Tab: " .. tostring(chatTab:IsShown()))
        else
            AzeriteMOP:Debug("    ChatFrame" .. i .. "Tab: Not found")
        end
    end
    
    -- Scan for all visible frames
    self:ScanVisibleFrames()
end 