-- AzeriteMOP Player Frame Module
-- Recreates the Azerite UI player frame for MoP Classic

local ADDON_NAME, Addon = ...
local AzeriteMOP = Addon.AzeriteMOP

-- Create PlayerFrame module
AzeriteMOP.PlayerFrame = {}
local PlayerFrame = AzeriteMOP.PlayerFrame

-- Constants for MoP Classic
local PLAYER_FRAME_WIDTH = 100
local PLAYER_FRAME_HEIGHT = 60
local HEALTH_BAR_HEIGHT = 28
local POWER_BAR_HEIGHT = 14

function PlayerFrame:Initialize()
    -- AzeriteMOP:Debug("Initializing Player Frame...")
    
    -- Create our custom player frame first
    self:CreatePlayerFrame()
    
    -- Set up events
    self:RegisterEvents()
    
    -- Set up periodic updates to ensure bars work properly
    self:SetupPeriodicUpdates()
    
    -- Try to hide default Blizzard player frame (optional)
    -- This might fail if the default UI isn't loaded yet, which is okay
    pcall(function()
        self:HideBlizzardFrame()
    end)
    
    -- AzeriteMOP:Debug("Player Frame initialized!")
end

function PlayerFrame:HideBlizzardFrame()
    -- Hide the default player frame in MoP Classic
    -- Note: In MoP Classic, the default UI might not be available or might have different names
    
    -- Try to hide the main player frame
    if _G["PlayerFrame"] then
        local frame = _G["PlayerFrame"]
        if frame.UnregisterAllEvents then
            frame:UnregisterAllEvents()
        end
        frame:Hide()
        frame:SetParent(CreateFrame("Frame"))
        -- AzeriteMOP:Debug("Hidden default PlayerFrame")
    else
        -- AzeriteMOP:Debug("Default PlayerFrame not found - this is normal in some cases")
    end
    
    -- Try to hide related frames if they exist
    local relatedFrames = {"PlayerName", "PlayerFrameHealthBar", "PlayerFrameManaBar"}
    for _, frameName in ipairs(relatedFrames) do
        if _G[frameName] then
            _G[frameName]:Hide()
            -- AzeriteMOP:Debug("Hidden " .. frameName)
        end
    end
end

function PlayerFrame:CreatePlayerFrame()
    -- Main container frame
    self.frame = CreateFrame("Frame", "AzeriteMOPPlayerFrame", UIParent)
    self.frame:SetSize(PLAYER_FRAME_WIDTH, PLAYER_FRAME_HEIGHT)
    
    -- Position from saved variables or default
    local pos = AzeriteMOP.db.playerFrame.position
    if pos and pos[1] then
        self.frame:SetPoint(pos[1], UIParent, pos[3] or "CENTER", pos[4] or 0, pos[5] or -150)
    else
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    end
    self.frame:SetScale(AzeriteMOP.db.playerFrame.scale or 1.0)
    
    -- Make it movable (for testing/positioning) - respect locked state
    local isLocked = AzeriteMOP.db.playerFrame.locked
    self.frame:SetMovable(not isLocked)
    self.frame:EnableMouse(not isLocked)
    
    -- Add drag functionality
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", function(frame)
        if not AzeriteMOP.db.playerFrame.locked then
            frame:StartMoving()
        end
    end)
    self.frame:SetScript("OnDragStop", function(frame)
        if not AzeriteMOP.db.playerFrame.locked then
            frame:StopMovingOrSizing()
            -- Save new position
            local point, _, relativePoint, x, y = frame:GetPoint()
            AzeriteMOP.db.playerFrame.position = {point, "UIParent", relativePoint, x, y}
        end
    end)
    
    -- Background
    self.bg = self.frame:CreateTexture(nil, "BACKGROUND")
    self.bg:SetAllPoints()
    self.bg:SetTexture(0, 0, 0, 0.3) -- Semi-transparent background for now
    
    -- Health Bar
    self:CreateHealthBar()
    
    -- Secondary Resource Bar (Chi, Combo Points, etc.)
    self:CreateSecondaryResourceBar()
    
    -- Power Bar (Mana/Energy/etc)
    self:CreatePowerBar()
    
    -- Player Name
    self:CreateNameText()
    
    -- Level and Class Text
    self:CreateLevelText()
end

function PlayerFrame:CreateHealthBar()
    -- Health bar background using custom texture - made 200% bigger
    self.healthBG = CreateFrame("Frame", nil, self.frame)
    self.healthBG:SetPoint("TOPLEFT", 5, -8)
    self.healthBG:SetSize((220) * 2, (58) * 2) -- Made 200% bigger
    self.healthBG:SetFrameLevel(30) -- Set very high frame level to appear on top of everything
    
    -- Use hp_mid_case.tga as the background frame
    local healthBGTex = self.healthBG:CreateTexture(nil, "BACKGROUND")
    healthBGTex:SetAllPoints()
    healthBGTex:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\hp_mid_case")
    
    
    -- Health bar using hp_cap_bar.tga - positioned inside the larger background
    self.healthBar = CreateFrame("StatusBar", nil, self.healthBG)
    self.healthBar:SetPoint("CENTER", 0, 0) -- Center it in the background
    self.healthBar:SetSize(235, 25) -- 25% longer, 2.5% thinner
    self.healthBar:SetFrameLevel(31) -- Set very high frame level to appear on top of everything
    self.healthBar:SetStatusBarTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\hp_cap_bar")
    self.healthBar:SetMinMaxValues(0, 100)
    self.healthBar:SetValue(100)
    
    -- Health bar color - will change based on health percentage
    self.healthBar:SetStatusBarColor(0.5, 0.0, 1.0) -- Purple when full
    
    -- Health text
    self.healthText = self.healthBar:CreateFontString(nil, "OVERLAY")
    self.healthText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.healthText:SetPoint("LEFT", 15,3)
    self.healthText:SetTextColor(1, 1, 1)
    self.healthText:SetText("100")
    
    -- Health bar glow effect - moved to HIGHEST layer
    self.healthGlow = self.frame:CreateTexture(nil, "OVERLAY") -- Changed to frame instead of healthBG
    self.healthGlow:SetAllPoints(self.healthBar) -- Position relative to healthBG but on frame layer
    self.healthGlow:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\hp_mid_case_glow")
    self.healthGlow:SetBlendMode("ADD")
    
    -- Debug: Check if glow texture loaded
    AzeriteMOP:Debug("Health glow texture loaded")
    
    -- Fallback if glow texture not found
    if not self.healthGlow:GetTexture() then
        AzeriteMOP:Debug("Health glow texture not found, using fallback")
        self.healthGlow:SetColorTexture(1.0, 0.0, 0.0, 0.3) -- Red glow fallback
    end
    
    -- Health bar is complete with background and glow
end

function PlayerFrame:CreateSecondaryResourceBar()
    -- Secondary resource bar (Chi, Combo Points, Holy Power, etc.)
    self.secondaryResourceBG = CreateFrame("Frame", nil, self.frame)
    self.secondaryResourceBG:SetPoint("CENTER", self.healthBar, "BOTTOM", 0, -15) -- Position centered under health bar
    self.secondaryResourceBG:SetSize(200, 15) -- Width matches health bar, height for segments
    
    -- Background texture
    self.secondaryResourceBack = self.secondaryResourceBG:CreateTexture(nil, "BACKGROUND")
    self.secondaryResourceBack:SetAllPoints()
    self.secondaryResourceBack:SetColorTexture(0.1, 0.1, 0.1, 0.8) -- Dark background
    
    -- Create segmented bar container
    self.segmentsContainer = CreateFrame("Frame", nil, self.secondaryResourceBG)
    self.segmentsContainer:SetPoint("CENTER", 0, 0)
    self.segmentsContainer:SetSize(180, 10) -- Adjusted for proper spacing (6 segments * 30px with gaps)
    
    -- Initialize segments
    self.segments = {}
    self.maxSegments = 6 -- Default max segments (Chi can go up to 6)
    self.currentSegments = 0
    
    -- Create individual segments
    for i = 1, self.maxSegments do
        local segment = CreateFrame("StatusBar", nil, self.segmentsContainer)
        segment:SetSize(20, 8) -- Each segment is 20 wide
        segment:SetPoint("LEFT", (i-1) * 30, 0) -- Position segments with 10px gaps (30 - 20 = 10px gap)
        segment:SetStatusBarTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\bar-progress")
        segment:SetStatusBarColor(1.0, 0.8, 0.0, 1.0) -- Gold color for Chi
        segment:SetMinMaxValues(0, 1)
        segment:SetValue(0) -- Start empty
        segment:Show() -- Always show segments
        
        self.segments[i] = segment
    end
    
    -- Secondary resource text
    self.secondaryResourceText = self.frame:CreateFontString(nil, "OVERLAY")
    self.secondaryResourceText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    self.secondaryResourceText:SetPoint("CENTER", self.secondaryResourceBG, "TOP", 0, 5) -- Position above the bar
    self.secondaryResourceText:SetTextColor(1, 1, 1)
    self.secondaryResourceText:SetText("")
    
    -- Initially hide the secondary resource bar
    self.secondaryResourceBG:Hide()
end

function PlayerFrame:CreatePowerBar()
    -- Power bar background with crystal frame
    self.powerBG = CreateFrame("Frame", nil, self.frame)
    self.powerBG:SetPoint("RIGHT", self.healthBG, "LEFT", 127, 45) -- Position touching the health bar on the left
    self.powerBG:SetSize(100* 1.4, 100 * 1.4) -- Width at 100%, height tripled
    
    -- Crystal back texture (empty crystal) - the power bar background
    self.crystalBack = self.powerBG:CreateTexture(nil, "BACKGROUND")
    self.crystalBack:SetAllPoints()
    self.crystalBack:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\power_crystal_back")
    
    -- Power bar using crystal front texture - this IS the crystal
    self.powerBar = CreateFrame("StatusBar", nil, self.powerBG)
    self.powerBar:SetAllPoints()
    self.powerBar:SetStatusBarTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\power_crystal_front")
    self.powerBar:SetOrientation("VERTICAL") -- Drain from top to bottom
    self.powerBar:SetMinMaxValues(0, 100)
    self.powerBar:SetValue(100)
    self.powerBar:SetFrameLevel(10) -- Set lower frame level so case appears on top
    
    -- Power bar color - gold
    self.powerBar:SetStatusBarColor(1.0, 0.8, 0.0, 1.0) -- Gold
    
    -- Power text
    self.powerText = self.powerBar:CreateFontString(nil, "OVERLAY")
    self.powerText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    self.powerText:SetPoint("CENTER", 0,-10)
    self.powerText:SetTextColor(1, 1, 1)
    self.powerText:SetText("100")
    
    -- --Crystal glow effect
    -- self.crystalGlow = self.powerBG:CreateTexture(nil, "OVERLAY")
    -- self.crystalGlow:SetAllPoints()
    -- self.crystalGlow:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\power_crystal_glow")
    -- self.crystalGlow:SetBlendMode("ADD")
    -- -- self.crystalGlow:SetFrameLevel(12)
    -- self.crystalGlow:SetVertexColor(1.0, 0.8, 0.0, 1.0) -- Darker red glow color

    -- Crystal case texture - positioned at the bottom of the crystal
    self.crystalCase = self.powerBG:CreateTexture(nil, "OVERLAY")
    self.crystalCase:SetPoint("BOTTOM", 0, -16) -- Position at the bottom of the power bar
    self.crystalCase:SetSize(50, 60) -- Size to cover the bottom portion of the crystal
    self.crystalCase:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\pw_crystal_case")
    -- Note: Textures don't have SetFrameLevel, they inherit from their parent frame
    
    -- Create a separate frame for the case to control its frame level
    self.crystalCaseFrame = CreateFrame("Frame", nil, self.powerBG)
    self.crystalCaseFrame:SetPoint("BOTTOM", 0, -14)
    self.crystalCaseFrame:SetSize(130, 70)
    self.crystalCaseFrame:SetFrameLevel(20) -- Set higher frame level to appear on top
    
    -- Move the case texture to the new frame
    self.crystalCase:SetParent(self.crystalCaseFrame)
    self.crystalCase:SetAllPoints()
    
end

-- Crystal shape function removed - now using custom textures

function PlayerFrame:CreateNameText()
    self.nameText = self.healthBar:CreateFontString(nil, "OVERLAY") -- Create on healthBar instead of frame
    self.nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    self.nameText:SetPoint("CENTER", 0, 40) -- Center on health bar
    self.nameText:SetTextColor(1, 1, 1)
    self.nameText:SetText(UnitName("player"))
end

function PlayerFrame:CreateLevelText()
    -- Create a background frame for the level
    self.levelBG = CreateFrame("Frame", nil, self.frame)
    self.levelBG:SetSize(80, 80) -- Circular background
    self.levelBG:SetPoint("BOTTOMLEFT", self.healthBar, "BOTTOMLEFT", -20, 20)
    self.levelBG:SetFrameLevel(10) -- Set high frame level to appear in front
    
    -- Create background using point_plate.tga texture
    self.levelBGTex = self.levelBG:CreateTexture(nil, "BACKGROUND")
    self.levelBGTex:SetAllPoints()
    self.levelBGTex:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\point_plate")
    
    -- Create level text on top
    self.levelText = self.levelBG:CreateFontString(nil, "OVERLAY")
    self.levelText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.levelText:SetPoint("CENTER", 0, 0) -- Center in the background
    self.levelText:SetTextColor(0, 1, 0) -- Purple
    
    self.levelText:SetText(UnitLevel("player"))
end

function PlayerFrame:SetupPeriodicUpdates()
    -- Create a timer to update bars periodically
    self.updateTimer = CreateFrame("Frame")
    self.updateTimer:SetScript("OnUpdate", function(frame, elapsed)
        frame.timeSinceLastUpdate = (frame.timeSinceLastUpdate or 0) + elapsed
        if frame.timeSinceLastUpdate >= 0.5 then -- Reduced to 0.5 seconds for less interference
            frame.timeSinceLastUpdate = 0
            -- Always update - periodic updates should run regardless of frame state
            -- AzeriteMOP:Debug("Periodic update running - updating health, power, and secondary resource")
            PlayerFrame:UpdateHealth()
            PlayerFrame:UpdatePower()
            PlayerFrame:UpdateSecondaryResource()
        end
    end)
end

function PlayerFrame:RegisterEvents()
    -- Register all necessary events for tracking player state
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterEvent("PLAYER_LEVEL_UP")
    self.frame:RegisterEvent("UNIT_HEALTH")
    self.frame:RegisterEvent("UNIT_MAXHEALTH")
    self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.frame:RegisterEvent("UNIT_NAME_UPDATE")
    
    -- Set event handler
    self.frame:SetScript("OnEvent", function(frame, event, ...)
        PlayerFrame:OnEvent(event, ...)
    end)
end

function PlayerFrame:OnEvent(event, unit, ...)
    -- AzeriteMOP:Debug("PlayerFrame event received: " .. event .. " for unit: " .. (unit or "nil"))
    
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        self:UpdateAll()
    elseif event == "PLAYER_LEVEL_UP" then
        self:UpdateLevel()
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        if unit == "player" then
            self:UpdateHealth()
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- Update secondary resource when target changes (for combo points)
        -- AzeriteMOP:Debug("Target changed, updating secondary resource")
        self:UpdateSecondaryResource()
    elseif event == "UNIT_NAME_UPDATE" then
        if unit == "player" then
            self:UpdateName()
        end
    end
end

function PlayerFrame:UpdateAll()
    self:UpdateHealth()
    self:UpdatePower()
    self:UpdateSecondaryResource()
    self:UpdateLevel()
    self:UpdateName()
end

function PlayerFrame:UpdateHealth()
    if not UnitExists("player") then 
        return 
    end
    
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    
    if maxHealth and maxHealth > 0 then
        self.healthBar:SetMinMaxValues(0, maxHealth)
        self.healthBar:SetValue(health)
        
        -- Update health text - show only remaining amount
        if health >= 1000000 then
            self.healthText:SetText(string.format("%.1fM", health/1000000))
        elseif health >= 1000 then
            self.healthText:SetText(string.format("%.1fk", health/1000))
        else
            self.healthText:SetText(health)
        end
        
        -- Keep health bar purple
        self.healthBar:SetStatusBarColor(0.5, 0.0, 1.0) -- Purple
    end
end

function PlayerFrame:UpdatePower()
    if not UnitExists("player") then 
        return 
    end
    
    -- Get current power values
    local powerType = UnitPowerType("player")
    local power = UnitPower("player", powerType)
    local maxPower = UnitPowerMax("player", powerType)
    
    -- AzeriteMOP:Debug("Power type detected: " .. powerType .. " (0=Manic, 1=Rage, 2=Focus, 3=Energy, 6=Runic Power)")
    
    -- AzeriteMOP:Debug("UpdatePower called - power: " .. power .. ", maxPower: " .. maxPower .. ", powerType: " .. powerType)
    
    -- Debug: Check if power bar exists
    if not self.powerBar then
        -- AzeriteMOP:Debug("ERROR: powerBar is nil!")
        return
    end
    
    if maxPower and maxPower > 0 then
        -- AzeriteMOP:Debug("Setting power bar values - power: " .. power .. ", maxPower: " .. maxPower)
        self.powerBar:SetMinMaxValues(0, maxPower)
        self.powerBar:SetValue(power)
        
        -- Update power text with proper formatting
        -- Update power text - show only remaining amount
        if power >= 1000000 then
            self.powerText:SetText(string.format("%.1fM", power/1000000))
        elseif power >= 1000 then
            self.powerText:SetText(string.format("%.1fk", power/1000))
        else
            self.powerText:SetText(power)
        end
        
        -- Keep power bar gold
        self.powerBar:SetStatusBarColor(1.0, 0.8, 0.0, 1.0) -- Gold
    end
end

function PlayerFrame:UpdateLevel()
    local level = UnitLevel("player")
    if level then
        self.levelText:SetText(level)
    end
end

function PlayerFrame:UpdateName()
    local name = UnitName("player")
    if name then
        self.nameText:SetText(name)
    end
end

function PlayerFrame:UpdateSecondaryResource()
    local class = select(2, UnitClass("player"))
    local current, max = 0, 0
    local resourceType = ""
    
    -- AzeriteMOP:Debug("UpdateSecondaryResource called for class: " .. class)
    
    -- Check for different secondary resources based on class
    if class == "MONK" then
        -- Chi for Monks - try different power types
        current = UnitPower("player", 12) -- Chi power type
        max = UnitPowerMax("player", 12)
        resourceType = "Chi"
        -- AzeriteMOP:Debug("MONK Chi (power type 12) - current: " .. current .. ", max: " .. max)
        
        -- If power type 12 doesn't work, try power type 0 (alternate resource)
        if current == 0 and max == 0 then
            current = UnitPower("player", 0)
            max = UnitPowerMax("player", 0)
            -- AzeriteMOP:Debug("MONK Chi (power type 0) - current: " .. current .. ", max: " .. max)
        end
    elseif class == "ROGUE" then
        -- Combo Points for Rogues
        current = GetComboPoints("player", "target")
        max = 5 -- Combo points max is 5
        resourceType = "Combo"
    elseif class == "PALADIN" then
        -- Holy Power for Paladins
        current = UnitPower("player", 9) -- Holy Power
        max = UnitPowerMax("player", 9)
        resourceType = "Holy"
    elseif class == "WARRIOR" then
        -- Rage for Warriors (if you want to track it separately)
        current = UnitPower("player", 1) -- Rage
        max = UnitPowerMax("player", 1)
        resourceType = "Rage"
    elseif class == "DEATHKNIGHT" then
        -- Runic Power for Death Knights
        current = UnitPower("player", 6) -- Runic Power
        max = UnitPowerMax("player", 6)
        resourceType = "Runic"
    end
    
    -- Always show secondary resource bar for classes that have secondary resources
    -- AzeriteMOP:Debug("Secondary resource check - current: " .. current .. ", max: " .. max .. ", resourceType: " .. resourceType)
    
    -- Show bar for classes with secondary resources, even when empty
    if class == "MONK" or class == "ROGUE" or class == "PALADIN" or class == "WARRIOR" or class == "DEATHKNIGHT" then
        -- AzeriteMOP:Debug("Showing secondary resource bar for " .. class)
        self.secondaryResourceBG:Show()
        
        -- Update segments - show all segments but only fill the ones we have
        for i = 1, self.maxSegments do
            self.segments[i]:Show() -- Always show all segments
            if i <= current then
                self.segments[i]:SetValue(1) -- Fill the ones we have
            else
                self.segments[i]:SetValue(0.1) -- Set to very low value instead of 0 to ensure visibility
            end
        end
        
        -- Update text - show current/max even when empty
        if max > 0 then
            self.secondaryResourceText:SetText(resourceType .. ": " .. current .. "/" .. max)
        else
            self.secondaryResourceText:SetText(resourceType .. ": 0/0")
        end
        
        -- Set text color to class color
        local classColor = RAID_CLASS_COLORS[class]
        if classColor then
            self.secondaryResourceText:SetTextColor(classColor.r, classColor.g, classColor.b)
        else
            self.secondaryResourceText:SetTextColor(1, 1, 1) -- Fallback to white
        end
        
        -- Use class colors for the bar segments
        local classColor = RAID_CLASS_COLORS[class]
        if classColor then
            -- Apply class color to all segments (filled and empty)
            for i = 1, self.maxSegments do
                if i <= current then
                    self.segments[i]:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1.0) -- Bright class color for filled
                else
                    self.segments[i]:SetStatusBarColor(1.0, 1.0, 1.0, 1.0) -- Solid white lines for empty segments
                end
            end
        else
            -- Fallback to default colors if class color not found
            local r, g, b = 1.0, 0.8, 0.0 -- Default gold
            for i = 1, self.maxSegments do
                if i <= current then
                    self.segments[i]:SetStatusBarColor(r, g, b, 1.0) -- Bright color for filled
                else
                    self.segments[i]:SetStatusBarColor(1.0, 1.0, 1.0, 1.0) -- Solid white lines for empty segments
                end
            end
        end
    else
        -- Hide secondary resource bar for classes without secondary resources
        -- AzeriteMOP:Debug("Hiding secondary resource bar - no secondary resource for " .. class)
        self.secondaryResourceBG:Hide()
    end
end

-- Function to scale fonts independently
function PlayerFrame:ScaleFonts(scale)
    if not scale or scale < 0.5 or scale > 3.0 then
        -- AzeriteMOP:Debug("Invalid font scale value: " .. tostring(scale) .. ", using 1.0")
        scale = 1.0
    end
    
    -- AzeriteMOP:Debug("Applying font scaling to player frame: " .. scale)
    
    -- Scale font sizes with bounds
    local function scaleFont(fontString, baseSize)
        if fontString then
            local scaledSize = math.max(6, math.min(30, baseSize * scale)) -- Min 6, Max 30
            -- AzeriteMOP:Debug("Scaling font from " .. baseSize .. " to " .. scaledSize)
            fontString:SetFont("Fonts\\FRIZQT__.TTF", scaledSize, "OUTLINE")
        else
            -- AzeriteMOP:Debug("Font string is nil, cannot scale")
        end
    end
    
    -- AzeriteMOP:Debug("Player frame font elements exist - healthText: " .. tostring(self.healthText ~= nil))
    -- AzeriteMOP:Debug("Player frame font elements exist - nameText: " .. tostring(self.nameText ~= nil))
    -- AzeriteMOP:Debug("Player frame font elements exist - levelText: " .. tostring(self.levelText ~= nil))
    -- AzeriteMOP:Debug("Player frame font elements exist - powerText: " .. tostring(self.powerText ~= nil))
    
    scaleFont(self.healthText, 12)
    scaleFont(self.nameText, 14)
    scaleFont(self.levelText, 12)
    scaleFont(self.powerText, 10)
    scaleFont(self.secondaryResourceText, 10)
    
    -- AzeriteMOP:Debug("Player frame font scaling applied successfully")
end

-- Function to reset fonts to default sizes
function PlayerFrame:ResetFonts()
    -- AzeriteMOP:Debug("Resetting player frame fonts to default sizes")
    
    if self.healthText then
        self.healthText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    end
    if self.nameText then
        self.nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    end
    if self.levelText then
        self.levelText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    end
    if self.powerText then
        self.powerText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    end
    if self.secondaryResourceText then
        self.secondaryResourceText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    end
    
    -- AzeriteMOP:Debug("Player frame fonts reset to default")
end