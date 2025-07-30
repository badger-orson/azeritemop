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
        self:DisableExplorerMode()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended, check if we should enable explorer mode
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
            -- AzeriteMOP:Debug("ExplorerMode: Combat detected, disabling explorer mode")
            self:DisableExplorerMode()
        end
        return
    end
    
    -- Try to get current player position
    local mapID = C_Map.GetBestMapForUnit("player")
    local position = nil
    
    if mapID then
        position = C_Map.GetPlayerMapPosition(mapID, "player")
    end
    
    -- If we can't get position from map, use a simpler movement detection
    if not position then
        -- Use a time-based movement detection as fallback
        if not self.lastUpdateTime then
            self.lastUpdateTime = GetTime()
        end
        
        local currentTime = GetTime()
        local timeDiff = currentTime - self.lastUpdateTime
        
        -- If more than 1 second has passed, assume player might be moving
        if timeDiff > 1.0 then
            if not self.isMoving then
                self.isMoving = true
                self.stationaryTimer = 0
                self:EnableExplorerMode()
            end
        else
            if self.isMoving then
                self.isMoving = false
            end
            
            -- Increment stationary timer
            self.stationaryTimer = self.stationaryTimer + elapsed
            
            -- Check if we should disable explorer mode
            local delay = AzeriteMOP.db.explorerMode.stationaryDelay
            if self.stationaryTimer >= delay and self.isActive then
                self:DisableExplorerMode()
            end
        end
        
        self.lastUpdateTime = currentTime
        return
    end
    
    -- Calculate movement distance
    local dx = position.x - self.lastPosition.x
    local dy = position.y - self.lastPosition.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Check if player is moving
    local threshold = AzeriteMOP.db.explorerMode.movementThreshold
    local isMoving = distance > threshold
    
    -- Debug movement detection (uncomment for testing)
    if self.debugCounter == nil then
        self.debugCounter = 0
    end
    self.debugCounter = self.debugCounter + elapsed
    if self.debugCounter >= 5.0 then -- Debug every 5 seconds
        -- AzeriteMOP:Debug("ExplorerMode: Position " .. position.x .. ", " .. position.y .. " | Distance: " .. distance .. " | Moving: " .. tostring(isMoving))
        self.debugCounter = 0
    end
    
    if isMoving then
        -- Player is moving
        if not self.isMoving then
            self.isMoving = true
            self.stationaryTimer = 0
            -- AzeriteMOP:Debug("ExplorerMode: Player started moving, enabling explorer mode")
            self:EnableExplorerMode()
        end
    else
        -- Player is stationary
        if self.isMoving then
            self.isMoving = false
            -- AzeriteMOP:Debug("ExplorerMode: Player stopped moving")
        end
        
        -- Increment stationary timer
        self.stationaryTimer = self.stationaryTimer + elapsed
        
        -- Check if we should disable explorer mode
        local delay = AzeriteMOP.db.explorerMode.stationaryDelay
        if self.stationaryTimer >= delay and self.isActive then
            -- AzeriteMOP:Debug("ExplorerMode: Stationary delay reached, disabling explorer mode")
            self:DisableExplorerMode()
        end
    end
    
    -- Update last position
    self.lastPosition.x = position.x
    self.lastPosition.y = position.y
end

function ExplorerMode:StoreOriginalStates()
    -- Store original visibility states of UI elements
    self.hiddenFrames = {}
    
    -- Quest Log
    if QuestLogFrame then
        self.hiddenFrames.questLog = {
            frame = QuestLogFrame,
            originalShown = QuestLogFrame:IsShown()
        }
    end
    
    -- Chat Frame
    if ChatFrame1 then
        self.hiddenFrames.chatFrame = {
            frame = ChatFrame1,
            originalShown = ChatFrame1:IsShown()
        }
    end
    
    -- Minimap (optional)
    if AzeriteMOP.db.explorerMode.hideMinimap and MinimapCluster then
        self.hiddenFrames.minimap = {
            frame = MinimapCluster,
            originalShown = MinimapCluster:IsShown()
        }
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
    end
end

function ExplorerMode:EnableExplorerMode()
    if self.isActive then
        return
    end
    
    -- AzeriteMOP:Debug("Enabling Explorer Mode")
    self.isActive = true
    
    -- Hide quest log
    if AzeriteMOP.db.explorerMode.hideQuestLog and QuestLogFrame then
        QuestLogFrame:Hide()
        -- AzeriteMOP:Debug("ExplorerMode: Hidden QuestLogFrame")
    else
        -- AzeriteMOP:Debug("ExplorerMode: QuestLogFrame not found or hiding disabled")
    end
    
    -- Hide chat frame
    if AzeriteMOP.db.explorerMode.hideChatFrame and ChatFrame1 then
        ChatFrame1:Hide()
        -- AzeriteMOP:Debug("ExplorerMode: Hidden ChatFrame1")
    else
        -- AzeriteMOP:Debug("ExplorerMode: ChatFrame1 not found or hiding disabled")
    end
    
    -- Hide minimap (optional)
    if AzeriteMOP.db.explorerMode.hideMinimap and MinimapCluster then
        MinimapCluster:Hide()
        -- AzeriteMOP:Debug("ExplorerMode: Hidden MinimapCluster")
    end
    
    -- Hide action bars (optional)
    if AzeriteMOP.db.explorerMode.hideActionBars then
        for i = 1, 10 do
            local actionBar = _G["ActionButton" .. i]
            if actionBar then
                actionBar:Hide()
            end
        end
        -- AzeriteMOP:Debug("ExplorerMode: Hidden action bars")
    end
end

function ExplorerMode:DisableExplorerMode()
    if not self.isActive then
        return
    end
    
    -- AzeriteMOP:Debug("Disabling Explorer Mode")
    self.isActive = false
    
    -- Show quest log
    if AzeriteMOP.db.explorerMode.hideQuestLog and QuestLogFrame then
        QuestLogFrame:Show()
        -- AzeriteMOP:Debug("ExplorerMode: Shown QuestLogFrame")
    end
    
    -- Show chat frame
    if AzeriteMOP.db.explorerMode.hideChatFrame and ChatFrame1 then
        ChatFrame1:Show()
        -- AzeriteMOP:Debug("ExplorerMode: Shown ChatFrame1")
    end
    
    -- Show minimap (optional)
    if AzeriteMOP.db.explorerMode.hideMinimap and MinimapCluster then
        MinimapCluster:Show()
        -- AzeriteMOP:Debug("ExplorerMode: Shown MinimapCluster")
    end
    
    -- Show action bars (optional)
    if AzeriteMOP.db.explorerMode.hideActionBars then
        for i = 1, 10 do
            local actionBar = _G["ActionButton" .. i]
            if actionBar then
                actionBar:Show()
            end
        end
        -- AzeriteMOP:Debug("ExplorerMode: Shown action bars")
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
end 