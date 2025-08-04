-- AzeriteMOP Nameplate Module
-- Custom nameplates for MoP Classic

local ADDON_NAME, Addon = ...
local AzeriteMOP = Addon.AzeriteMOP

-- Create Nameplate module
AzeriteMOP.Nameplate = {}
local Nameplate = AzeriteMOP.Nameplate

-- Constants
local NAMEPLATE_WIDTH = 120
local NAMEPLATE_HEIGHT = 12
local CASTBAR_HEIGHT = 10
local NAMEPLATE_FONT = "Fonts\\FRIZQT__.TTF"
local NAMEPLATE_FONT_SIZE = 10

-- Color tables
local REACTION_COLORS = {
    [1] = {0.78, 0.25, 0.25}, -- Hostile
    [2] = {0.78, 0.25, 0.25}, -- Hostile
    [3] = {0.78, 0.25, 0.25}, -- Hostile
    [4] = {0.93, 0.93, 0.00}, -- Neutral
    [5] = {0.00, 0.50, 0.00}, -- Friendly
    [6] = {0.00, 0.50, 0.00}, -- Friendly
    [7] = {0.00, 0.50, 0.00}, -- Friendly
    [8] = {0.00, 0.50, 0.00}, -- Friendly
}

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

-- Store active nameplates
Nameplate.activePlates = {}

function Nameplate:Initialize()
    AzeriteMOP:Debug("Initializing Nameplate Module...")
    
    -- Ensure database exists first
    AzeriteMOP:EnsureDatabase()
    
    -- Set up database defaults
    self:SetupDatabase()
    
    -- Hook into nameplate system
    self:SetupNameplateCallbacks()
    
    -- Register events
    self:RegisterEvents()
    
    -- Set up CVars for better nameplate behavior
    self:SetupCVars()
    
    AzeriteMOP:Debug("Nameplate Module initialized!")
end

function Nameplate:SetupDatabase()
    if not AzeriteMOP.db then
        AzeriteMOP.db = {}
    end
    
    if not AzeriteMOP.db.nameplate then
        AzeriteMOP.db.nameplate = {
            enabled = true,
            scale = 1.0,
            width = NAMEPLATE_WIDTH,
            height = NAMEPLATE_HEIGHT,
            showCastbar = true,
            showLevel = true,
            showName = true,
            classColors = true,
            threatColors = true,
            hideBlizzard = true,
            fontSize = NAMEPLATE_FONT_SIZE,
            healthTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\nameplate_bar",
            castTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\cast_bar",
            castBackdropTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\cast_back",
            castBorderTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\cast_back_outline",
            backdropTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\nameplate_backdrop",
            borderTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\nameplate_outline",
            glowTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\nameplate_glow",
            -- Cast bar colors
            castColorInterruptible = {1, 0.7, 0}, -- Yellow/gold for interruptible
            castColorNotInterruptible = {0.7, 0.7, 0.7}, -- Gray for non-interruptible
            castColorChanneled = {0, 1, 0}, -- Green for channeled spells
            showCastSpellName = true,
            -- Cast bar size settings
            castBarWidth = NAMEPLATE_WIDTH,  -- Default same as nameplate width
            castBarHeight = CASTBAR_HEIGHT,   -- Default 8
            -- Font size settings
            castFontSize = NAMEPLATE_FONT_SIZE,  -- Cast bar spell name font size
            levelFontSize = NAMEPLATE_FONT_SIZE - 1  -- Level text font size
        }
    end
    
    -- Ensure all fields exist with defaults
    local defaults = {
        enabled = true,
        scale = 1.0,
        width = NAMEPLATE_WIDTH,
        height = NAMEPLATE_HEIGHT,
        showCastbar = true,
        showLevel = true,
        showName = true,
        classColors = true,
        threatColors = true,
        hideBlizzard = true,
        fontSize = NAMEPLATE_FONT_SIZE,
        healthTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\nameplate_bar",
        castTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\cast_bar",
        castBackdropTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\cast_back",
        castBorderTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\cast_back_outline",
        backdropTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\nameplate_backdrop",
        borderTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\nameplate_outline",
        glowTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\nameplate_glow",
        -- Cast bar colors
        castColorInterruptible = {1, 0.7, 0}, -- Yellow/gold for interruptible
        castColorNotInterruptible = {0.7, 0.7, 0.7}, -- Gray for non-interruptible
        castColorChanneled = {0, 1, 0}, -- Green for channeled spells
        showCastSpellName = true,
        -- Cast bar size settings
        castBarWidth = NAMEPLATE_WIDTH,
        castBarHeight = CASTBAR_HEIGHT,
        -- Font size settings
        castFontSize = NAMEPLATE_FONT_SIZE,
        levelFontSize = NAMEPLATE_FONT_SIZE - 1
    }
    
    for key, value in pairs(defaults) do
        if AzeriteMOP.db.nameplate[key] == nil then
            AzeriteMOP.db.nameplate[key] = value
        end
    end
end

function Nameplate:SetupCVars()
    -- Set up nameplate CVars for better behavior in MoP
    if SetCVar then
        SetCVar("nameplateShowAll", 1)
        SetCVar("nameplateShowEnemies", 1)
        SetCVar("nameplateShowFriends", 1)
        SetCVar("nameplateMotion", 1) -- Stacking nameplates
        SetCVar("nameplateOverlapH", 0.8)
        SetCVar("nameplateOverlapV", 1.1)
    end
end

function Nameplate:SetupNameplateCallbacks()
    -- In MoP, we hook into the default nameplate creation
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        Nameplate:OnUpdate(elapsed)
    end)
    
    -- Store reference
    self.updateFrame = frame
end

function Nameplate:OnUpdate(elapsed)
    -- Throttle updates for performance
    self.updateTimer = (self.updateTimer or 0) + elapsed
    if self.updateTimer < 0.03 then  -- Update 30 times per second for smooth cast bars
        return
    end
    self.updateTimer = 0
    
    -- Scan for nameplates (MoP style)
    local nameplates = {WorldFrame:GetChildren()}
    
    for _, frame in ipairs(nameplates) do
        if self:IsNameplate(frame) and not frame.AzeriteMOPProcessed then
            self:ProcessNameplate(frame)
            frame.AzeriteMOPProcessed = true
        end
    end
    
    -- Update active nameplates (this keeps health/cast bars current)
    for frame, customPlate in pairs(self.activePlates) do
        if frame and frame:IsShown() and customPlate then
            self:UpdateNameplate(frame, customPlate)
            
            -- Update cast bar animation if casting
            if customPlate.currentCast and customPlate.castBar then
                local castInfo = customPlate.currentCast
                local currentTime = GetTime()
                local duration = castInfo.endTime - castInfo.startTime
                local elapsed = currentTime - castInfo.startTime
                
                -- Add a small buffer to prevent premature hiding (0.1 seconds)
                if elapsed >= 0 and elapsed <= (duration + 0.1) then
                    -- Ensure cast bar is shown
                    if not customPlate.castBar:IsShown() then
                        customPlate.castBar:Show()
                        customPlate.castBar:SetAlpha(1)
                    end
                    
                    -- Clamp elapsed to duration to prevent overflow
                    local displayElapsed = math.min(elapsed, duration)
                    
                    if castInfo.isChannel then
                        -- Channels count down
                        customPlate.castBar:SetValue(duration - displayElapsed)
                    else
                        -- Regular casts count up
                        customPlate.castBar:SetValue(displayElapsed)
                    end
                    
                    -- Update time text
                    if customPlate.castTime then
                        local timeLeft = math.max(0, duration - elapsed)
                        if timeLeft > 0 then
                            customPlate.castTime:SetText(string.format("%.1f", timeLeft))
                        else
                            customPlate.castTime:SetText("")
                        end
                    end
                    
                    -- Keep spell name and text frame visible during animation
                    if customPlate.castTextFrame then
                        customPlate.castTextFrame:Show()
                        customPlate.castTextFrame:SetAlpha(1)
                    end
                    if customPlate.castText and castInfo.spellName and AzeriteMOP.db.nameplate.showCastSpellName then
                        customPlate.castText:SetText(castInfo.spellName)
                        customPlate.castText:Show()
                        customPlate.castText:SetAlpha(1)
                        customPlate.castText:SetTextColor(1, 1, 1, 1)
                    end
                else
                    -- Cast should be done, hide it
                    customPlate.currentCast = nil
                    customPlate.lastCastSpellName = nil  -- Clear stored spell name
                    customPlate.castBar:SetScript("OnHide", nil)  -- Clear the OnHide prevention
                    customPlate.castBar:Hide()
                    
                    -- Clear any cached cast shown flag
                    if frame.castBarShown then
                        frame.castBarShown = nil
                        frame.castBarShownTime = nil
                    end
                end
            end
        end
    end
end

function Nameplate:IsNameplate(frame)
    -- Check if this frame is a nameplate
    if not frame then return false end
    
    local name = frame:GetName()
    if name and string.find(name, "^NamePlate") then
        return true
    end
    
    -- Additional checks for unnamed nameplates
    local regions = {frame:GetRegions()}
    if #regions > 2 then
        for _, region in ipairs(regions) do
            if region and region:GetObjectType() == "Texture" then
                local texture = region:GetTexture()
                if texture and string.find(texture, "TextureKit") then
                    return true
                end
            end
        end
    end
    
    return false
end

function Nameplate:ProcessNameplate(frame)
    AzeriteMOP:Debug("Processing new nameplate")
    
    -- Try to determine the unit token for this nameplate early
    local unit = self:GetNameplateUnit(frame)
    if unit then
        AzeriteMOP:Debug("Found unit token: " .. unit .. " for nameplate")
    end
    
    -- Create our custom nameplate FIRST
    local customPlate = self:CreateCustomNameplate(frame)
    self.activePlates[frame] = customPlate
    
    -- Store reference to our custom plate in the frame so we can avoid hiding it
    frame.AzeriteMOPCustomPlate = customPlate
    
    -- Hide default Blizzard nameplate elements when using custom nameplates
    if AzeriteMOP.db.nameplate.hideBlizzard ~= false then
        self:HideBlizzardPlate(frame)
        
        -- Double-check hiding with a slight delay to catch late-loading elements
        C_Timer.After(0.01, function()
            if frame and frame:IsShown() then
                self:HideBlizzardPlate(frame)
            end
        end)
    end
    
    -- Initial update
    self:UpdateNameplate(frame, customPlate)
    
    -- Make sure our custom plate is visible
    customPlate:Show()
    customPlate:SetAlpha(1)
    if customPlate.container then
        customPlate.container:Show()
        customPlate.container:SetAlpha(1)
    end
    
    -- Set up continuous hiding to prevent Blizzard elements from reappearing
    if not frame.hideTimer then
        frame.hideTimer = C_Timer.NewTicker(0.2, function()  -- Check more frequently
            if AzeriteMOP.db.nameplate.hideBlizzard ~= false and frame:IsShown() then
                -- Keep UnitFrame hidden
                if frame.UnitFrame then
                    if frame.UnitFrame:GetAlpha() > 0 then
                        frame.UnitFrame:SetAlpha(0)
                    end
                    if frame.UnitFrame.healthBar and frame.UnitFrame.healthBar:IsShown() then
                        frame.UnitFrame.healthBar:Hide()
                        frame.UnitFrame.healthBar:SetAlpha(0)
                    end
                    -- Keep cast bar functional but visually hidden
                    if frame.UnitFrame.castBar then
                        local castRegions = {frame.UnitFrame.castBar:GetRegions()}
                        for _, region in ipairs(castRegions) do
                            if region and region:GetObjectType() ~= "StatusBar" then
                                region:SetAlpha(0)
                            end
                        end
                    end
                end
                
                -- Re-hide Blizzard elements periodically (but not our custom plate)
                local regions = {frame:GetRegions()}
                for _, region in ipairs(regions) do
                    if region and region:GetAlpha() > 0 then
                        region:SetAlpha(0)
                    end
                end
                
                local children = {frame:GetChildren()}
                for _, child in ipairs(children) do
                    -- Don't hide our custom plate!
                    if child and child ~= customPlate and child:GetAlpha() > 0 then
                        child:SetAlpha(0)
                    end
                end
                
                -- Ensure our custom plate stays visible
                if customPlate and customPlate:GetAlpha() < 1 then
                    customPlate:SetAlpha(1)
                    if customPlate.container then
                        customPlate.container:SetAlpha(1)
                    end
                end
                
                -- NEVER hide cast bar if it's currently showing a cast
                if customPlate and customPlate.castBar and customPlate.currentCast then
                    customPlate.castBar:SetAlpha(1)
                    if customPlate.castBar:GetAlpha() < 1 then
                        customPlate.castBar:SetAlpha(1)
                    end
                    -- Make sure cast bar is shown if we have an active cast
                    if not customPlate.castBar:IsShown() then
                        customPlate.castBar:Show()
                    end
                    -- Keep cast text and text frame visible
                    if customPlate.castTextFrame then
                        customPlate.castTextFrame:Show()
                        customPlate.castTextFrame:SetAlpha(1)
                    end
                    if customPlate.castText then
                        -- Use either the current spell name or the last known one
                        local spellName = customPlate.currentCast.spellName or customPlate.lastCastSpellName
                        if spellName and AzeriteMOP.db.nameplate.showCastSpellName then
                            customPlate.castText:SetText(spellName)
                            customPlate.castText:Show()
                            customPlate.castText:SetAlpha(1)
                            customPlate.castText:SetTextColor(1, 1, 1, 1)
                        end
                    end
                end
            end
        end)
    end
end

function Nameplate:HideBlizzardPlate(frame)
    -- Hide default nameplate elements more thoroughly
    if not frame then return end
    
    -- MoP specific: Hide the UnitFrame health bar if it exists
    if frame.UnitFrame then
        if frame.UnitFrame.healthBar then
            frame.UnitFrame.healthBar:Hide()
            frame.UnitFrame.healthBar:SetAlpha(0)
            -- Also hide its textures
            local healthRegions = {frame.UnitFrame.healthBar:GetRegions()}
            for _, region in ipairs(healthRegions) do
                if region then
                    region:SetAlpha(0)
                    region:Hide()
                end
            end
        end
        -- Don't hide the cast bar - we need to read from it!
        -- Just hide its visual elements but keep the StatusBar functional
        if frame.UnitFrame.castBar then
            -- Hide visual elements but keep the bar functional for data reading
            local castRegions = {frame.UnitFrame.castBar:GetRegions()}
            for _, region in ipairs(castRegions) do
                if region and region:GetObjectType() ~= "StatusBar" then
                    region:SetAlpha(0)
                end
            end
            -- Keep the cast bar itself functional but invisible
            if frame.UnitFrame.castBar.SetAlpha then
                -- Don't set alpha to 0, keep it functional
                -- frame.UnitFrame.castBar:SetAlpha(0)
            end
        end
        -- Don't hide the entire UnitFrame - we need data from it
        -- frame.UnitFrame:SetAlpha(0)
    end
    
    -- Hide all regions (textures, fontstrings)
    local regions = {frame:GetRegions()}
    for _, region in ipairs(regions) do
        if region then
            if region:GetObjectType() == "Texture" then
                -- Hide all textures
                region:SetAlpha(0)
                region:Hide()
            elseif region:GetObjectType() == "FontString" then
                -- Hide name and level text
                region:SetAlpha(0)
                region:Hide()
            end
        end
    end
    
    -- Hide all children (status bars, frames) EXCEPT our custom plate
    local children = {frame:GetChildren()}
    for _, child in ipairs(children) do
        -- Skip our custom plate
        if child and child ~= frame.AzeriteMOPCustomPlate then
            if child:GetObjectType() == "StatusBar" then
                -- This is likely health or cast bar
                child:SetAlpha(0)
                child:Hide()
                
                -- Also hide the statusbar's textures
                local barRegions = {child:GetRegions()}
                for _, barRegion in ipairs(barRegions) do
                    if barRegion then
                        barRegion:SetAlpha(0)
                        barRegion:Hide()
                    end
                end
                
                -- Hide statusbar's children too
                local barChildren = {child:GetChildren()}
                for _, barChild in ipairs(barChildren) do
                    if barChild then
                        barChild:SetAlpha(0)
                        barChild:Hide()
                    end
                end
            elseif child:GetObjectType() == "Frame" then
                -- Hide any frame children (but not our custom plate)
                child:SetAlpha(0)
                child:Hide()
            end
        end
    end
    
    -- Special handling for known Blizzard nameplate elements
    -- Try to hide by common patterns
    if frame.barFrame then
        frame.barFrame:Hide()
        frame.barFrame:SetAlpha(0)
    end
    
    if frame.nameFrame then
        frame.nameFrame:Hide()
        frame.nameFrame:SetAlpha(0)
    end
    
    -- Hide the health bar border specifically
    if frame.healthBar then
        frame.healthBar:Hide()
        frame.healthBar:SetAlpha(0)
    end
    
    if frame.castBar then
        -- Don't completely hide - we need to read from it!
        -- Just make it invisible visually
        local castRegions = {frame.castBar:GetRegions()}
        for _, region in ipairs(castRegions) do
            if region then
                region:SetAlpha(0)
            end
        end
        -- Don't hide the StatusBar itself - we need its data
        -- frame.castBar:Hide()
        -- frame.castBar:SetAlpha(0)
    end
    
    -- Set frame alpha to 0 as fallback (but keep frame visible for our overlay)
    -- We don't hide the frame itself because we need it for positioning
    local frameRegions = {frame:GetRegions()}
    for i = 1, #frameRegions do
        if frameRegions[i] then
            frameRegions[i]:SetAlpha(0)
        end
    end
end

function Nameplate:CreateCustomNameplate(parentFrame)
    -- Ensure database exists
    if not AzeriteMOP.db or not AzeriteMOP.db.nameplate then
        self:SetupDatabase()
    end
    
    local db = AzeriteMOP.db.nameplate
    
    local plate = CreateFrame("Frame", nil, parentFrame)
    plate:SetAllPoints(parentFrame)
    plate:SetFrameStrata("MEDIUM")  -- Ensure proper strata
    plate:SetFrameLevel(parentFrame:GetFrameLevel() + 10)  -- Above parent
    
    -- Create container for our elements
    local container = CreateFrame("Frame", nil, plate)
    local width = db.width or NAMEPLATE_WIDTH
    local height = db.height or NAMEPLATE_HEIGHT
    container:SetSize(width, height)
    container:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)
    
    -- Use global scale if enabled, otherwise use individual scale
    local scale = db.scale or 1.0
    if self.currentGlobalScale then
        scale = self.currentGlobalScale
    elseif AzeriteMOP.db.global and AzeriteMOP.db.global.useGlobalScale then
        scale = AzeriteMOP.db.global.uiScale or 1.0
    end
    container:SetScale(scale)
    container:SetFrameLevel(plate:GetFrameLevel() + 1)
    plate.container = container
    
    -- Create backdrop/background texture first (bottom layer)
    local backdrop = container:CreateTexture(nil, "BACKGROUND", nil, -2)
    backdrop:SetTexture(db.backdropTexture)
    backdrop:SetPoint("TOPLEFT", container, "TOPLEFT", -4, 4)
    backdrop:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 4, -4)
    backdrop:SetVertexColor(0.1, 0.1, 0.1, 0.9)
    plate.backdrop = backdrop
    
    -- Create health bar
    local healthBar = CreateFrame("StatusBar", nil, container)
    healthBar:SetSize(width, height)
    healthBar:SetPoint("CENTER", container, "CENTER", 0, 0)
    healthBar:SetStatusBarTexture(db.healthTexture)
    healthBar:SetMinMaxValues(0, 100)
    healthBar:SetValue(100)
    healthBar:SetAlpha(1)  -- Ensure full opacity
    plate.healthBar = healthBar
    
    -- Health bar background (darker version of the bar texture)
    local healthBg = healthBar:CreateTexture(nil, "BACKGROUND", nil, -1)
    healthBg:SetAllPoints(healthBar)
    healthBg:SetTexture(db.healthTexture)
    healthBg:SetVertexColor(0.15, 0.15, 0.15, 1)  -- Full opacity for background
    plate.healthBg = healthBg
    
    -- Border/outline texture (on top)
    local borderTexture = container:CreateTexture(nil, "OVERLAY", nil, 1)
    borderTexture:SetTexture(db.borderTexture)
    borderTexture:SetPoint("TOPLEFT", container, "TOPLEFT", -4, 4)
    borderTexture:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 4, -4)
    borderTexture:SetVertexColor(0, 0, 0, 1)
    plate.borderTexture = borderTexture
    
    -- Name text
    local nameText = container:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(NAMEPLATE_FONT, db.fontSize or NAMEPLATE_FONT_SIZE, "OUTLINE")
    nameText:SetPoint("BOTTOM", healthBar, "TOP", 0, 2)
    nameText:SetText("Unknown")
    plate.nameText = nameText
    
    -- Level text
    local levelText = container:CreateFontString(nil, "OVERLAY")
    levelText:SetFont(NAMEPLATE_FONT, db.levelFontSize or (db.fontSize or NAMEPLATE_FONT_SIZE) - 1, "OUTLINE")
    levelText:SetPoint("RIGHT", healthBar, "LEFT", -2, 0)
    levelText:SetText("")
    plate.levelText = levelText
    
    -- Cast bar
    if db.showCastbar then
        local castBar = CreateFrame("StatusBar", nil, container)
        local castWidth = db.castBarWidth or width
        local castHeight = db.castBarHeight or CASTBAR_HEIGHT
        castBar:SetSize(castWidth, castHeight)
        castBar:SetPoint("TOP", healthBar, "BOTTOM", 0, -4)
        
        -- FIXED: Swapped textures - cast_back is the actual bar texture
        local castTexture = "Interface\\AddOns\\AzeriteMOP\\Textures\\cast_back"
        if not castBar:SetStatusBarTexture(castTexture) then
            -- Fallback to default UI texture
            castTexture = "Interface\\TargetingFrame\\UI-StatusBar"
            castBar:SetStatusBarTexture(castTexture)
        else
            castBar:SetStatusBarTexture(castTexture)
        end
        
        castBar:SetMinMaxValues(0, 100)
        castBar:SetValue(0)
        castBar:Hide()
        castBar:SetAlpha(1)
        castBar:SetFrameLevel(container:GetFrameLevel() + 2)  -- Base level for cast bar
        castBar:SetFrameStrata("HIGH")  -- Higher strata to prevent hiding
        plate.castBar = castBar
        
        -- Cast bar background (darker background for the bar) - FIXED: Using cast_back
        local castBg = castBar:CreateTexture(nil, "BACKGROUND", nil, -2)
        castBg:SetAllPoints(castBar)
        castBg:SetTexture(db.castTexture or "Interface\\AddOns\\AzeriteMOP\\Textures\\cast_back")
        castBg:SetVertexColor(0.15, 0.15, 0.15, 1)
        plate.castBg = castBg
        
        -- Cast bar backdrop (using cast_bar.tga as the backdrop) - FIXED: Swapped
        local castBackdrop = castBar:CreateTexture(nil, "BACKGROUND", nil, -3)
        castBackdrop:SetTexture(db.castBackdropTexture or "Interface\\AddOns\\AzeriteMOP\\Textures\\cast_bar")
        castBackdrop:SetPoint("TOPLEFT", castBar, "TOPLEFT", -4, 4)
        castBackdrop:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 4, -4)
        castBackdrop:SetVertexColor(0.2, 0.2, 0.2, 1)
        plate.castBackdrop = castBackdrop
        
        -- Cast bar border/outline (using cast_back_outline.tga)
        local castBorder = castBar:CreateTexture(nil, "BORDER", nil, -1)
        castBorder:SetTexture(db.castBorderTexture or "Interface\\AddOns\\AzeriteMOP\\Textures\\cast_back_outline")
        castBorder:SetPoint("TOPLEFT", castBar, "TOPLEFT", -4, 4)
        castBorder:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 4, -4)
        castBorder:SetVertexColor(0, 0, 0, 1)
        plate.castBorder = castBorder
        
        -- Create a text frame that sits ABOVE the cast bar with TOOLTIP strata
        -- This ensures it's always on top of everything
        local textFrame = CreateFrame("Frame", nil, container)
        textFrame:SetAllPoints(castBar)
        textFrame:SetFrameLevel(999)  -- Maximum frame level
        textFrame:SetFrameStrata("TOOLTIP")  -- Highest strata for text visibility
        plate.castTextFrame = textFrame
        
        -- Cast bar text - Create it on the text frame for proper layering
        local castText = textFrame:CreateFontString(nil, "OVERLAY", nil, 7)
        castText:SetFont(NAMEPLATE_FONT, db.castFontSize or db.fontSize or NAMEPLATE_FONT_SIZE, "OUTLINE")
        castText:SetPoint("CENTER", textFrame, "CENTER", 0, 0)  -- Center it on the text frame
        castText:SetWidth(castBar:GetWidth() - 4)
        castText:SetHeight(CASTBAR_HEIGHT)
        castText:SetJustifyH("CENTER")
        castText:SetJustifyV("MIDDLE")
        castText:SetWordWrap(false)
        castText:SetText("")
        castText:SetTextColor(1, 1, 1, 1)
        castText:SetShadowOffset(1, -1)
        castText:SetShadowColor(0, 0, 0, 1)
        castText:SetDrawLayer("OVERLAY", 7)  -- Highest sublayer
        plate.castText = castText
        
        -- Cast time text - Also on the text frame for visibility
        local castTime = textFrame:CreateFontString(nil, "OVERLAY", nil, 7)
        castTime:SetFont(NAMEPLATE_FONT, math.max(6, (db.castFontSize or db.fontSize or NAMEPLATE_FONT_SIZE) - 2), "OUTLINE")
        castTime:SetPoint("RIGHT", textFrame, "RIGHT", -2, 0)
        castTime:SetJustifyH("RIGHT")
        castTime:SetJustifyV("MIDDLE")
        castTime:SetText("")
        castTime:SetTextColor(1, 1, 1, 1)
        castTime:SetShadowOffset(1, -1)
        castTime:SetShadowColor(0, 0, 0, 1)
        castTime:SetDrawLayer("OVERLAY", 7)
        plate.castTime = castTime
    end
    
    -- Threat indicator (glow texture)
    local threatGlow = container:CreateTexture(nil, "OVERLAY", nil, 2)
    threatGlow:SetPoint("TOPLEFT", container, "TOPLEFT", -6, 6)
    threatGlow:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 6, -6)
    threatGlow:SetTexture(db.glowTexture)
    threatGlow:SetBlendMode("ADD")
    threatGlow:SetAlpha(0)
    plate.threatGlow = threatGlow
    
    -- Raid icon
    local raidIcon = container:CreateTexture(nil, "OVERLAY")
    raidIcon:SetSize(16, 16)
    raidIcon:SetPoint("LEFT", healthBar, "RIGHT", 2, 0)
    raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    raidIcon:Hide()
    plate.raidIcon = raidIcon
    
    return plate
end

function Nameplate:GetNameplateUnit(frame)
    -- In MoP Classic, nameplates don't have direct unit tokens
    -- We need to match them by checking all nameplate units
    
    -- First check if frame has stored unit info
    if frame.namePlateUnitToken then
        return frame.namePlateUnitToken
    end
    
    if frame.unit then
        return frame.unit
    end
    
    if frame.UnitFrame and frame.UnitFrame.unit then
        return frame.UnitFrame.unit
    end
    
    -- Try to find a matching nameplate unit by comparing the nameplate's target
    -- This is a workaround for MoP's limited nameplate API
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) then
            -- Try to match by name if we have it
            local unitName = UnitName(unit)
            if unitName then
                -- Check if this nameplate shows this unit's name
                local name, _ = self:GetNameplateInfo(frame)
                if name and name == unitName then
                    -- Cache the unit token for this frame
                    frame.namePlateUnitToken = unit
                    return unit
                end
            end
        end
    end
    
    -- Fallback: Check if this is a NamePlate frame by name pattern
    local name = frame:GetName()
    if name and string.match(name, "^NamePlate%d+$") then
        local id = string.match(name, "(%d+)")
        if id then
            local unit = "nameplate" .. id
            -- Cache it
            frame.namePlateUnitToken = unit
            return unit
        end
    end
    
    return nil
end

function Nameplate:UpdateNameplate(frame, customPlate)
    if not frame or not customPlate then return end
    
    -- Try to get unit token for better info
    local unit = self:GetNameplateUnit(frame)
    
    -- Update our unit-to-frame mappings
    if unit then
        -- Clear old mapping if this unit was mapped to a different frame
        local oldFrame = self.unitToFrame[unit]
        if oldFrame and oldFrame ~= frame then
            self.frameToUnit[oldFrame] = nil
        end
        
        -- Clear old mapping if this frame was mapped to a different unit
        local oldUnit = self.frameToUnit[frame]
        if oldUnit and oldUnit ~= unit then
            self.unitToFrame[oldUnit] = nil
        end
        
        -- Store new mappings
        self.unitToFrame[unit] = frame
        self.frameToUnit[frame] = unit
        
        -- Also store in frame for quick access
        frame.namePlateUnitToken = unit
        
        -- Store unit in custom plate for color updates
        if customPlate then
            customPlate.unit = unit
        end
    end
    
    -- Get nameplate info from the default frame
    local healthBar, castBar = self:GetNameplateElements(frame)
    
    if healthBar and healthBar.GetValue then
        -- Update health
        local minHealth, maxHealth = healthBar:GetMinMaxValues()
        local currentHealth = healthBar:GetValue()
        
        -- Debug output for first nameplate
        if not frame.debugged then
            frame.debugged = true
            AzeriteMOP:Debug("Health bar found - Current: " .. tostring(currentHealth) .. " Max: " .. tostring(maxHealth))
        end
        
        if maxHealth and maxHealth > 0 then
            customPlate.healthBar:SetMinMaxValues(0, maxHealth)
            customPlate.healthBar:SetValue(currentHealth)
            
            -- Update health color using our color system
            -- Don't copy from Blizzard nameplate, use our colors
            self:UpdateNameplateColors(customPlate)
        else
            -- No valid health data, try to set default values
            customPlate.healthBar:SetMinMaxValues(0, 100)
            customPlate.healthBar:SetValue(100)
            -- Use our color system for default
        local hr, hg, hb = AzeriteMOP:GetColor("nameplateHealthHostile")
        customPlate.healthBar:SetStatusBarColor(hr, hg, hb)
        end
    else
        -- Can't find health bar, set defaults
        customPlate.healthBar:SetMinMaxValues(0, 100)
        customPlate.healthBar:SetValue(100)
        -- Use our color system for default
        local hr, hg, hb = AzeriteMOP:GetColor("nameplateHealthHostile")
        customPlate.healthBar:SetStatusBarColor(hr, hg, hb)
    end
    
    -- Update name and level - look harder for them
    local name, level = self:GetNameplateInfo(frame)
    
    -- If we have a unit token, try to get the name from it
    if unit and UnitExists(unit) then
        local unitName = UnitName(unit)
        if unitName and unitName ~= "" and unitName ~= "Unknown" then
            name = unitName
        end
        
        -- Also get level from unit
        local unitLevel = UnitLevel(unit)
        if unitLevel and unitLevel > 0 then
            level = tostring(unitLevel)
        end
        
        -- Update colors using our color system
        self:UpdateNameplateColors(customPlate)
    end
    
    -- If we didn't find a name, try alternative methods
    if not name or name == "" or name == "Unknown" then
        -- Try to get from regions more thoroughly
        local regions = {frame:GetRegions()}
        for _, region in ipairs(regions) do
            if region and region:GetObjectType() == "FontString" then
                local text = region:GetText()
                if text and text ~= "" and text ~= "Unknown" and not string.match(text, "^%d") and string.len(text) > 1 then
                    -- This might be the name
                    if not string.match(text, "^%s*$") then
                        name = text
                        break
                    end
                end
            end
        end
    end
    
    if name and name ~= "" and name ~= "Unknown" and AzeriteMOP.db.nameplate.showName then
        customPlate.nameText:SetText(name)
    end
    
    if level and AzeriteMOP.db.nameplate.showLevel then
        customPlate.levelText:SetText(level)
        
        -- Color level text based on difficulty
        local levelNum = tonumber(string.match(level, "%d+"))
        if levelNum then
            local levelDiff = levelNum - UnitLevel("player")
            if levelDiff >= 5 then
                customPlate.levelText:SetTextColor(1, 0.2, 0.2) -- Red
            elseif levelDiff >= 3 then
                customPlate.levelText:SetTextColor(1, 0.5, 0.25) -- Orange
            elseif levelDiff >= -2 then
                customPlate.levelText:SetTextColor(1, 1, 0) -- Yellow
            else
                customPlate.levelText:SetTextColor(0.5, 0.5, 0.5) -- Gray
            end
        end
    end
    
    -- Update cast bar if exists
    if customPlate.castBar then
        -- Primary method: Read directly from Blizzard cast bar
        -- This is more reliable in MoP than events
        -- Check if we have a cast bar from the source frame
        if castBar then
            local isShowing = castBar:IsShown()
            local minCast, maxCast = castBar:GetMinMaxValues()
            local currentCast = castBar:GetValue()
            
            -- Only show if cast bar is actually casting (has reasonable values)
            -- MoP cast bars can use seconds or milliseconds - be flexible
            if isShowing and maxCast and maxCast > 0 and currentCast >= 0 then
                -- Detect if values are in milliseconds or seconds
                -- If maxCast > 100, it's likely milliseconds
                local isMilliseconds = maxCast > 100
                local duration = isMilliseconds and (maxCast / 1000) or maxCast
                local progress = isMilliseconds and (currentCast / 1000) or currentCast
                
                -- Debug cast bar detection (only once per cast)
                if not frame.currentCastMax or frame.currentCastMax ~= maxCast then
                    frame.currentCastMax = maxCast
                    AzeriteMOP:Debug("Cast detected! Duration: " .. string.format("%.1f", duration) .. "s (raw max: " .. maxCast .. ")")
                end
                
                -- Show and update our custom cast bar with normalized values
                customPlate.castBar:SetMinMaxValues(0, duration)
                customPlate.castBar:SetValue(progress)
                customPlate.castBar:Show()
                customPlate.castBar:SetAlpha(1)
                
                -- Force the cast bar to stay visible
                customPlate.castBar:SetScript("OnHide", function(self)
                    -- Prevent hiding while we have an active cast
                    if customPlate.currentCast then
                        self:Show()
                    end
                end)
                
                -- Make sure all cast bar elements are visible
                if customPlate.castBackdrop then
                    customPlate.castBackdrop:Show()
                    customPlate.castBackdrop:SetAlpha(1)
                end
                if customPlate.castBorder then
                    customPlate.castBorder:Show()
                    customPlate.castBorder:SetAlpha(1)
                end
                if customPlate.castBg then
                    customPlate.castBg:Show()
                    customPlate.castBg:SetAlpha(1)
                end
                -- Show the text frame to ensure text is visible
                if customPlate.castTextFrame then
                    customPlate.castTextFrame:Show()
                    customPlate.castTextFrame:SetAlpha(1)
                end
                
                -- Get spell name if available
                local spellName = self:GetCastingSpellName(frame, castBar)
                if spellName and customPlate.castText and AzeriteMOP.db.nameplate.showCastSpellName then
                    customPlate.castText:SetText(spellName)
                    customPlate.castText:Show()
                    customPlate.castText:SetAlpha(1)
                    -- Ensure text is visible and on top
                    customPlate.castText:SetTextColor(1, 1, 1, 1)
                    -- Store the spell name so it persists throughout the cast
                    customPlate.lastCastSpellName = spellName
                    AzeriteMOP:Debug("Setting cast text to: " .. spellName)
                elseif customPlate.lastCastSpellName and customPlate.castText and AzeriteMOP.db.nameplate.showCastSpellName then
                    -- Keep showing the last known spell name while cast bar is visible
                    customPlate.castText:SetText(customPlate.lastCastSpellName)
                    customPlate.castText:Show()
                    customPlate.castText:SetAlpha(1)
                    customPlate.castText:SetTextColor(1, 1, 1, 1)
                elseif customPlate.castText then
                    customPlate.castText:SetText("")
                    customPlate.castText:Hide()
                end
                
                -- Update cast time
                if customPlate.castTime then
                    -- Calculate time remaining using normalized values
                    local timeLeft = duration - progress
                    if timeLeft > 0 then
                        customPlate.castTime:SetText(string.format("%.1f", timeLeft))
                    else
                        customPlate.castTime:SetText("")
                    end
                    customPlate.castTime:Show()
                end
                
                -- Store normalized cast info for animation updates
                customPlate.currentCast = {
                    startTime = GetTime() - progress,
                    endTime = GetTime() - progress + duration,
                    isChannel = false,  -- Can't detect from Blizzard bar alone
                    spellName = spellName or customPlate.lastCastSpellName or "Unknown"
                }
                
                -- Also ensure cast bar stays on top
                customPlate.castBar:SetFrameLevel(customPlate.container:GetFrameLevel() + 5)
                
                -- Debug output
                if not frame.castBarShown then
                    frame.castBarShown = true
                    frame.castBarShownTime = GetTime()  -- Track when we showed it
                    AzeriteMOP:Debug("Showing cast bar from Blizzard detection - duration: " .. string.format("%.1f", duration) .. "s")
                end
                
                -- Set cast bar color based on interruptibility and type
                local r, g, b
                
                -- Try to detect if spell is interruptible from source cast bar color
                -- In MoP, gray typically means non-interruptible
                local isInterruptible = true
                if castBar.GetStatusBarColor then
                    local cr, cg, cb = castBar:GetStatusBarColor()
                    if cr and cg and cb then
                        -- Check if it's gray (non-interruptible)
                        if math.abs(cr - cg) < 0.1 and math.abs(cg - cb) < 0.1 and cr < 0.8 then
                            isInterruptible = false
                        end
                    end
                end
                
                -- Use color system colors
                if not isInterruptible then
                    r, g, b = 0.7, 0.7, 0.7  -- Gray for non-interruptible
                else
                    r, g, b = AzeriteMOP:GetColor("nameplateCastBar")
                end
                
                customPlate.castBar:SetStatusBarColor(r, g, b)
                
                -- Also ensure the cast bar texture is visible
                local texture = customPlate.castBar:GetStatusBarTexture()
                if texture then
                    texture:Show()
                    texture:SetAlpha(1)
                end
            else
                -- Only hide if we're sure there's no cast
                -- Check if we recently showed a cast bar to prevent flickering
                if frame.castBarShown and GetTime() - (frame.castBarShownTime or 0) < 0.1 then
                    -- Don't hide immediately - could be a timing issue
                else
                    -- No valid cast or cast finished, hide the cast bar
                    customPlate.castBar:Hide()
                    if customPlate.castText then
                        customPlate.castText:SetText("")
                        customPlate.castText:Hide()
                    end
                    if customPlate.castTime then
                        customPlate.castTime:SetText("")
                        customPlate.castTime:Hide()
                    end
                    if customPlate.castTextFrame then
                        customPlate.castTextFrame:Hide()
                    end
                    if customPlate.castBackdrop then
                        customPlate.castBackdrop:Hide()
                    end
                    if customPlate.castBorder then
                        customPlate.castBorder:Hide()
                    end
                    frame.currentCastMax = nil  -- Reset for next cast
                    frame.castBarShown = nil  -- Reset debug flag
                    customPlate.currentCast = nil
                    customPlate.lastCastSpellName = nil  -- Clear stored spell name
                end
            end
        else
            -- No cast bar found in source
            -- BUT check if we have an active cast that's still running
            if customPlate.currentCast then
                local currentTime = GetTime()
                if currentTime < customPlate.currentCast.endTime then
                    -- We still have an active cast, don't hide anything yet!
                    -- This prevents flickering when Blizzard cast bar detection fails momentarily
                    return
                end
            end
            
            -- Really no cast, hide our cast bar
            customPlate.castBar:Hide()
            if customPlate.castText then
                customPlate.castText:SetText("")
                customPlate.castText:Hide()
            end
            if customPlate.castTime then
                customPlate.castTime:SetText("")
                customPlate.castTime:Hide()
            end
            if customPlate.castTextFrame then
                customPlate.castTextFrame:Hide()
            end
            if customPlate.castBackdrop then
                customPlate.castBackdrop:Hide()
            end
            if customPlate.castBorder then
                customPlate.castBorder:Hide()
            end
        end
    end
    
    -- Update raid icon
    local raidIconIndex = self:GetRaidIconIndex(frame)
    if raidIconIndex and raidIconIndex > 0 then
        local coords = {
            [1] = {0, 0.25, 0, 0.25}, -- Star
            [2] = {0.25, 0.5, 0, 0.25}, -- Circle
            [3] = {0.5, 0.75, 0, 0.25}, -- Diamond
            [4] = {0.75, 1, 0, 0.25}, -- Triangle
            [5] = {0, 0.25, 0.25, 0.5}, -- Moon
            [6] = {0.25, 0.5, 0.25, 0.5}, -- Square
            [7] = {0.5, 0.75, 0.25, 0.5}, -- X
            [8] = {0.75, 1, 0.25, 0.5}, -- Skull
        }
        
        if coords[raidIconIndex] then
            customPlate.raidIcon:SetTexCoord(unpack(coords[raidIconIndex]))
            customPlate.raidIcon:Show()
        end
    else
        customPlate.raidIcon:Hide()
    end
    
    -- Update threat
    self:UpdateThreat(frame, customPlate)
end

function Nameplate:GetNameplateElements(frame)
    local healthBar, castBar = nil, nil
    
    -- In MoP 5.4, nameplate structure is simpler - direct children
    -- The first child is usually the health bar, second is cast bar
    local children = {frame:GetChildren()}
    
    -- MoP Classic structure: frame has 2 direct children - healthBar and castBar
    if #children >= 1 then
        local child1 = children[1]
        if child1 and child1:GetObjectType() == "StatusBar" then
            healthBar = child1
        end
    end
    
    if #children >= 2 then
        local child2 = children[2]
        if child2 and child2:GetObjectType() == "StatusBar" then
            castBar = child2
        end
    end
    
    -- Fallback: Check for UnitFrame structure (might exist in some versions)
    if not healthBar and frame.UnitFrame then
        if frame.UnitFrame.healthBar then
            healthBar = frame.UnitFrame.healthBar
        end
        if frame.UnitFrame.castBar then
            castBar = frame.UnitFrame.castBar
        end
    end
    
    -- If still not found, do a more thorough search
    if not healthBar or not castBar then
        for i, child in ipairs(children) do
            if child and child:GetObjectType() == "StatusBar" then
                -- Check if this is a health bar or cast bar based on current values
                local minVal, maxVal = child:GetMinMaxValues()
                local currentVal = child:GetValue()
                
                -- Health bars typically have larger max values
                if not healthBar and maxVal > 100 then
                    healthBar = child
                elseif not castBar and child ~= healthBar then
                    castBar = child
                end
            end
        end
    end
    
    -- Debug output
    if not frame.debuggedElements then
        frame.debuggedElements = true
        if healthBar and castBar then
            AzeriteMOP:Debug("Found nameplate elements - HealthBar: yes, CastBar: yes")
        elseif healthBar then
            AzeriteMOP:Debug("Found nameplate elements - HealthBar: yes, CastBar: no")
        else
            AzeriteMOP:Debug("Found nameplate elements - HealthBar: no, CastBar: no")
        end
    end
    
    return healthBar, castBar
end

function Nameplate:GetNameplateInfo(frame)
    local name, level = nil, nil
    
    -- MoP nameplate structure: regions are in a predictable order
    -- Region order: threat, border, highlight, name, level, bossIcon, raidIcon, eliteIcon
    local regions = {frame:GetRegions()}
    
    -- Debug: log all regions to understand structure
    if not frame.regionsDebuggedInfo then
        frame.regionsDebuggedInfo = true
        AzeriteMOP:Debug("Nameplate has " .. #regions .. " regions:")
        for i, region in ipairs(regions) do
            if region and region:GetObjectType() == "FontString" then
                local text = region:GetText()
                if text and text ~= "" then
                    AzeriteMOP:Debug("  Region " .. i .. " (FontString): '" .. text .. "'")
                end
            end
        end
    end
    
    -- In MoP, name is typically the 4th region and level is the 5th
    if regions[4] and regions[4]:GetObjectType() == "FontString" then
        name = regions[4]:GetText()
    end
    
    if regions[5] and regions[5]:GetObjectType() == "FontString" then
        level = regions[5]:GetText()
    end
    
    -- If the standard positions didn't work, search through all regions
    if not name or name == "" then
        for i, region in ipairs(regions) do
            if region and region:GetObjectType() == "FontString" then
                local text = region:GetText()
                if text and text ~= "" then
                    -- Skip if it looks like a level (pure numbers with optional ?)
                    if not string.match(text, "^%d+%??$") then
                        -- This is likely the name if it's more than 1 character
                        if string.len(text) > 1 and not string.match(text, "^%s*$") then
                            name = text
                            AzeriteMOP:Debug("Found name in region " .. i .. ": '" .. text .. "'")
                        end
                    elseif not level then
                        -- This looks like a level
                        level = text
                    end
                end
            end
        end
    end
    
    -- Clean up the name if needed
    if name then
        -- Store original for debugging
        local originalName = name
        
        name = string.gsub(name, "|c%x%x%x%x%x%x%x%x", "")  -- Remove color codes
        name = string.gsub(name, "|r", "")  -- Remove reset codes
        name = string.gsub(name, "^%s*(.-)%s*$", "%1")  -- Trim whitespace
        
        if originalName ~= name then
            AzeriteMOP:Debug("Cleaned name from '" .. originalName .. "' to '" .. name .. "'")
        end
    end
    
    return name, level
end

function Nameplate:GetCastingSpellName(frame, castBar)
    -- First try to get it from the cast bar itself
    if castBar then
        -- Check if cast bar has regions (text)
        local castRegions = {castBar:GetRegions()}
        for i, region in ipairs(castRegions) do
            if region and region:GetObjectType() == "FontString" then
                local text = region:GetText()
                if text and text ~= "" and string.len(text) > 1 then
                    AzeriteMOP:Debug("Found spell name in cast bar region " .. i .. ": " .. text)
                    return text
                end
            end
        end
        
        -- Check cast bar children
        local castChildren = {castBar:GetChildren()}
        for _, child in ipairs(castChildren) do
            if child and child:GetObjectType() == "FontString" then
                local text = child:GetText()
                if text and text ~= "" then
                    AzeriteMOP:Debug("Found spell name in cast bar child: " .. text)
                    return text
                end
            end
        end
    end
    
    -- Check UnitFrame for cast info
    if frame.UnitFrame and frame.UnitFrame.castBar then
        local castBarRegions = {frame.UnitFrame.castBar:GetRegions()}
        for _, region in ipairs(castBarRegions) do
            if region and region:GetObjectType() == "FontString" then
                local text = region:GetText()
                if text and text ~= "" and string.len(text) > 1 then
                    AzeriteMOP:Debug("Found spell name in UnitFrame cast bar: " .. text)
                    return text
                end
            end
        end
    end
    
    -- Fallback: search all frame regions
    local regions = {frame:GetRegions()}
    for _, region in ipairs(regions) do
        if region and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            -- Look for text that looks like a spell name (not numbers, not the unit name)
            if text and string.len(text) > 2 and not string.match(text, "^%d") then
                local parent = region:GetParent()
                if parent and parent:GetObjectType() == "StatusBar" then
                    -- This is likely the cast bar text
                    AzeriteMOP:Debug("Found spell name in frame region: " .. text)
                    return text
                end
            end
        end
    end
    
    -- As a last resort, if we're tracking the target, get spell from target
    if frame.namePlateUnitToken == "target" and UnitExists("target") then
        local spellName = UnitCastingInfo("target")
        if not spellName then
            spellName = UnitChannelInfo("target")
        end
        if spellName then
            AzeriteMOP:Debug("Got spell name from target unit: " .. spellName)
            return spellName
        end
    end
    
    AzeriteMOP:Debug("Could not find spell name")
    return nil
end

function Nameplate:GetRaidIconIndex(frame)
    local regions = {frame:GetRegions()}
    for _, region in ipairs(regions) do
        if region and region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and string.find(texture, "RaidTargetingIcon") then
                -- Get the raid icon index from texture coordinates
                local left = region:GetTexCoord()
                local index = math.floor(left * 8) + 1
                if region:IsShown() then
                    return index
                end
            end
        end
    end
    return nil
end

function Nameplate:OnUnitCastStart(unit, isChannel)
    if not unit then return end
    
    -- In MoP, nameplate units might not work, so we'll handle target specially
    -- and try to match any unit that's casting to a visible nameplate
    AzeriteMOP:Debug("OnUnitCastStart called for unit: " .. unit)
    
    -- Get cast info
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId
    
    if isChannel then
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(unit)
    else
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
    end
    
    if not name then return end
    
    -- Store cast info for this unit
    self.activeCasts[unit] = {
        spellName = name,
        spellTexture = texture,
        startTime = startTimeMS / 1000,  -- Convert to seconds
        endTime = endTimeMS / 1000,      -- Convert to seconds
        isChannel = isChannel,
        notInterruptible = notInterruptible,
        spellId = spellId,
        castID = castID
    }
    
    AzeriteMOP:Debug("Cast started for " .. unit .. ": " .. name .. " (Duration: " .. string.format("%.1f", (endTimeMS - startTimeMS) / 1000) .. "s)")
    
    -- Update the nameplate cast bar immediately
    self:UpdateNameplateCastBar(unit)
end

function Nameplate:OnUnitCastStop(unit)
    if not unit then return end
    
    -- Clear cast info for this unit
    if self.activeCasts[unit] then
        AzeriteMOP:Debug("Cast stopped for " .. unit)
        self.activeCasts[unit] = nil
        
        -- Update the nameplate cast bar to hide it
        self:UpdateNameplateCastBar(unit)
    end
end

function Nameplate:OnUnitCastUpdate(unit, isChannel)
    if not unit then return end
    
    -- Update cast info
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId
    
    if isChannel then
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(unit)
    else
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
    end
    
    if not name then 
        self.activeCasts[unit] = nil
        return 
    end
    
    -- Update cast info
    if self.activeCasts[unit] then
        self.activeCasts[unit].startTime = startTimeMS / 1000
        self.activeCasts[unit].endTime = endTimeMS / 1000
        
        -- Update the nameplate cast bar
        self:UpdateNameplateCastBar(unit)
    end
end

function Nameplate:UpdateNameplateCastBar(unit)
    if not unit then return end
    
    -- Find the nameplate frame for this unit
    local nameplateFrame = nil
    local customPlate = nil
    
    -- First try our stored mapping
    nameplateFrame = self.unitToFrame[unit]
    if nameplateFrame then
        customPlate = self.activePlates[nameplateFrame]
    end
    
    -- Special handling for target unit
    if not customPlate and unit == "target" then
        -- Find the nameplate that matches our target
        local targetName = UnitName("target")
        if targetName then
            for frame, plate in pairs(self.activePlates) do
                local frameName, _ = self:GetNameplateInfo(frame)
                if frameName then
                    local cleanFrameName = string.gsub(frameName, "^%s*(.-)%s*$", "%1"):lower()
                    local cleanTargetName = string.gsub(targetName, "^%s*(.-)%s*$", "%1"):lower()
                    
                    if cleanFrameName == cleanTargetName then
                        nameplateFrame = frame
                        customPlate = plate
                        AzeriteMOP:Debug("Found target's nameplate: " .. frameName)
                        break
                    end
                end
            end
        end
    end
    
    -- If not found in mapping, try to find by name matching
    if not customPlate then
        local unitName = UnitName(unit)
        
        if unitName then
            AzeriteMOP:Debug("Looking for nameplate with name: " .. unitName .. " for unit: " .. unit)
            
            for frame, plate in pairs(self.activePlates) do
                -- Try to match by name (case-insensitive and trim whitespace)
                local frameName, _ = self:GetNameplateInfo(frame)
                if frameName then
                    -- Clean up both names for comparison
                    local cleanFrameName = string.gsub(frameName, "^%s*(.-)%s*$", "%1"):lower()
                    local cleanUnitName = string.gsub(unitName, "^%s*(.-)%s*$", "%1"):lower()
                    
                    if cleanFrameName == cleanUnitName then
                        nameplateFrame = frame
                        customPlate = plate
                        -- Store the mapping for future use
                        self.unitToFrame[unit] = frame
                        self.frameToUnit[frame] = unit
                        frame.namePlateUnitToken = unit
                        AzeriteMOP:Debug("Found nameplate by name match: " .. frameName .. " == " .. unitName)
                        break
                    end
                end
            end
        end
    end
    
    if not customPlate or not customPlate.castBar then 
        local unitName = UnitName(unit) or "unknown"
        AzeriteMOP:Debug("Could not find nameplate for unit " .. unit .. " (" .. unitName .. ")")
        -- List all active nameplates for debugging
        local count = 0
        for frame, plate in pairs(self.activePlates) do
            count = count + 1
            local name, _ = self:GetNameplateInfo(frame)
            AzeriteMOP:Debug("  Active nameplate " .. count .. ": " .. (name or "unnamed"))
        end
        return 
    end
    
    AzeriteMOP:Debug("Updating cast bar for unit " .. unit .. " on nameplate")
    
    -- Debug cast bar visibility
    if not nameplateFrame.castDebugged then
        nameplateFrame.castDebugged = true
        AzeriteMOP:Debug("Cast bar frame level: " .. customPlate.castBar:GetFrameLevel())
        AzeriteMOP:Debug("Cast bar parent visible: " .. tostring(customPlate.container:IsVisible()))
    end
    
    local castInfo = self.activeCasts[unit]
    
    if castInfo then
        -- Show and update cast bar
        local currentTime = GetTime()
        local duration = castInfo.endTime - castInfo.startTime
        local elapsed = currentTime - castInfo.startTime
        
        if elapsed < 0 then elapsed = 0 end
        if elapsed > duration then elapsed = duration end
        
        -- Set up the cast bar
        customPlate.castBar:SetMinMaxValues(0, duration)
        
        if castInfo.isChannel then
            -- Channels count down
            customPlate.castBar:SetValue(duration - elapsed)
        else
            -- Regular casts count up
            customPlate.castBar:SetValue(elapsed)
        end
        
        customPlate.castBar:Show()
        customPlate.castBar:SetAlpha(1)
        
        -- Ensure the status bar texture is set and visible
        local texture = customPlate.castBar:GetStatusBarTexture()
        if texture then
            texture:SetAlpha(1)
            texture:Show()
        end
        
        -- Show cast bar elements
        if customPlate.castBackdrop then
            customPlate.castBackdrop:Show()
            customPlate.castBackdrop:SetAlpha(1)
        end
        if customPlate.castBorder then
            customPlate.castBorder:Show()
            customPlate.castBorder:SetAlpha(1)
        end
        if customPlate.castBg then
            customPlate.castBg:Show()
            customPlate.castBg:SetAlpha(1)
        end
        if customPlate.castTextFrame then
            customPlate.castTextFrame:Show()
            customPlate.castTextFrame:SetAlpha(1)
        end
        
        -- Update spell name
        if customPlate.castText and AzeriteMOP.db.nameplate.showCastSpellName then
            customPlate.castText:SetText(castInfo.spellName or "")
            customPlate.castText:Show()
            customPlate.castText:SetAlpha(1)
            customPlate.castText:SetTextColor(1, 1, 1, 1)  -- White text for visibility
            AzeriteMOP:Debug("Showing spell name from event: " .. (castInfo.spellName or "unknown"))
        elseif customPlate.castText then
            customPlate.castText:SetText("")
            customPlate.castText:Hide()
        end
        
        -- Update cast time
        if customPlate.castTime then
            local timeLeft = duration - elapsed
            if castInfo.isChannel then
                timeLeft = duration - elapsed
            end
            
            if timeLeft > 0 then
                customPlate.castTime:SetText(string.format("%.1f", timeLeft))
            else
                customPlate.castTime:SetText("")
            end
            customPlate.castTime:Show()
        end
        
        -- Set cast bar color based on interruptibility and type
        local r, g, b
        
        if castInfo.notInterruptible then
            r, g, b = 0.7, 0.7, 0.7  -- Gray for non-interruptible
        elseif castInfo.isChannel then
            -- Use a slightly different color for channeled casts if desired
            r, g, b = AzeriteMOP:GetColor("nameplateCastBar")
            -- Make it slightly greener for channels
            g = math.min(1, g + 0.2)
        else
            r, g, b = AzeriteMOP:GetColor("nameplateCastBar")
        end
        
        customPlate.castBar:SetStatusBarColor(r, g, b)
        
        -- Store cast info in frame for update ticker
        customPlate.currentCast = castInfo
    else
        -- Hide cast bar
        customPlate.castBar:Hide()
        if customPlate.castText then
            customPlate.castText:SetText("")
            customPlate.castText:Hide()
        end
        if customPlate.castTime then
            customPlate.castTime:SetText("")
            customPlate.castTime:Hide()
        end
        if customPlate.castTextFrame then
            customPlate.castTextFrame:Hide()
        end
        if customPlate.castBackdrop then
            customPlate.castBackdrop:Hide()
        end
        if customPlate.castBorder then
            customPlate.castBorder:Hide()
        end
        
        customPlate.currentCast = nil
        customPlate.lastCastSpellName = nil  -- Clear stored spell name
    end
end

function Nameplate:UpdateThreat(frame, customPlate)
    if not AzeriteMOP.db.nameplate.threatColors then
        customPlate.threatGlow:SetAlpha(0)
        return
    end
    
    -- Simple threat detection based on healthbar color
    local healthBar = self:GetNameplateElements(frame)
    if healthBar then
        local r, g, b = healthBar:GetStatusBarColor()
        
        -- Check if we have aggro (red tinted)
        if r > 0.9 and g < 0.2 and b < 0.2 then
            customPlate.threatGlow:SetVertexColor(1, 0, 0)
            customPlate.threatGlow:SetAlpha(0.5)
        -- Check if we're losing aggro (yellow/orange)
        elseif r > 0.9 and g > 0.6 and b < 0.2 then
            customPlate.threatGlow:SetVertexColor(1, 0.7, 0)
            customPlate.threatGlow:SetAlpha(0.3)
        else
            customPlate.threatGlow:SetAlpha(0)
        end
    end
end

function Nameplate:RegisterEvents()
    -- Register for nameplate-related events
    local eventFrame = CreateFrame("Frame")
    
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
    
    -- Register for casting events
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        Nameplate:OnEvent(event, ...)
    end)
    
    self.eventFrame = eventFrame
    
    -- Store active casts per unit
    self.activeCasts = {}
    
    -- Store unit-to-frame mappings
    self.unitToFrame = {}
    self.frameToUnit = {}
end

function Nameplate:OnEvent(event, ...)
    local unit = ...
    
    if event == "PLAYER_ENTERING_WORLD" then
        -- Refresh CVars
        self:SetupCVars()
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- Update target cast bar if casting
        if UnitExists("target") then
            local name = UnitCastingInfo("target")
            if not name then
                name = UnitChannelInfo("target")
            end
            if name then
                self:OnUnitCastStart("target", UnitChannelInfo("target") ~= nil)
            end
        end
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
        -- Update threat on all nameplates
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        -- Also handle target unit specially
        if unit == "target" or string.match(unit or "", "^nameplate") then
            self:OnUnitCastStart(unit, event == "UNIT_SPELLCAST_CHANNEL_START")
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or 
           event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or
           event == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit == "target" or string.match(unit or "", "^nameplate") then
            self:OnUnitCastStop(unit)
        end
    elseif event == "UNIT_SPELLCAST_DELAYED" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        if unit == "target" or string.match(unit or "", "^nameplate") then
            self:OnUnitCastUpdate(unit, event == "UNIT_SPELLCAST_CHANNEL_UPDATE")
        end
    end
end

-- Slash commands for testing
function Nameplate:SetupSlashCommands()
    SLASH_AZNAMEPLATES1 = "/azplates"
    SLASH_AZNAMEPLATES2 = "/aznp"
    
    SlashCmdList["AZNAMEPLATES"] = function(msg)
        local args = {}
        for arg in string.gmatch(msg, "%S+") do
            table.insert(args, string.lower(arg))
        end
        
        local command = args[1] or ""
        
        if command == "" or command == "help" then
            -- Show help/available commands
            print("|cFF4488FF[AzeriteMOP Nameplates]|r Available Commands:")
            print("  |cFFFFFF00General:|r")
            print("    /azplates scale [0.5-2.0] - Set nameplate scale")
            print("    /azplates width [50-200] - Set nameplate width")
            print("    /azplates height [5-30] - Set nameplate height")
            print("    /azplates fontsize [6-20] - Set nameplate name font size")
            print("    /azplates levelfontsize [6-20] - Set level text font size")
            print("    /azplates reset - Reset all nameplates")
            print("")
            print("  |cFFFFFF00Cast Bars:|r")
            print("    /azplates castwidth [50-200] - Set cast bar width")
            print("    /azplates castheight [4-20] - Set cast bar height")
            print("    /azplates castfontsize [6-20] - Set cast bar spell name font size")
            print("    /azplates castcolor - Show cast color settings and types")
            print("    /azplates spellname [on/off] - Toggle spell names on cast bars")
            print("")
            print("  |cFFFFFF00Testing:|r")
            print("    /azplates testcast - Test cast bar display")
            print("    /azplates testtext - Test nameplate text")
            print("")
            print("  |cFF00FF00Type any command without parameters to see current values|r")
            return
        elseif command == "scale" then
            local scale = tonumber(args[2]) or 1.0
            if not AzeriteMOP.db or not AzeriteMOP.db.nameplate then
                self:SetupDatabase()
            end
            AzeriteMOP.db.nameplate.scale = math.max(0.5, math.min(2.0, scale))
            print("|cFF4488FF[AzeriteMOP]|r Nameplate scale set to " .. AzeriteMOP.db.nameplate.scale)
            -- Update existing nameplates
            for frame, customPlate in pairs(self.activePlates) do
                if customPlate.container then
                    customPlate.container:SetScale(AzeriteMOP.db.nameplate.scale)
                end
            end
        elseif command == "width" then
            local width = tonumber(args[2]) or NAMEPLATE_WIDTH
            AzeriteMOP.db.nameplate.width = math.max(50, math.min(200, width))
            print("|cFF4488FF[AzeriteMOP]|r Nameplate width set to " .. AzeriteMOP.db.nameplate.width)
            -- Update existing nameplates
            for frame, customPlate in pairs(self.activePlates) do
                if customPlate.healthBar then
                    customPlate.healthBar:SetSize(AzeriteMOP.db.nameplate.width, customPlate.healthBar:GetHeight())
                    -- Force status bar texture to update
                    local texture = customPlate.healthBar:GetStatusBarTexture()
                    if texture then
                        texture:SetWidth(AzeriteMOP.db.nameplate.width)
                    end
                end
                if customPlate.healthBg then
                    customPlate.healthBg:SetAllPoints(customPlate.healthBar)
                end
                if customPlate.container then
                    -- Adjust container size
                    customPlate.container:SetSize(AzeriteMOP.db.nameplate.width, customPlate.container:GetHeight())
                end
                -- Update backdrop and border positions
                if customPlate.backdrop then
                    customPlate.backdrop:ClearAllPoints()
                    customPlate.backdrop:SetPoint("TOPLEFT", customPlate.container, "TOPLEFT", -4, 4)
                    customPlate.backdrop:SetPoint("BOTTOMRIGHT", customPlate.container, "BOTTOMRIGHT", 4, -4)
                end
                if customPlate.borderTexture then
                    customPlate.borderTexture:ClearAllPoints()
                    customPlate.borderTexture:SetPoint("TOPLEFT", customPlate.container, "TOPLEFT", -4, 4)
                    customPlate.borderTexture:SetPoint("BOTTOMRIGHT", customPlate.container, "BOTTOMRIGHT", 4, -4)
                end
                -- Also update cast bar width if it's using nameplate width
                if customPlate.castBar and not AzeriteMOP.db.nameplate.castBarWidth then
                    customPlate.castBar:SetWidth(AzeriteMOP.db.nameplate.width)
                    if customPlate.castText then
                        customPlate.castText:SetWidth(AzeriteMOP.db.nameplate.width - 4)
                    end
                end
            end
        elseif command == "height" then
            local height = tonumber(args[2]) or NAMEPLATE_HEIGHT
            AzeriteMOP.db.nameplate.height = math.max(5, math.min(30, height))
            print("|cFF4488FF[AzeriteMOP]|r Nameplate height set to " .. AzeriteMOP.db.nameplate.height)
            -- Update existing nameplates
            for frame, customPlate in pairs(self.activePlates) do
                if customPlate.healthBar then
                    customPlate.healthBar:SetSize(customPlate.healthBar:GetWidth(), AzeriteMOP.db.nameplate.height)
                    -- Force status bar texture to update
                    local texture = customPlate.healthBar:GetStatusBarTexture()
                    if texture then
                        texture:SetHeight(AzeriteMOP.db.nameplate.height)
                    end
                end
                if customPlate.healthBg then
                    customPlate.healthBg:SetAllPoints(customPlate.healthBar)
                end
                if customPlate.container then
                    -- Adjust container height
                    customPlate.container:SetSize(customPlate.container:GetWidth(), AzeriteMOP.db.nameplate.height)
                end
                -- Update backdrop and border positions
                if customPlate.backdrop then
                    customPlate.backdrop:ClearAllPoints()
                    customPlate.backdrop:SetPoint("TOPLEFT", customPlate.container, "TOPLEFT", -4, 4)
                    customPlate.backdrop:SetPoint("BOTTOMRIGHT", customPlate.container, "BOTTOMRIGHT", 4, -4)
                end
                if customPlate.borderTexture then
                    customPlate.borderTexture:ClearAllPoints()
                    customPlate.borderTexture:SetPoint("TOPLEFT", customPlate.container, "TOPLEFT", -4, 4)
                    customPlate.borderTexture:SetPoint("BOTTOMRIGHT", customPlate.container, "BOTTOMRIGHT", 4, -4)
                end
            end
        elseif command == "castwidth" then
            local width = tonumber(args[2]) or NAMEPLATE_WIDTH
            AzeriteMOP.db.nameplate.castBarWidth = math.max(50, math.min(200, width))
            print("|cFF4488FF[AzeriteMOP]|r Cast bar width set to " .. AzeriteMOP.db.nameplate.castBarWidth)
            -- Update existing cast bars
            for frame, customPlate in pairs(self.activePlates) do
                if customPlate.castBar then
                    customPlate.castBar:SetWidth(AzeriteMOP.db.nameplate.castBarWidth)
                    if customPlate.castText then
                        customPlate.castText:SetWidth(AzeriteMOP.db.nameplate.castBarWidth - 4)
                    end
                    -- Update backdrop and border to match new size
                    if customPlate.castBackdrop then
                        customPlate.castBackdrop:ClearAllPoints()
                        customPlate.castBackdrop:SetPoint("TOPLEFT", customPlate.castBar, "TOPLEFT", -4, 4)
                        customPlate.castBackdrop:SetPoint("BOTTOMRIGHT", customPlate.castBar, "BOTTOMRIGHT", 4, -4)
                    end
                    if customPlate.castBorder then
                        customPlate.castBorder:ClearAllPoints()
                        customPlate.castBorder:SetPoint("TOPLEFT", customPlate.castBar, "TOPLEFT", -4, 4)
                        customPlate.castBorder:SetPoint("BOTTOMRIGHT", customPlate.castBar, "BOTTOMRIGHT", 4, -4)
                    end
                    if customPlate.castTextFrame then
                        customPlate.castTextFrame:SetAllPoints(customPlate.castBar)
                    end
                end
            end
        elseif command == "castheight" then
            local height = tonumber(args[2]) or CASTBAR_HEIGHT
            AzeriteMOP.db.nameplate.castBarHeight = math.max(4, math.min(20, height))
            print("|cFF4488FF[AzeriteMOP]|r Cast bar height set to " .. AzeriteMOP.db.nameplate.castBarHeight)
            -- Update existing cast bars
            for frame, customPlate in pairs(self.activePlates) do
                if customPlate.castBar then
                    customPlate.castBar:SetHeight(AzeriteMOP.db.nameplate.castBarHeight)
                    if customPlate.castText then
                        customPlate.castText:SetHeight(AzeriteMOP.db.nameplate.castBarHeight)
                    end
                    -- Update backdrop and border to match new size
                    if customPlate.castBackdrop then
                        customPlate.castBackdrop:ClearAllPoints()
                        customPlate.castBackdrop:SetPoint("TOPLEFT", customPlate.castBar, "TOPLEFT", -4, 4)
                        customPlate.castBackdrop:SetPoint("BOTTOMRIGHT", customPlate.castBar, "BOTTOMRIGHT", 4, -4)
                    end
                    if customPlate.castBorder then
                        customPlate.castBorder:ClearAllPoints()
                        customPlate.castBorder:SetPoint("TOPLEFT", customPlate.castBar, "TOPLEFT", -4, 4)
                        customPlate.castBorder:SetPoint("BOTTOMRIGHT", customPlate.castBar, "BOTTOMRIGHT", 4, -4)
                    end
                    if customPlate.castTextFrame then
                        customPlate.castTextFrame:SetAllPoints(customPlate.castBar)
                    end
                end
            end
        elseif command == "fontsize" then
            local size = tonumber(args[2])
            if not size then
                print("|cFF4488FF[AzeriteMOP]|r Current nameplate font size: " .. (AzeriteMOP.db.nameplate.fontSize or NAMEPLATE_FONT_SIZE))
                print("  Usage: /azplates fontsize [6-20]")
                return
            end
            AzeriteMOP.db.nameplate.fontSize = math.max(6, math.min(20, size))
            print("|cFF4488FF[AzeriteMOP]|r Nameplate font size set to " .. AzeriteMOP.db.nameplate.fontSize)
            -- Update existing nameplates
            for frame, customPlate in pairs(self.activePlates) do
                if customPlate.nameText then
                    customPlate.nameText:SetFont(NAMEPLATE_FONT, AzeriteMOP.db.nameplate.fontSize, "OUTLINE")
                end
            end
        elseif command == "levelfontsize" then
            local size = tonumber(args[2])
            if not size then
                print("|cFF4488FF[AzeriteMOP]|r Current level font size: " .. (AzeriteMOP.db.nameplate.levelFontSize or NAMEPLATE_FONT_SIZE - 1))
                print("  Usage: /azplates levelfontsize [6-20]")
                return
            end
            AzeriteMOP.db.nameplate.levelFontSize = math.max(6, math.min(20, size))
            print("|cFF4488FF[AzeriteMOP]|r Level font size set to " .. AzeriteMOP.db.nameplate.levelFontSize)
            -- Update existing nameplates
            for frame, customPlate in pairs(self.activePlates) do
                if customPlate.levelText then
                    customPlate.levelText:SetFont(NAMEPLATE_FONT, AzeriteMOP.db.nameplate.levelFontSize, "OUTLINE")
                end
            end
        elseif command == "castfontsize" then
            local size = tonumber(args[2])
            if not size then
                print("|cFF4488FF[AzeriteMOP]|r Current cast bar font size: " .. (AzeriteMOP.db.nameplate.castFontSize or NAMEPLATE_FONT_SIZE))
                print("  Usage: /azplates castfontsize [6-20]")
                return
            end
            AzeriteMOP.db.nameplate.castFontSize = math.max(6, math.min(20, size))
            print("|cFF4488FF[AzeriteMOP]|r Cast bar font size set to " .. AzeriteMOP.db.nameplate.castFontSize)
            -- Update existing cast bars
            for frame, customPlate in pairs(self.activePlates) do
                if customPlate.castText then
                    customPlate.castText:SetFont(NAMEPLATE_FONT, AzeriteMOP.db.nameplate.castFontSize, "OUTLINE")
                end
                if customPlate.castTime then
                    customPlate.castTime:SetFont(NAMEPLATE_FONT, math.max(6, AzeriteMOP.db.nameplate.castFontSize - 2), "OUTLINE")
                end
            end
        elseif command == "reset" then
            self.activePlates = {}
            -- Force reprocess all nameplates
            local nameplates = {WorldFrame:GetChildren()}
            for _, frame in ipairs(nameplates) do
                if frame.AzeriteMOPProcessed then
                    frame.AzeriteMOPProcessed = nil
                end
            end
            print("|cFF4488FF[AzeriteMOP]|r Nameplates reset")
        elseif command == "testcast" then
            -- Test cast bar display
            print("|cFF4488FF[AzeriteMOP]|r Testing cast bars...")
            local count = 0
            for frame, customPlate in pairs(self.activePlates) do
                count = count + 1
                if customPlate and customPlate.castBar then
                    -- Get nameplate name for identification
                    local name, _ = self:GetNameplateInfo(frame)
                    
                    customPlate.castBar:SetMinMaxValues(0, 3)
                    customPlate.castBar:SetValue(1.5)
                    customPlate.castBar:Show()
                    customPlate.castBar:SetAlpha(1)
                    local cr, cg, cb = AzeriteMOP:GetColor("nameplateCastBar")
                    customPlate.castBar:SetStatusBarColor(cr, cg, cb)
                    
                    -- Show all cast bar elements
                    if customPlate.castBackdrop then
                        customPlate.castBackdrop:Show()
                        customPlate.castBackdrop:SetAlpha(1)
                    end
                    if customPlate.castBorder then
                        customPlate.castBorder:Show()
                        customPlate.castBorder:SetAlpha(1)
                    end
                    if customPlate.castBg then
                        customPlate.castBg:Show()
                        customPlate.castBg:SetAlpha(1)
                    end
                    if customPlate.castTextFrame then
                        customPlate.castTextFrame:Show()
                        customPlate.castTextFrame:SetAlpha(1)
                    end
                    if customPlate.castText then
                        customPlate.castText:SetText("Test Spell Name")
                        customPlate.castText:Show()
                        customPlate.castText:SetAlpha(1)
                        customPlate.castText:SetTextColor(1, 1, 1, 1)
                        
                        -- Debug text properties
                        local font, size, flags = customPlate.castText:GetFont()
                        print("    Cast text font size: " .. (size or "unknown"))
                        print("    Cast text alpha: " .. customPlate.castText:GetAlpha())
                        print("    Cast text shown: " .. tostring(customPlate.castText:IsShown()))
                    end
                    if customPlate.castTime then
                        customPlate.castTime:SetText("1.5")
                        customPlate.castTime:Show()
                        customPlate.castTime:SetAlpha(1)
                    end
                    
                    -- Store test cast info for animation
                    customPlate.currentCast = {
                        startTime = GetTime() - 1.5,
                        endTime = GetTime() + 1.5,
                        isChannel = false
                    }
                    
                    print("  - Showing test cast bar on nameplate " .. count .. " (" .. (name or "unnamed") .. ")")
                    
                    -- Only test first 3 nameplates
                    if count >= 3 then break end
                end
            end
            
            if count == 0 then
                print("  - No active nameplates found!")
            end
        elseif command == "findcast" then
            -- Debug command to find cast bars in nameplates
            print("|cFF4488FF[AzeriteMOP]|r Searching for cast bars in nameplates...")
            local nameplates = {WorldFrame:GetChildren()}
            local foundCount = 0
            
            for _, frame in ipairs(nameplates) do
                if self:IsNameplate(frame) then
                    foundCount = foundCount + 1
                    print("Checking nameplate " .. foundCount .. ":")
                    
                    -- Look for all StatusBars in this nameplate
                    local statusBars = {}
                    local children = {frame:GetChildren()}
                    
                    -- Check direct children
                    for i, child in ipairs(children) do
                        if child and child:GetObjectType() == "StatusBar" then
                            local min, max = child:GetMinMaxValues()
                            local value = child:GetValue()
                            local isShown = child:IsShown()
                            print(string.format("  - StatusBar %d: Min=%.1f Max=%.1f Value=%.1f Shown=%s", 
                                i, min or 0, max or 0, value or 0, tostring(isShown)))
                            table.insert(statusBars, child)
                        end
                    end
                    
                    -- Check nested frames
                    for i, child in ipairs(children) do
                        if child and child:GetObjectType() == "Frame" then
                            local subChildren = {child:GetChildren()}
                            for j, subChild in ipairs(subChildren) do
                                if subChild and subChild:GetObjectType() == "StatusBar" then
                                    local min, max = subChild:GetMinMaxValues()
                                    local value = subChild:GetValue()
                                    local isShown = subChild:IsShown()
                                    print(string.format("  - Nested StatusBar %d-%d: Min=%.1f Max=%.1f Value=%.1f Shown=%s", 
                                        i, j, min or 0, max or 0, value or 0, tostring(isShown)))
                                    table.insert(statusBars, subChild)
                                end
                            end
                        end
                    end
                    
                    -- Check UnitFrame structure
                    if frame.UnitFrame then
                        print("  - Has UnitFrame structure")
                        if frame.UnitFrame.healthBar then
                            local min, max = frame.UnitFrame.healthBar:GetMinMaxValues()
                            local value = frame.UnitFrame.healthBar:GetValue()
                            print(string.format("    - healthBar: Min=%.1f Max=%.1f Value=%.1f", 
                                min or 0, max or 0, value or 0))
                        end
                        if frame.UnitFrame.castBar then
                            local min, max = frame.UnitFrame.castBar:GetMinMaxValues()
                            local value = frame.UnitFrame.castBar:GetValue()
                            local isShown = frame.UnitFrame.castBar:IsShown()
                            print(string.format("    - castBar: Min=%.1f Max=%.1f Value=%.1f Shown=%s", 
                                min or 0, max or 0, value or 0, tostring(isShown)))
                        end
                    end
                    
                    if foundCount >= 2 then break end  -- Check first 2 nameplates
                end
            end
        elseif command == "toggle" then
            AzeriteMOP.db.nameplate.enabled = not AzeriteMOP.db.nameplate.enabled
            print("|cFF4488FF[AzeriteMOP]|r Nameplates " .. (AzeriteMOP.db.nameplate.enabled and "enabled" or "disabled"))
        elseif command == "debug" then
            -- Debug command to see what elements are still visible
            print("|cFF4488FF[AzeriteMOP]|r Debugging nameplates...")
            local count = 0
            local nameplates = {WorldFrame:GetChildren()}
            for _, frame in ipairs(nameplates) do
                if self:IsNameplate(frame) then
                    count = count + 1
                    print("Nameplate " .. count .. ":")
                    
                    -- Check regions
                    local regions = {frame:GetRegions()}
                    for i, region in ipairs(regions) do
                        if region and region:GetAlpha() > 0 then
                            print("  - Region " .. i .. ": " .. region:GetObjectType() .. " (Alpha: " .. region:GetAlpha() .. ")")
                            if region:GetObjectType() == "Texture" then
                                local texture = region:GetTexture()
                                if texture then
                                    print("    Texture: " .. tostring(texture))
                                end
                            end
                        end
                    end
                    
                    -- Check children
                    local children = {frame:GetChildren()}
                    for i, child in ipairs(children) do
                        if child and child:GetAlpha() > 0 then
                            print("  - Child " .. i .. ": " .. child:GetObjectType() .. " (Alpha: " .. child:GetAlpha() .. ")")
                        end
                    end
                    
                    if count >= 1 then break end -- Just debug first nameplate
                end
            end
            print("Found " .. count .. " nameplates")
        elseif command == "hideblizz" then
            -- Force hide all Blizzard nameplate elements
            AzeriteMOP.db.nameplate.hideBlizzard = true
            for frame, customPlate in pairs(self.activePlates) do
                self:HideBlizzardPlate(frame)
            end
            print("|cFF4488FF[AzeriteMOP]|r Force hiding all Blizzard nameplate elements")
        elseif command == "show" then
            -- Force show our custom nameplates
            print("|cFF4488FF[AzeriteMOP]|r Showing custom nameplates...")
            local count = 0
            for frame, customPlate in pairs(self.activePlates) do
                count = count + 1
                if customPlate then
                    customPlate:Show()
                    customPlate:SetAlpha(1)
                    if customPlate.container then
                        customPlate.container:Show()
                        customPlate.container:SetAlpha(1)
                        print("  - Showing nameplate container #" .. count)
                    end
                    if customPlate.healthBar then
                        customPlate.healthBar:Show()
                        customPlate.healthBar:SetAlpha(1)
                        print("  - Health bar visible: " .. tostring(customPlate.healthBar:IsVisible()))
                        print("  - Health bar alpha: " .. customPlate.healthBar:GetAlpha())
                        local min, max = customPlate.healthBar:GetMinMaxValues()
                        local value = customPlate.healthBar:GetValue()
                        print("  - Health bar values: " .. value .. "/" .. max)
                        local r, g, b = customPlate.healthBar:GetStatusBarColor()
                        print("  - Health bar color: R=" .. string.format("%.2f", r or 0) .. " G=" .. string.format("%.2f", g or 0) .. " B=" .. string.format("%.2f", b or 0))
                    end
                    if customPlate.nameText then
                        print("  - Name text: " .. tostring(customPlate.nameText:GetText()))
                    end
                    
                    -- Check the source frame for data
                    local healthBar, castBar = self:GetNameplateElements(frame)
                    if healthBar then
                        local srcMin, srcMax = healthBar:GetMinMaxValues()
                        local srcVal = healthBar:GetValue()
                        print("  - Source health bar: " .. srcVal .. "/" .. srcMax)
                    else
                        print("  - WARNING: No source health bar found!")
                    end
                    
                    -- Check for cast bar
                    if castBar then
                        print("  - Cast bar found!")
                        print("    - Cast bar shown: " .. tostring(castBar:IsShown()))
                        if castBar:IsShown() then
                            local minCast, maxCast = castBar:GetMinMaxValues()
                            local currentCast = castBar:GetValue()
                            print("    - Cast values: " .. currentCast .. "/" .. maxCast)
                        end
                    else
                        print("  - No cast bar found in source")
                    end
                    
                    if customPlate.castBar then
                        print("  - Custom cast bar exists: " .. tostring(customPlate.castBar:IsShown()))
                    end
                    
                    if customPlate.backdrop then
                        local texture = customPlate.backdrop:GetTexture()
                        print("  - Backdrop texture: " .. tostring(texture))
                    end
                    if customPlate.borderTexture then
                        local texture = customPlate.borderTexture:GetTexture()
                        print("  - Border texture: " .. tostring(texture))
                    end
                    
                    if count >= 1 then break end  -- Just show first one for debugging
                end
            end
        elseif command == "castcolor" then
            local colorType = args[2]
            local r = tonumber(args[3])
            local g = tonumber(args[4])
            local b = tonumber(args[5])
            
            if not colorType then
                print("|cFF4488FF[AzeriteMOP]|r Cast Bar Color Settings:")
                print("  |cFFFFFF00Usage:|r /azplates castcolor [type] R G B")
                print("  |cFF00FF00Cast Types:|r")
                print("    |cFFFFAA00interruptible|r - Regular casts that can be interrupted")
                print("    |cFF888888notinterruptible|r - Casts that cannot be interrupted (gray shield)")
                print("    |cFF00FF00channeled|r - Channeled spells (e.g., Drain Life, Arcane Missiles)")
                print("")
                print("  |cFF00FFFFCurrent Colors:|r")
                local db = AzeriteMOP.db.nameplate
                local ir, ig, ib = unpack(db.castColorInterruptible)
                local nr, ng, nb = unpack(db.castColorNotInterruptible)
                local cr, cg, cb = unpack(db.castColorChanneled)
                print(string.format("    Interruptible: |cFF%02x%02x%02x%.2f %.2f %.2f|r", ir*255, ig*255, ib*255, ir, ig, ib))
                print(string.format("    Not Interruptible: |cFF%02x%02x%02x%.2f %.2f %.2f|r", nr*255, ng*255, nb*255, nr, ng, nb))
                print(string.format("    Channeled: |cFF%02x%02x%02x%.2f %.2f %.2f|r", cr*255, cg*255, cb*255, cr, cg, cb))
                print("")
                print("  |cFFAAAAFFExamples:|r")
                print("    /azplates castcolor interruptible 1 0.7 0  |cFFFFB300(golden)|r")
                print("    /azplates castcolor notinterruptible 0.5 0.5 0.5  |cFF808080(gray)|r")
                print("    /azplates castcolor channeled 0 1 0  |cFF00FF00(green)|r")
                return
            end
            
            if not r or not g or not b then
                print("|cFF4488FF[AzeriteMOP]|r |cFFFF0000Error:|r Please provide R G B values (0-1)")
                print("  Example: /azplates castcolor " .. colorType .. " 1 0.7 0")
                return
            end
            
            -- Clamp values
            r = math.max(0, math.min(1, r))
            g = math.max(0, math.min(1, g))
            b = math.max(0, math.min(1, b))
            
            if colorType == "interruptible" then
                AzeriteMOP.db.nameplate.castColorInterruptible = {r, g, b}
                print("|cFF4488FF[AzeriteMOP]|r Interruptible cast color set to: " .. string.format("%.2f %.2f %.2f", r, g, b))
            elseif colorType == "notinterruptible" then
                AzeriteMOP.db.nameplate.castColorNotInterruptible = {r, g, b}
                print("|cFF4488FF[AzeriteMOP]|r Not interruptible cast color set to: " .. string.format("%.2f %.2f %.2f", r, g, b))
            elseif colorType == "channeled" then
                AzeriteMOP.db.nameplate.castColorChanneled = {r, g, b}
                print("|cFF4488FF[AzeriteMOP]|r Channeled cast color set to: " .. string.format("%.2f %.2f %.2f", r, g, b))
            else
                print("|cFF4488FF[AzeriteMOP]|r Invalid color type. Use: interruptible, notinterruptible, or channeled")
            end
        elseif command == "spellname" then
            local toggle = args[2]
            if toggle == "on" or toggle == "true" or toggle == "1" then
                AzeriteMOP.db.nameplate.showCastSpellName = true
                print("|cFF4488FF[AzeriteMOP]|r Cast spell names enabled")
            elseif toggle == "off" or toggle == "false" or toggle == "0" then
                AzeriteMOP.db.nameplate.showCastSpellName = false
                print("|cFF4488FF[AzeriteMOP]|r Cast spell names disabled")
            else
                AzeriteMOP.db.nameplate.showCastSpellName = not AzeriteMOP.db.nameplate.showCastSpellName
                print("|cFF4488FF[AzeriteMOP]|r Cast spell names " .. (AzeriteMOP.db.nameplate.showCastSpellName and "enabled" or "disabled"))
            end
        elseif command == "testtext" then
            -- Debug test to see if text shows at all
            print("|cFF4488FF[AzeriteMOP]|r Testing nameplate text...")
            for frame, customPlate in pairs(self.activePlates) do
                if customPlate and customPlate.nameText then
                    -- Test the name text
                    customPlate.nameText:SetText("TEST NAME")
                    customPlate.nameText:SetTextColor(1, 0, 0, 1)  -- Red
                    print("  - Set name text to red TEST NAME")
                end
                if customPlate and customPlate.castBar and customPlate.castText then
                    -- Force show cast bar and text
                    customPlate.castBar:Show()
                    customPlate.castBar:SetMinMaxValues(0, 3)
                    customPlate.castBar:SetValue(1.5)
                    customPlate.castText:SetText("TEST CAST")
                    customPlate.castText:Show()
                    customPlate.castText:SetTextColor(0, 1, 0, 1)  -- Green
                    print("  - Set cast text to green TEST CAST")
                    print("  - Cast text parent: " .. tostring(customPlate.castText:GetParent():GetName() or "unnamed"))
                    print("  - Cast text visible: " .. tostring(customPlate.castText:IsVisible()))
                end
                break  -- Just test first nameplate
            end
        else
            print("|cFF4488FF[AzeriteMOP Nameplates]|r Commands:")
            print("  /azplates scale [0.5-2.0] - Set nameplate scale")
            print("  /azplates width [50-200] - Set nameplate width")
            print("  /azplates height [5-30] - Set nameplate height")
            print("  /azplates reset - Reset all nameplates")
            print("  /azplates toggle - Enable/disable nameplates")
            print("  /azplates debug - Debug visible nameplate elements")
            print("  /azplates hideblizz - Force hide Blizzard nameplates")
            print("  /azplates testcast - Show test cast bar")
            print("  /azplates findcast - Find and debug cast bars in nameplates")
            print("  /azplates show - Show detailed info about active nameplates")
            print("  /azplates castcolor [type] R G B - Set cast bar colors")
            print("  /azplates spellname [on|off] - Toggle spell name display")
        end
    end
end

-- Texture update support
function Nameplate:UpdateAllTextures()
    if not AzeriteMOP.db.textures then
        return
    end
    
    -- Update textures for all active nameplates
    for frame, customPlate in pairs(self.activePlates) do
        self:UpdateNameplateTextures(customPlate)
    end
end

function Nameplate:UpdateNameplateTextures(plate)
    if not plate or not AzeriteMOP.db.textures then
        return
    end
    
    -- Update health bar texture
    if plate.healthBar then
        local healthTexture = AzeriteMOP:GetTexture("healthBar")
        plate.healthBar:SetStatusBarTexture(healthTexture)
    end
    
    -- Update cast bar texture
    if plate.castBar then
        local castTexture = AzeriteMOP:GetTexture("castBar")
        plate.castBar:SetStatusBarTexture(castTexture)
    end
    
    -- Update background textures
    local bgTexture = AzeriteMOP:GetTexture("barBackground")
    if plate.backdrop then
        plate.backdrop:SetTexture(bgTexture)
    end
    if plate.castBG then
        plate.castBG:SetTexture(bgTexture)
    end
end

-- Color update support
function Nameplate:UpdateAllColors()
    if not AzeriteMOP.db.colors then
        return
    end
    
    -- Update colors for all active nameplates
    for frame, customPlate in pairs(self.activePlates) do
        self:UpdateNameplateColors(customPlate)
    end
end

function Nameplate:UpdateNameplateColors(plate)
    if not plate or not AzeriteMOP.db.colors then
        return
    end
    
    local unit = plate.unit
    
    -- Update health bar color based on reaction
    if plate.healthBar then
        local colorKey = "nameplateHealthNeutral"
        
        if unit and UnitExists(unit) then
            -- We have a valid unit, use it to determine reaction
            if UnitIsFriend(unit, "player") then
                colorKey = "nameplateHealthFriendly"
            elseif UnitIsEnemy(unit, "player") then
                colorKey = "nameplateHealthHostile"
            end
        else
            -- No unit token, default to hostile for most nameplates
            -- (Most nameplates are enemies in combat)
            colorKey = "nameplateHealthHostile"
        end
        
        -- Check for class colors
        if unit and UnitExists(unit) and AzeriteMOP.db.colors.useClassColors and UnitIsPlayer(unit) then
            local _, class = UnitClass(unit)
            if class and CLASS_COLORS[class] then
                local color = CLASS_COLORS[class]
                plate.healthBar:SetStatusBarColor(color[1], color[2], color[3])
            else
                local hr, hg, hb = AzeriteMOP:GetColor(colorKey)
                plate.healthBar:SetStatusBarColor(hr, hg, hb)
            end
        else
            local hr, hg, hb = AzeriteMOP:GetColor(colorKey)
            plate.healthBar:SetStatusBarColor(hr, hg, hb)
        end
    end
    
    -- Update health background
    if plate.backdrop then
        local hbr, hbg, hbb = AzeriteMOP:GetColor("nameplateHealthBg")
        plate.backdrop:SetVertexColor(hbr, hbg, hbb, 0.8)
    end
    
    -- Update name text color
    if plate.nameText then
        local tr, tg, tb = AzeriteMOP:GetColor("nameplateNameText")
        plate.nameText:SetTextColor(tr, tg, tb)
    end
    
    -- Update level text color
    if plate.levelText then
        local lr, lg, lb = AzeriteMOP:GetColor("nameplateLevelText")
        plate.levelText:SetTextColor(lr, lg, lb)
    end
    
    -- Update cast bar colors (will be applied when cast starts)
    -- Cast bar colors are set dynamically during casting
    
    if plate.castText then
        local ctr, ctg, ctb = AzeriteMOP:GetColor("castBarText")
        plate.castText:SetTextColor(ctr, ctg, ctb)
    end
    
    if plate.castTime then
        local ctr2, ctg2, ctb2 = AzeriteMOP:GetColor("castBarTimeText")
        plate.castTime:SetTextColor(ctr2, ctg2, ctb2)
    end
end

-- Global scale support
function Nameplate:ApplyGlobalScale(scale)
    if not AzeriteMOP.db.nameplate then
        return
    end
    
    -- Apply scale to all active nameplates
    for frame, customPlate in pairs(self.activePlates) do
        if customPlate and customPlate.container then
            customPlate.container:SetScale(scale)
        end
    end
    
    -- Store the global scale for new nameplates
    self.currentGlobalScale = scale
end

function Nameplate:RestoreIndividualScales()
    if not AzeriteMOP.db.nameplate then
        return
    end
    
    local individualScale = AzeriteMOP.db.nameplate.scale or 1.0
    
    -- Restore individual scale to all active nameplates
    for frame, customPlate in pairs(self.activePlates) do
        if customPlate and customPlate.container then
            customPlate.container:SetScale(individualScale)
        end
    end
    
    -- Clear the global scale
    self.currentGlobalScale = nil
end

-- Initialize slash commands
Nameplate:SetupSlashCommands()