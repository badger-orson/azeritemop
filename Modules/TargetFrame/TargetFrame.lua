-- AzeriteMOP Target Frame Module
-- Recreates the Azerite UI target frame for MoP Classic

local ADDON_NAME, Addon = ...
local AzeriteMOP = Addon.AzeriteMOP

-- Create TargetFrame module
AzeriteMOP.TargetFrame = {}
local TargetFrame = AzeriteMOP.TargetFrame

-- Constants for MoP Classic
local TARGET_FRAME_WIDTH = 100
local TARGET_FRAME_HEIGHT = 60
local HEALTH_BAR_HEIGHT = 28
local POWER_BAR_HEIGHT = 14

-- Store original sizes for scaling
TargetFrame.originalSizes = {}

-- Ensure database exists immediately when module loads
if AzeriteMOP then
    if not AzeriteMOP.db then
        AzeriteMOP.db = {}
    end
    if not AzeriteMOP.db.targetFrame then
        AzeriteMOP.db.targetFrame = {
            enabled = true,
            position = { "CENTER", UIParent, "CENTER", 0, 150 },
            scale = 1.0,
            locked = false
        }
    end
    -- AzeriteMOP:Debug("TargetFrame module: Database initialized - targetFrame exists: " .. tostring(AzeriteMOP.db.targetFrame ~= nil))
end

function TargetFrame:Initialize()
    -- AzeriteMOP:Debug("Initializing Target Frame...")
    
    -- Ensure database is available
    if not AzeriteMOP.db then
        -- AzeriteMOP:Debug("Initialize: Creating AzeriteMOP.db")
        AzeriteMOP.db = {}
    end
    
    if not AzeriteMOP.db.targetFrame then
        -- AzeriteMOP:Debug("Initialize: Creating targetFrame in database")
        AzeriteMOP.db.targetFrame = {
            enabled = true,
            position = { "CENTER", UIParent, "CENTER", 0, 150 },
            scale = 1.0,
            locked = false
        }
    end
    
    -- Create our custom target frame first
    self:CreateTargetFrame()
    
    -- Set up events
    self:RegisterEvents()
    
    -- Set up periodic updates to ensure bars work properly
    self:SetupPeriodicUpdates()
    
    -- Try to hide default Blizzard target frame (optional)
    pcall(function()
        self:HideBlizzardFrame()
    end)
    
    -- AzeriteMOP:Debug("Target Frame initialized!")
    -- AzeriteMOP:Debug("TargetFrame module loaded successfully")
end

-- Function to apply scaling to all child elements
function TargetFrame:ApplyScaling(scale)
    if not self.frame then 
        AzeriteMOP:Debug("Target frame not found, cannot apply scaling")
        return 
    end
    
    -- Validate scale value
    if not scale or scale < 0.1 or scale > 3.0 then
        AzeriteMOP:Debug("Invalid scale value: " .. tostring(scale) .. ", using 1.0")
        scale = 1.0
    end
    
    -- AzeriteMOP:Debug("Applying scaling to target frame: " .. scale)
    
    -- Apply scale to main frame only (no font scaling)
    self.frame:SetScale(scale)
    
    -- AzeriteMOP:Debug("Target frame scaling applied successfully")
end

-- Debug function to test scaling
function TargetFrame:TestScaling()
    AzeriteMOP:Debug("Testing target frame scaling...")
    self:ApplyScaling(1.5)
    AzeriteMOP:Debug("Applied 1.5x scaling for testing")
end

-- Function to scale fonts independently
function TargetFrame:ScaleFonts(scale)
    if not scale or scale < 0.5 or scale > 3.0 then
        AzeriteMOP:Debug("Invalid font scale value: " .. tostring(scale) .. ", using 1.0")
        scale = 1.0
    end
    
    AzeriteMOP:Debug("Applying font scaling to target frame: " .. scale)
    
    -- Scale font sizes with bounds
    local function scaleFont(fontString, baseSize)
        if fontString then
            local scaledSize = math.max(6, math.min(30, baseSize * scale)) -- Min 6, Max 30
            AzeriteMOP:Debug("Scaling font from " .. baseSize .. " to " .. scaledSize)
            fontString:SetFont("Fonts\\FRIZQT__.TTF", scaledSize, "OUTLINE")
        else
            AzeriteMOP:Debug("Font string is nil, cannot scale")
        end
    end
    
    AzeriteMOP:Debug("Target frame font elements exist - healthText: " .. tostring(self.healthText ~= nil))
    AzeriteMOP:Debug("Target frame font elements exist - nameText: " .. tostring(self.nameText ~= nil))
    AzeriteMOP:Debug("Target frame font elements exist - levelText: " .. tostring(self.levelText ~= nil))
    AzeriteMOP:Debug("Target frame font elements exist - powerText: " .. tostring(self.powerText ~= nil))
    
    scaleFont(self.healthText, 12)
    scaleFont(self.nameText, 14)
    scaleFont(self.levelText, 12)
    scaleFont(self.powerText, 10)
    
    AzeriteMOP:Debug("Target frame font scaling applied successfully")
end

-- Function to reset fonts to default sizes
function TargetFrame:ResetFonts()
    AzeriteMOP:Debug("Resetting target frame fonts to default sizes")
    
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
    
    AzeriteMOP:Debug("Target frame fonts reset to default")
end

-- Function to update textures based on settings
function TargetFrame:UpdateTextures()
    -- Target frame uses custom Azerite textures that are part of its unique design
    -- We preserve these instead of overriding them with the texture system
    -- The custom textures are:
    -- - hp_lowmid_bar_flipped.tga for health bar
    -- - hp_mid_case.tga for health background (mirrored)
    -- - hp_mid_case_glow.tga for health glow
    -- - portrait_frame_hi.tga for portrait frame
    -- This maintains the unique Azerite UI aesthetic
    
    -- Only update cast bar texture since it's not part of the core design
    if AzeriteMOP.db.textures and self.castBar then
        local castTexture = AzeriteMOP:GetTexture("castBar")
        if castTexture and castTexture ~= "Interface\\TargetingFrame\\UI-StatusBar" then
            self.castBar:SetStatusBarTexture(castTexture)
        end
    end
end

-- Function to update colors based on settings
function TargetFrame:UpdateColors()
    if not AzeriteMOP.db.colors or not self.frame or not UnitExists("target") then
        return
    end
    
    -- Determine target reaction
    local reaction = UnitReaction("target", "player")
    local colorKey = "targetHealthNeutral"
    
    if UnitIsFriend("target", "player") then
        colorKey = "targetHealthFriendly"
    elseif UnitIsEnemy("target", "player") then
        colorKey = "targetHealthHostile"
    end
    
    -- Check for class colors
    if AzeriteMOP.db.colors.useClassColors and UnitIsPlayer("target") then
        local _, class = UnitClass("target")
        if class and CLASS_COLORS[class] then
            local color = CLASS_COLORS[class]
            self.healthBar:SetStatusBarColor(color[1], color[2], color[3])
        else
            local hr, hg, hb = AzeriteMOP:GetColor(colorKey)
            self.healthBar:SetStatusBarColor(hr, hg, hb)
        end
    else
        local hr, hg, hb = AzeriteMOP:GetColor(colorKey)
        self.healthBar:SetStatusBarColor(hr, hg, hb)
    end
    
    -- Health background texture should not be tinted - use original texture colors
    if self.healthBGTex then
        self.healthBGTex:SetVertexColor(1, 1, 1, 1)  -- No tint, full opacity
    end
    
    -- Target frame doesn't have a traditional power bar, it uses a portrait instead
    -- So we skip power bar color updates for target frame
    
    -- Update text colors
    local tr, tg, tb = AzeriteMOP:GetColor("targetText")
    self.healthText:SetTextColor(tr, tg, tb)
    self.powerText:SetTextColor(tr, tg, tb)
    self.nameText:SetTextColor(tr, tg, tb)
    
    -- Update level text color
    local lr, lg, lb = AzeriteMOP:GetColor("targetLevelText")
    self.levelText:SetTextColor(lr, lg, lb)
    
    -- Update cast bar colors if casting
    if self.castBar and self.castBar:IsShown() then
        local casting = UnitCastingInfo("target")
        local channeling = UnitChannelInfo("target")
        
        if channeling then
            local cr, cg, cb = AzeriteMOP:GetColor("castBarChannel")
            self.castBar:SetStatusBarColor(cr, cg, cb)
        else
            local cr, cg, cb = AzeriteMOP:GetColor("castBarNormal")
            self.castBar:SetStatusBarColor(cr, cg, cb)
        end
        
        -- Update cast bar background
        local cbr, cbg, cbb = AzeriteMOP:GetColor("castBarBg")
        if self.castBarBG then
            self.castBarBG:SetVertexColor(cbr, cbg, cbb)
        end
        
        -- Update cast text colors
        local ctr, ctg, ctb = AzeriteMOP:GetColor("castBarText")
        self.castText:SetTextColor(ctr, ctg, ctb)
        
        local ctr2, ctg2, ctb2 = AzeriteMOP:GetColor("castBarTimeText")
        self.castTime:SetTextColor(ctr2, ctg2, ctb2)
    end
end

-- Add class colors table if not defined
local CLASS_COLORS = {
    ["WARRIOR"] = {0.78, 0.61, 0.43},
    ["PALADIN"] = {0.96, 0.55, 0.73},
    ["HUNTER"] = {0.67, 0.83, 0.45},
    ["ROGUE"] = {1.00, 0.96, 0.41},
    ["PRIEST"] = {1.00, 1.00, 1.00},
    ["DEATHKNIGHT"] = {0.77, 0.12, 0.23},
    ["SHAMAN"] = {0.00, 0.44, 0.87},
    ["MAGE"] = {0.41, 0.80, 0.94},
    ["WARLOCK"] = {0.58, 0.51, 0.79},
    ["MONK"] = {0.00, 1.00, 0.59},
    ["DRUID"] = {1.00, 0.49, 0.04},
}

-- Function to update scaling from saved variables
function TargetFrame:UpdateScaling()
    -- AzeriteMOP:Debug("UpdateScaling called")
    
    -- Ensure database is available
    if not AzeriteMOP.db then
        -- AzeriteMOP:Debug("UpdateScaling: Creating AzeriteMOP.db")
        AzeriteMOP.db = {}
    end
    
    if not AzeriteMOP.db.targetFrame then
        -- AzeriteMOP:Debug("UpdateScaling: Creating targetFrame in database")
        AzeriteMOP.db.targetFrame = {
            enabled = true,
            position = { "CENTER", UIParent, "CENTER", 0, 150 },
            scale = 1.0,
            locked = false
        }
    end
    
    -- Use global scale if enabled, otherwise use individual scale
    local scale = AzeriteMOP.db.targetFrame.scale or 1.0
    if AzeriteMOP.db.global and AzeriteMOP.db.global.useGlobalScale then
        scale = AzeriteMOP.db.global.uiScale or 1.0
    end
    -- AzeriteMOP:Debug("Applying scale: " .. scale)
    self:ApplyScaling(scale)
end

function TargetFrame:HideBlizzardFrame()
    -- Hide the default target frame in MoP Classic
    
    -- Try to hide the main target frame
    if _G["TargetFrame"] then
        local frame = _G["TargetFrame"]
        if frame.UnregisterAllEvents then
            frame:UnregisterAllEvents()
        end
        frame:Hide()
        frame:SetParent(CreateFrame("Frame"))
        AzeriteMOP:Debug("Hidden default TargetFrame")
    else
        AzeriteMOP:Debug("Default TargetFrame not found - this is normal in some cases")
    end
    
    -- Try to hide related frames if they exist
    local relatedFrames = {"TargetName", "TargetFrameHealthBar", "TargetFrameManaBar"}
    for _, frameName in ipairs(relatedFrames) do
        if _G[frameName] then
            _G[frameName]:Hide()
            AzeriteMOP:Debug("Hidden " .. frameName)
        end
    end
end

function TargetFrame:CreateTargetFrame()
    -- Ensure database is available - create it if it doesn't exist
    AzeriteMOP:Debug("CreateTargetFrame: Checking database state")
    AzeriteMOP:Debug("CreateTargetFrame: AzeriteMOP.db exists: " .. tostring(AzeriteMOP.db ~= nil))
    
    if not AzeriteMOP.db then
        AzeriteMOP:Debug("CreateTargetFrame: Creating AzeriteMOP.db")
        AzeriteMOP.db = {}
    end
    
    AzeriteMOP:Debug("CreateTargetFrame: AzeriteMOP.db.targetFrame exists: " .. tostring(AzeriteMOP.db.targetFrame ~= nil))
    
    if not AzeriteMOP.db.targetFrame then
        AzeriteMOP:Debug("CreateTargetFrame: Creating targetFrame in database")
        AzeriteMOP.db.targetFrame = {
            enabled = true,
            position = { "CENTER", UIParent, "CENTER", 0, 150 },
            scale = 1.0,
            locked = false
        }
    end
    
    -- Main container frame
    self.frame = CreateFrame("Frame", "AzeriteMOPTargetFrame", UIParent)
    self.frame:SetSize(TARGET_FRAME_WIDTH, TARGET_FRAME_HEIGHT)
    
    -- Position from saved variables or default
    local pos = AzeriteMOP.db.targetFrame.position
    if pos and pos[1] then
        self.frame:SetPoint(pos[1], UIParent, pos[3] or "CENTER", pos[4] or 0, pos[5] or 150)
    else
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 150) -- Position above player frame
    end
    
    -- Apply scaling after all elements are created
    -- (We'll call UpdateScaling at the end of CreateTargetFrame)
    
    -- Make it movable (for testing/positioning) - respect locked state
    local isLocked = AzeriteMOP.db.targetFrame.locked
    self.frame:SetMovable(not isLocked)
    self.frame:EnableMouse(not isLocked)
    
    -- Add drag functionality
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", function(frame)
        if not AzeriteMOP.db.targetFrame.locked then
            frame:StartMoving()
        end
    end)
    self.frame:SetScript("OnDragStop", function(frame)
        if not AzeriteMOP.db.targetFrame.locked then
            frame:StopMovingOrSizing()
            -- Save new position
            local point, _, relativePoint, x, y = frame:GetPoint()
            AzeriteMOP.db.targetFrame.position = {point, "UIParent", relativePoint, x, y}
        end
    end)
    
    -- Background
    self.bg = self.frame:CreateTexture(nil, "BACKGROUND")
    self.bg:SetAllPoints()
    self.bg:SetTexture(0, 0, 0, 0.3) -- Semi-transparent background for now
    
    -- Health Bar
    self:CreateHealthBar()
    
    -- Power Bar (Mana/Energy/etc)
    self:CreatePowerBar()
    
    -- Target Name
    self:CreateNameText()
    
    -- Level and Class Text
    self:CreateLevelText()
    
    -- Cast Bar
    self:CreateCastBar()
    
    -- Initially hide the frame until we have a target
    self.frame:Hide()
    
    -- Apply scaling after all elements are created
    self:UpdateScaling()
end

function TargetFrame:CreateHealthBar()
    -- Health bar background using custom texture - made 200% bigger (mirrored)
    self.healthBG = CreateFrame("Frame", nil, self.frame)
    self.healthBG:SetPoint("TOPRIGHT", -5, -8) -- Mirrored to right side
    self.healthBG:SetSize((220) * 2, (28 + 30) * 2) -- Made 200% bigger
    self.healthBG:SetFrameLevel(30) -- Set very high frame level to appear on top of everything
    
    -- Health bar using hp_lowmid_bar.tga - positioned BEHIND the background
    self.healthBar = CreateFrame("StatusBar", nil, self.healthBG)
    self.healthBar:SetPoint("CENTER", 0, 0) -- Center it in the background
    self.healthBar:SetSize(235, 20) -- 25% longer, 2.5% thinner
    self.healthBar:SetFrameLevel(31) -- Set very high frame level to appear on top of everything
    self.healthBar:SetStatusBarTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\hp_lowmid_bar_flipped")
    
    self.healthBar:SetMinMaxValues(0, 100)
    self.healthBar:SetValue(100)
    
    -- Mirror the health bar texture horizontally (same as background)
    self.healthBar:GetStatusBarTexture():SetTexCoord(1, 0, 0, 1)
    
    -- Set the health bar to fill from right to left (so it empties from left to right)
    self.healthBar:SetReverseFill(true)
    
    -- Health bar color - will be set by UpdateColors()
    self.healthBar:SetStatusBarColor(1.0, 0.0, 0.0) -- Default red for hostile
    
    -- Use hp_mid_case.tga as the background frame (mirrored) - NOW ON TOP
    self.healthBGTex = self.healthBG:CreateTexture(nil, "OVERLAY")
    self.healthBGTex:SetAllPoints()
    self.healthBGTex:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\hp_mid_case")
    self.healthBGTex:SetTexCoord(1, 0, 0, 1) -- Mirror the background texture
    self.healthBGTex:SetVertexColor(1, 1, 1, 1)  -- No tint, use original texture colors
    
    -- Health text (mirrored position)
    self.healthText = self.healthBar:CreateFontString(nil, "OVERLAY")
    self.healthText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.healthText:SetPoint("RIGHT", -15, 3) -- Mirrored to right side
    self.healthText:SetTextColor(1, 1, 1)
    self.healthText:SetText("100")
    
    -- Health bar glow effect - moved to HIGHEST layer (mirrored)
    self.healthGlow = self.frame:CreateTexture(nil, "OVERLAY") -- Changed to frame instead of healthBG
    self.healthGlow:SetAllPoints(self.healthBar) -- Position relative to healthBG but on frame layer
    self.healthGlow:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\hp_mid_case_glow")
    self.healthGlow:SetBlendMode("ADD")
    self.healthGlow:SetTexCoord(1, 0, 0, 1) -- Mirror the glow texture
    
    -- Debug: Check if glow texture loaded
    AzeriteMOP:Debug("Target health glow texture loaded")
    
    -- Fallback if glow texture not found
    if not self.healthGlow:GetTexture() then
        AzeriteMOP:Debug("Target health glow texture not found, using fallback")
        self.healthGlow:SetColorTexture(1.0, 0.0, 0.0, 0.3) -- Red glow fallback
    end
    
    -- Health bar is complete with background and glow
end

function TargetFrame:CreatePowerBar()
    -- Portrait frame background
    self.portraitBG = CreateFrame("Frame", nil, self.frame)
    self.portraitBG:SetPoint("LEFT", self.healthBG, "RIGHT", -128, 10) -- Position touching the health bar on the right, moved left and down
    self.portraitBG:SetSize(100 * 1.4, 100 * 1.4) -- Width at 100%, height tripled
    
    -- Live portrait of the target (full circle) - behind the frame
    self.portrait = self.portraitBG:CreateTexture(nil, "BACKGROUND")
    self.portrait:SetPoint("CENTER", 0, 0)
    self.portrait:SetSize(85, 85) -- Full size to match the mask
    -- Use full circle cropping
    self.portrait:SetTexCoord(0, 1, 0, 1) -- Full circle
    
    -- Portrait frame background texture (glass effect on top)
    self.portraitFrame = self.portraitBG:CreateTexture(nil, "OVERLAY")
    self.portraitFrame:SetAllPoints()
    self.portraitFrame:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\portrait_frame_hi")
    
    -- Portrait glow effect (black)
    self.portraitGlow = self.portraitBG:CreateTexture(nil, "OVERLAY")
    self.portraitGlow:SetPoint("CENTER", 0, 0)
    self.portraitGlow:SetSize(100, 100)
    self.portraitGlow:SetColorTexture(0.0, 0.0, 0.0, 0.5) -- Black glow
    self.portraitGlow:SetBlendMode("ADD")
    
    -- Power text (moved to portrait area) - HIDDEN
    self.powerText = self.portraitBG:CreateFontString(nil, "OVERLAY")
    self.powerText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    self.powerText:SetPoint("CENTER", 0, -10)
    self.powerText:SetTextColor(1, 1, 1)
    self.powerText:SetText("") -- Empty text to hide it
end

function TargetFrame:CreateNameText()
    self.nameText = self.healthBar:CreateFontString(nil, "OVERLAY") -- Create on healthBar instead of frame
    self.nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    self.nameText:SetPoint("CENTER", 0, 40) -- Center on health bar
    self.nameText:SetTextColor(1, 1, 1)
    self.nameText:SetText("No Target")
end

function TargetFrame:CreateLevelText()
    -- Create a background frame for the level (mirrored to right side)
    self.levelBG = CreateFrame("Frame", nil, self.frame)
    self.levelBG:SetSize(80, 80) -- Circular background
    self.levelBG:SetPoint("BOTTOMRIGHT", self.healthBar, "BOTTOMRIGHT", 20, 20) -- Mirrored to right side
    self.levelBG:SetFrameLevel(10) -- Set high frame level to appear in front
    
    -- Create background using point_plate.tga texture
    self.levelBGTex = self.levelBG:CreateTexture(nil, "BACKGROUND")
    self.levelBGTex:SetAllPoints()
    self.levelBGTex:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\point_plate")
    
    -- Create level text on top
    self.levelText = self.levelBG:CreateFontString(nil, "OVERLAY")
    self.levelText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.levelText:SetPoint("CENTER", 0, 0) -- Center in the background
    self.levelText:SetTextColor(1, 0.5, 0) -- Orange for enemy
    
    self.levelText:SetText("??")
end

function TargetFrame:SetupPeriodicUpdates()
    -- Create a timer to update bars periodically
    self.updateTimer = CreateFrame("Frame")
    self.updateTimer:SetScript("OnUpdate", function(frame, elapsed)
        frame.timeSinceLastUpdate = (frame.timeSinceLastUpdate or 0) + elapsed
        if frame.timeSinceLastUpdate >= 0.5 then -- Reduced to 0.5 seconds for less interference
            frame.timeSinceLastUpdate = 0
            -- Only update if not currently dragging and database is initialized
            local shouldUpdate = true
            if self.frame:IsMovable() then
                shouldUpdate = false
            elseif AzeriteMOP.db and AzeriteMOP.db.targetFrame and AzeriteMOP.db.targetFrame.locked then
                shouldUpdate = true
            end
            
            if shouldUpdate then
                TargetFrame:UpdateTarget()
            end
        end
    end)
end

function TargetFrame:RegisterEvents()
    -- Register target-related events (only events that exist in MoP Classic)
    self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterEvent("UNIT_HEALTH")
    self.frame:RegisterEvent("UNIT_MAXHEALTH")
    self.frame:RegisterEvent("UNIT_LEVEL")
    self.frame:RegisterEvent("UNIT_NAME_UPDATE")
    
    -- Set event handler
    self.frame:SetScript("OnEvent", function(frame, event, ...)
        TargetFrame:OnEvent(event, ...)
    end)
end

function TargetFrame:OnEvent(event, unit, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        self:OnTargetChanged()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        self:OnTargetChanged()
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        if unit == "target" then
            self:UpdateHealth()
            self:UpdateColors()  -- Keep colors updated
        end
    elseif event == "UNIT_LEVEL" then
        if unit == "target" then
            self:UpdateLevel()
        end
    elseif event == "UNIT_NAME_UPDATE" then
        if unit == "target" then
            self:UpdateName()
        end
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        if unit == "target" then
            self:UpdateCastBar()
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_SUCCEEDED" or 
           event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or
           event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        if unit == "target" then
            self:UpdateCastBar()
        end
    end
end

function TargetFrame:OnTargetChanged()
    if UnitExists("target") then
        self.frame:Show()
        self:UpdateAll()
        -- Ensure scaling is applied when frame is shown
        self:UpdateScaling()
    else
        self.frame:Hide()
    end
end

function TargetFrame:UpdateAll()
    self:UpdateHealth()
    self:UpdatePower()
    self:UpdateLevel()
    self:UpdateName()
    self:UpdateColors()
    self:UpdateTextures()
end

function TargetFrame:UpdateHealth()
    if not UnitExists("target") then 
        return 
    end
    
    local health = UnitHealth("target")
    local maxHealth = UnitHealthMax("target")
    
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
        
        -- Don't override the color here - it's set in UpdateColors()
        
        -- Re-apply texture coordinates after status bar update (status bars reset texture coords)
        -- self.healthBar:GetStatusBarTexture():SetTexCoord(1, 0, 0, 1)
    end
end

function TargetFrame:UpdatePower()
    if not UnitExists("target") then 
        return 
    end
    
    -- Update portrait using SetPortraitTexture which should work in MoP Classic
    SetPortraitTexture(self.portrait, "target")
    
    -- Get current power values
    local powerType = UnitPowerType("target")
    local power = UnitPower("target", powerType)
    local maxPower = UnitPowerMax("target", powerType)
    
    if maxPower and maxPower > 0 then
        -- Update power text - show only current amount (but hidden)
        if power >= 1000000 then
            self.powerText:SetText(string.format("%.1fM", power/1000000))
        elseif power >= 1000 then
            self.powerText:SetText(string.format("%.1fk", power/1000))
        else
            self.powerText:SetText(power)
        end
        -- Hide the power text since user doesn't want to see it in portrait
        self.powerText:SetText("")
    else
        self.powerText:SetText("")
    end
end

function TargetFrame:UpdateLevel()
    if not UnitExists("target") then 
        return 
    end
    
    local level = UnitLevel("target")
    if level then
        if level == -1 then
            self.levelText:SetText("??") -- Boss level
        else
            self.levelText:SetText(level)
        end
    end
end

function TargetFrame:UpdateName()
    if not UnitExists("target") then 
        return 
    end
    
    local name = UnitName("target")
    if name then
        self.nameText:SetText(name)
    end
end

function TargetFrame:CreateCastBar()
    -- Cast bar container
    self.castBG = CreateFrame("Frame", nil, self.frame)
    self.castBG:SetPoint("TOP", self.healthBG, "BOTTOM", 0, -5)
    local width = AzeriteMOP.db.targetFrame and AzeriteMOP.db.targetFrame.castBarWidth or 200
    local height = AzeriteMOP.db.targetFrame and AzeriteMOP.db.targetFrame.castBarHeight or 20
    self.castBG:SetSize(width, height)
    
    -- Cast bar background
    self.castBarBG = self.castBG:CreateTexture(nil, "BACKGROUND")
    self.castBarBG:SetAllPoints()
    self.castBarBG:SetColorTexture(0, 0, 0, 0.7)
    
    -- Cast bar
    self.castBar = CreateFrame("StatusBar", nil, self.castBG)
    self.castBar:SetAllPoints()
    self.castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    self.castBar:SetMinMaxValues(0, 1)
    self.castBar:SetValue(0)
    self.castBar:Hide()
    
    -- Cast bar text (spell name)
    self.castText = self.castBar:CreateFontString(nil, "OVERLAY")
    self.castText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    self.castText:SetPoint("LEFT", 5, 0)
    self.castText:SetTextColor(1, 1, 1)
    
    -- Cast time text
    self.castTime = self.castBar:CreateFontString(nil, "OVERLAY")
    self.castTime:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    self.castTime:SetPoint("RIGHT", -5, 0)
    self.castTime:SetTextColor(1, 1, 1)
    
    -- Register cast events
    self.frame:RegisterEvent("UNIT_SPELLCAST_START")
    self.frame:RegisterEvent("UNIT_SPELLCAST_STOP")
    self.frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self.frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self.frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self.frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    self.frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    self.frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
end

function TargetFrame:UpdateCastBar()
    if not UnitExists("target") then
        self.castBar:Hide()
        return
    end
    
    local name, _, _, startTime, endTime, _, _, notInterruptible = UnitCastingInfo("target")
    local channeling = false
    
    if not name then
        name, _, _, startTime, endTime, _, notInterruptible = UnitChannelInfo("target")
        channeling = true
    end
    
    if name then
        self.castBar:Show()
        self.castText:SetText(name)
        
        local duration = (endTime - startTime) / 1000
        local current = GetTime() - (startTime / 1000)
        
        if channeling then
            self.castBar:SetMinMaxValues(0, duration)
            self.castBar:SetValue(duration - current)
        else
            self.castBar:SetMinMaxValues(0, duration)
            self.castBar:SetValue(current)
        end
        
        self.castTime:SetFormattedText("%.1f/%.1f", current, duration)
        
        -- Update colors
        if notInterruptible then
            self.castBar:SetStatusBarColor(0.7, 0.7, 0.7)
        elseif channeling then
            local cr, cg, cb = AzeriteMOP:GetColor("castBarChannel")
            self.castBar:SetStatusBarColor(cr, cg, cb)
        else
            local cr, cg, cb = AzeriteMOP:GetColor("castBarNormal")
            self.castBar:SetStatusBarColor(cr, cg, cb)
        end
    else
        self.castBar:Hide()
    end
end

function TargetFrame:UpdateTarget()
    -- This function is called periodically to ensure the target frame stays updated
    if UnitExists("target") then
        self:UpdateHealth()
        self:UpdatePower() -- This now updates the portrait and power text
        self:UpdateCastBar() -- Update cast bar
    end
end

 