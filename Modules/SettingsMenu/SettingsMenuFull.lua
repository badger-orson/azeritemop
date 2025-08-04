-- AzeriteMOP Settings Menu Module (Full Featured Version)
-- Comprehensive GUI for all addon settings

local ADDON_NAME, Addon = ...
local AzeriteMOP = Addon.AzeriteMOP

-- Create SettingsMenu module
AzeriteMOP.SettingsMenu = {}
local SettingsMenu = AzeriteMOP.SettingsMenu

-- Constants
local MENU_WIDTH = 900
local MENU_HEIGHT = 650
local TAB_WIDTH = 100
local TAB_HEIGHT = 30

-- Tab management
local tabs = {}
local tabFrames = {}
local currentTab = nil

function SettingsMenu:Initialize()
    AzeriteMOP:Debug("Initializing Full Settings Menu...")
    
    -- Create the main settings frame
    self:CreateMainFrame()
    
    -- Create all tabs
    self:CreateTabs()
    
    -- Create tab content frames
    self:CreateGeneralTab()
    self:CreateFramesTab()
    self:CreateExplorerTab()
    self:CreateChatTab()
    self:CreateColorsTab()
    self:CreateProfilesTab()
    
    -- Show first tab
    self:ShowTab("General")
    
    -- Initially hide the menu
    self.mainFrame:Hide()
    
    AzeriteMOP:Debug("Full Settings Menu initialized!")
end

function SettingsMenu:CreateMainFrame()
    -- Main frame
    self.mainFrame = CreateFrame("Frame", "AzeriteMOPSettingsFrameFull", UIParent)
    self.mainFrame:SetSize(MENU_WIDTH, MENU_HEIGHT)
    self.mainFrame:SetPoint("CENTER")
    self.mainFrame:SetFrameStrata("DIALOG")
    self.mainFrame:SetMovable(true)
    self.mainFrame:EnableMouse(true)
    self.mainFrame:RegisterForDrag("LeftButton")
    self.mainFrame:SetScript("OnDragStart", self.mainFrame.StartMoving)
    self.mainFrame:SetScript("OnDragStop", self.mainFrame.StopMovingOrSizing)
    
    -- Background
    self.mainFrame.bg = self.mainFrame:CreateTexture(nil, "BACKGROUND")
    self.mainFrame.bg:SetAllPoints()
    self.mainFrame.bg:SetColorTexture(0.05, 0.05, 0.05, 0.98)
    
    -- Border
    local borderSize = 2
    local border = self.mainFrame:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -borderSize, borderSize)
    border:SetPoint("BOTTOMRIGHT", borderSize, -borderSize)
    border:SetColorTexture(1, 0.8, 0, 0.5)
    
    -- Title
    self.mainFrame.title = self.mainFrame:CreateFontString(nil, "OVERLAY")
    self.mainFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    self.mainFrame.title:SetPoint("TOP", 0, -15)
    self.mainFrame.title:SetTextColor(1, 0.8, 0)
    self.mainFrame.title:SetText("AzeriteMOP Settings")
    
    -- Version text
    local version = self.mainFrame:CreateFontString(nil, "OVERLAY")
    version:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    version:SetPoint("TOPRIGHT", -40, -18)
    version:SetTextColor(0.5, 0.5, 0.5)
    version:SetText("v1.0.0")
    
    -- Close button
    self.mainFrame.closeButton = CreateFrame("Button", nil, self.mainFrame)
    self.mainFrame.closeButton:SetSize(30, 30)
    self.mainFrame.closeButton:SetPoint("TOPRIGHT", -5, -5)
    
    local closeBg = self.mainFrame.closeButton:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.8, 0.2, 0.2, 0.8)
    
    local closeText = self.mainFrame.closeButton:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    
    self.mainFrame.closeButton:SetScript("OnClick", function()
        SettingsMenu:Hide()
    end)
    
    -- Tab area background
    self.tabArea = CreateFrame("Frame", nil, self.mainFrame)
    self.tabArea:SetPoint("TOPLEFT", 10, -50)
    self.tabArea:SetPoint("TOPRIGHT", -10, -50)
    self.tabArea:SetHeight(TAB_HEIGHT + 10)
    
    local tabBg = self.tabArea:CreateTexture(nil, "BACKGROUND")
    tabBg:SetAllPoints()
    tabBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    
    -- Content area
    self.contentArea = CreateFrame("Frame", nil, self.mainFrame)
    self.contentArea:SetPoint("TOPLEFT", 10, -95)
    self.contentArea:SetPoint("BOTTOMRIGHT", -10, 10)
    
    local contentBg = self.contentArea:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints()
    contentBg:SetColorTexture(0.08, 0.08, 0.08, 0.8)
end

function SettingsMenu:CreateTabs()
    local tabNames = {"General", "Frames", "Explorer", "Chat", "Colors", "Profiles"}
    local xOffset = 5
    
    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", nil, self.tabArea)
        tab:SetSize(TAB_WIDTH, TAB_HEIGHT)
        tab:SetPoint("TOPLEFT", xOffset, -5)
        
        -- Tab background
        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        tab.bg = bg
        
        -- Tab text
        local text = tab:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        text:SetPoint("CENTER")
        text:SetText(name)
        tab.text = text
        
        -- Tab highlight
        local highlight = tab:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.1)
        
        -- Selection indicator
        local selected = tab:CreateTexture(nil, "OVERLAY")
        selected:SetHeight(3)
        selected:SetPoint("BOTTOMLEFT", 2, 0)
        selected:SetPoint("BOTTOMRIGHT", -2, 0)
        selected:SetColorTexture(1, 0.8, 0, 1)
        selected:Hide()
        tab.selected = selected
        
        tab:SetScript("OnClick", function()
            self:ShowTab(name)
        end)
        
        tabs[name] = tab
        xOffset = xOffset + TAB_WIDTH + 5
    end
end

function SettingsMenu:ShowTab(tabName)
    -- Hide all tab frames
    for name, frame in pairs(tabFrames) do
        if frame then
            frame:Hide()
        end
    end
    
    -- Deselect all tabs
    for name, tab in pairs(tabs) do
        tab.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        tab.text:SetTextColor(0.8, 0.8, 0.8)
        tab.selected:Hide()
    end
    
    -- Show selected tab frame
    if tabFrames[tabName] then
        tabFrames[tabName]:Show()
    end
    
    -- Highlight selected tab
    if tabs[tabName] then
        tabs[tabName].bg:SetColorTexture(0.3, 0.3, 0.3, 0.9)
        tabs[tabName].text:SetTextColor(1, 0.8, 0)
        tabs[tabName].selected:Show()
    end
    
    currentTab = tabName
end

-- Helper function to create a slider
function SettingsMenu:CreateSlider(parent, label, min, max, step, value, x, y, onChange)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetSize(200, 20)
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetMinMaxValues(min, max)
    slider:SetValue(value)
    slider:SetValueStep(step)
    
    local bg = slider:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(20, 20)
    thumb:SetColorTexture(1, 0.8, 0, 0.8)
    slider:SetThumbTexture(thumb)
    
    local labelText = parent:CreateFontString(nil, "OVERLAY")
    labelText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    labelText:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 3)
    labelText:SetText(label)
    
    local valueText = parent:CreateFontString(nil, "OVERLAY")
    valueText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valueText:SetText(string.format("%.2f", value))
    
    slider:SetScript("OnValueChanged", function(self, val)
        valueText:SetText(string.format("%.2f", val))
        if onChange then
            onChange(val)
        end
    end)
    
    return slider
end

-- Helper function to create a checkbox
function SettingsMenu:CreateCheckbox(parent, label, checked, x, y, onChange)
    local checkbox = CreateFrame("Button", nil, parent)
    checkbox:SetSize(20, 20)
    checkbox:SetPoint("TOPLEFT", x, y)
    
    local bg = checkbox:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    local check = checkbox:CreateTexture(nil, "OVERLAY")
    check:SetSize(16, 16)
    check:SetPoint("CENTER")
    check:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
    checkbox.check = check
    
    if checked then
        check:Show()
    else
        check:Hide()
    end
    
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    text:SetText(label)
    
    checkbox.isChecked = checked
    
    checkbox:SetScript("OnClick", function(self)
        self.isChecked = not self.isChecked
        if self.isChecked then
            self.check:Show()
        else
            self.check:Hide()
        end
        if onChange then
            onChange(self.isChecked)
        end
    end)
    
    return checkbox
end

-- Helper function to create a button
function SettingsMenu:CreateButton(parent, label, width, height, x, y, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button:SetPoint("TOPLEFT", x, y)
    
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    button.bg = bg
    
    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    text:SetPoint("CENTER")
    text:SetText(label)
    
    button:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.4, 0.4, 0.4, 0.9)
    end)
    
    button:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    end)
    
    button:SetScript("OnClick", onClick)
    
    return button
end

-- General Tab
function SettingsMenu:CreateGeneralTab()
    local frame = CreateFrame("Frame", nil, self.contentArea)
    frame:SetAllPoints()
    frame:Hide()
    
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetTextColor(1, 0.8, 0)
    title:SetText("General Settings")
    
    -- Lock all frames
    self:CreateCheckbox(frame, "Lock All Frames", 
        AzeriteMOP.db.playerFrame.locked, 
        20, -60,
        function(checked)
            AzeriteMOP.db.playerFrame.locked = checked
            AzeriteMOP.db.targetFrame.locked = checked
            AzeriteMOP:UpdateFrameLocks()
        end
    )
    
    -- Global UI Scale
    self:CreateCheckbox(frame, "Use Global UI Scale", 
        AzeriteMOP.db.global.useGlobalScale, 
        20, -90,
        function(checked)
            AzeriteMOP.db.global.useGlobalScale = checked
            if checked then
                AzeriteMOP:ApplyGlobalScale()
            else
                AzeriteMOP:RestoreIndividualScales()
            end
        end
    )
    
    self:CreateSlider(frame, "Global UI Scale", 
        0.5, 2.0, 0.05, 
        AzeriteMOP.db.global.uiScale or 1.0,
        250, -90,
        function(value)
            AzeriteMOP.db.global.uiScale = value
            if AzeriteMOP.db.global.useGlobalScale then
                AzeriteMOP:ApplyGlobalScale()
            end
        end
    )
    
    -- Class colors
    self:CreateCheckbox(frame, "Use Class Colors for Health Bars", 
        AzeriteMOP.db.colors.useClassColors, 
        20, -130,
        function(checked)
            AzeriteMOP.db.colors.useClassColors = checked
            AzeriteMOP:UpdateAllColors()
        end
    )
    
    -- Reset button
    self:CreateButton(frame, "Reset All Positions", 
        150, 30, 20, -170,
        function()
            AzeriteMOP:ResetFramePositions()
            print("|cFF4488FF[AzeriteMOP]|r All frame positions reset!")
        end
    )
    
    -- Reload UI button
    self:CreateButton(frame, "Reload UI", 
        100, 30, 180, -170,
        function()
            ReloadUI()
        end
    )
    
    tabFrames["General"] = frame
end

-- Frames Tab
function SettingsMenu:CreateFramesTab()
    local frame = CreateFrame("ScrollFrame", nil, self.contentArea)
    frame:SetAllPoints()
    frame:Hide()
    
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(MENU_WIDTH - 40, 1000)  -- Increased for nameplate settings
    frame:SetScrollChild(scrollChild)
    
    -- Create scrollbar
    local scrollBar = CreateFrame("Slider", nil, frame)
    scrollBar:SetPoint("TOPRIGHT", -5, -5)
    scrollBar:SetPoint("BOTTOMRIGHT", -5, 5)
    scrollBar:SetWidth(16)
    
    -- Set scrollbar range after frame is shown
    local function UpdateScrollRange()
        local contentHeight = 1000  -- Total content height for Frames tab (increased)
        local frameHeight = frame:GetHeight()
        if frameHeight and frameHeight > 0 then
            local scrollRange = math.max(0, contentHeight - frameHeight)
            scrollBar:SetMinMaxValues(0, scrollRange)
        else
            scrollBar:SetMinMaxValues(0, 500)  -- Default fallback (increased)
        end
    end
    
    frame:SetScript("OnShow", UpdateScrollRange)
    scrollBar:SetMinMaxValues(0, 300)  -- Initial values
    scrollBar:SetValue(0)
    scrollBar:SetValueStep(20)
    
    local scrollBg = scrollBar:CreateTexture(nil, "BACKGROUND")
    scrollBg:SetAllPoints()
    scrollBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    
    local scrollThumb = scrollBar:CreateTexture(nil, "OVERLAY")
    scrollThumb:SetSize(16, 30)
    scrollThumb:SetColorTexture(0.6, 0.6, 0.6, 0.8)
    scrollBar:SetThumbTexture(scrollThumb)
    
    scrollBar:SetScript("OnValueChanged", function(self, value)
        frame:SetVerticalScroll(value)
    end)
    
    -- Enable mouse wheel scrolling
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        local newValue = current - (delta * 20)
        
        -- Clamp the value to valid range
        if newValue < min then
            newValue = min
        elseif newValue > max then
            newValue = max
        end
        
        scrollBar:SetValue(newValue)
    end)
    
    local title = scrollChild:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetTextColor(1, 0.8, 0)
    title:SetText("Frame Settings")
    
    local yOffset = -60
    
    -- Player Frame Section
    local playerTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    playerTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    playerTitle:SetPoint("TOPLEFT", 20, yOffset)
    playerTitle:SetTextColor(0.8, 1, 0.8)
    playerTitle:SetText("Player Frame")
    yOffset = yOffset - 30
    
    self:CreateCheckbox(scrollChild, "Enable Player Frame", 
        AzeriteMOP.db.playerFrame.enabled ~= false, 
        20, yOffset,
        function(checked)
            AzeriteMOP.db.playerFrame.enabled = checked
            if AzeriteMOP.PlayerFrame and AzeriteMOP.PlayerFrame.frame then
                if checked then
                    AzeriteMOP.PlayerFrame.frame:Show()
                else
                    AzeriteMOP.PlayerFrame.frame:Hide()
                end
            end
        end
    )
    
    self:CreateSlider(scrollChild, "Player Frame Scale", 
        0.5, 2.0, 0.05, 
        AzeriteMOP.db.playerFrame.scale or 1.0,
        250, yOffset,
        function(value)
            AzeriteMOP.db.playerFrame.scale = value
            if AzeriteMOP.PlayerFrame and AzeriteMOP.PlayerFrame.frame then
                AzeriteMOP.PlayerFrame.frame:SetScale(value)
            end
        end
    )
    
    self:CreateButton(scrollChild, "Reset Position", 
        120, 25, 470, yOffset,
        function()
            AzeriteMOP.db.playerFrame.position = {"CENTER", "UIParent", "CENTER", 0, -150}
            if AzeriteMOP.PlayerFrame and AzeriteMOP.PlayerFrame.frame then
                AzeriteMOP.PlayerFrame.frame:ClearAllPoints()
                AzeriteMOP.PlayerFrame.frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
            end
        end
    )
    yOffset = yOffset - 50
    
    -- Target Frame Section
    local targetTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    targetTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    targetTitle:SetPoint("TOPLEFT", 20, yOffset)
    targetTitle:SetTextColor(1, 0.8, 0.8)
    targetTitle:SetText("Target Frame")
    yOffset = yOffset - 30
    
    self:CreateCheckbox(scrollChild, "Enable Target Frame", 
        AzeriteMOP.db.targetFrame.enabled ~= false, 
        20, yOffset,
        function(checked)
            AzeriteMOP.db.targetFrame.enabled = checked
            if AzeriteMOP.TargetFrame and AzeriteMOP.TargetFrame.frame then
                if checked and UnitExists("target") then
                    AzeriteMOP.TargetFrame.frame:Show()
                elseif not checked then
                    AzeriteMOP.TargetFrame.frame:Hide()
                end
            end
        end
    )
    
    self:CreateSlider(scrollChild, "Target Frame Scale", 
        0.5, 2.0, 0.05, 
        AzeriteMOP.db.targetFrame.scale or 1.0,
        250, yOffset,
        function(value)
            AzeriteMOP.db.targetFrame.scale = value
            if AzeriteMOP.TargetFrame then
                AzeriteMOP.TargetFrame:UpdateScaling()
            end
        end
    )
    
    self:CreateButton(scrollChild, "Reset Position", 
        120, 25, 470, yOffset,
        function()
            AzeriteMOP.db.targetFrame.position = {"CENTER", "UIParent", "CENTER", 0, 150}
            if AzeriteMOP.TargetFrame and AzeriteMOP.TargetFrame.frame then
                AzeriteMOP.TargetFrame.frame:ClearAllPoints()
                AzeriteMOP.TargetFrame.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
            end
        end
    )
    yOffset = yOffset - 50
    
    -- Font Settings Section
    local fontTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    fontTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    fontTitle:SetPoint("TOPLEFT", 20, yOffset)
    fontTitle:SetTextColor(1, 1, 0.8)
    fontTitle:SetText("Font Settings")
    yOffset = yOffset - 30
    
    self:CreateSlider(scrollChild, "Player Font Scale", 
        0.5, 2.0, 0.05, 
        AzeriteMOP.db.playerFrame.fontScale or 1.0,
        20, yOffset,
        function(value)
            AzeriteMOP.db.playerFrame.fontScale = value
            if AzeriteMOP.PlayerFrame and AzeriteMOP.PlayerFrame.ScaleFonts then
                AzeriteMOP.PlayerFrame:ScaleFonts(value)
            end
        end
    )
    
    self:CreateSlider(scrollChild, "Target Font Scale", 
        0.5, 2.0, 0.05, 
        AzeriteMOP.db.targetFrame.fontScale or 1.0,
        250, yOffset,
        function(value)
            AzeriteMOP.db.targetFrame.fontScale = value
            if AzeriteMOP.TargetFrame and AzeriteMOP.TargetFrame.ScaleFonts then
                AzeriteMOP.TargetFrame:ScaleFonts(value)
            end
        end
    )
    
    self:CreateButton(scrollChild, "Reset Fonts", 
        120, 25, 470, yOffset,
        function()
            AzeriteMOP.db.playerFrame.fontScale = 1.0
            AzeriteMOP.db.targetFrame.fontScale = 1.0
            if AzeriteMOP.PlayerFrame and AzeriteMOP.PlayerFrame.ResetFonts then
                AzeriteMOP.PlayerFrame:ResetFonts()
            end
            if AzeriteMOP.TargetFrame and AzeriteMOP.TargetFrame.ResetFonts then
                AzeriteMOP.TargetFrame:ResetFonts()
            end
        end
    )
    yOffset = yOffset - 50
    
    -- Nameplate Settings Section
    local nameplateTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    nameplateTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    nameplateTitle:SetPoint("TOPLEFT", 20, yOffset)
    nameplateTitle:SetTextColor(1, 0.8, 1)
    nameplateTitle:SetText("Nameplate Settings")
    yOffset = yOffset - 30
    
    self:CreateSlider(scrollChild, "Nameplate Scale", 
        0.5, 2.0, 0.05, 
        AzeriteMOP.db.nameplate and AzeriteMOP.db.nameplate.scale or 1.0,
        20, yOffset,
        function(value)
            if not AzeriteMOP.db.nameplate then
                AzeriteMOP.db.nameplate = {}
            end
            AzeriteMOP.db.nameplate.scale = value
            if AzeriteMOP.Nameplate then
                -- Apply scale to all active nameplates
                for frame, customPlate in pairs(AzeriteMOP.Nameplate.activePlates or {}) do
                    if customPlate and customPlate.container then
                        customPlate.container:SetScale(value)
                    end
                end
            end
        end
    )
    
    self:CreateSlider(scrollChild, "Nameplate Width", 
        60, 200, 5, 
        AzeriteMOP.db.nameplate and AzeriteMOP.db.nameplate.width or 120,
        250, yOffset,
        function(value)
            if not AzeriteMOP.db.nameplate then
                AzeriteMOP.db.nameplate = {}
            end
            AzeriteMOP.db.nameplate.width = value
            if AzeriteMOP.Nameplate then
                -- Update width for all active nameplates
                for frame, customPlate in pairs(AzeriteMOP.Nameplate.activePlates or {}) do
                    if customPlate then
                        -- Update container and all width-dependent elements
                        if customPlate.container then
                            customPlate.container:SetWidth(value)
                        end
                        if customPlate.healthBar then
                            customPlate.healthBar:SetWidth(value)
                        end
                        if customPlate.castBar then
                            customPlate.castBar:SetWidth(value)
                        end
                        -- Update backdrop and border to match new width
                        if customPlate.backdrop then
                            customPlate.backdrop:SetPoint("TOPLEFT", customPlate.container, "TOPLEFT", -4, 4)
                            customPlate.backdrop:SetPoint("BOTTOMRIGHT", customPlate.container, "BOTTOMRIGHT", 4, -4)
                        end
                        if customPlate.borderTexture then
                            customPlate.borderTexture:SetPoint("TOPLEFT", customPlate.container, "TOPLEFT", -4, 4)
                            customPlate.borderTexture:SetPoint("BOTTOMRIGHT", customPlate.container, "BOTTOMRIGHT", 4, -4)
                        end
                    end
                end
            end
        end
    )
    
    self:CreateSlider(scrollChild, "Nameplate Height", 
        8, 30, 1, 
        AzeriteMOP.db.nameplate and AzeriteMOP.db.nameplate.height or 12,
        470, yOffset,
        function(value)
            if not AzeriteMOP.db.nameplate then
                AzeriteMOP.db.nameplate = {}
            end
            AzeriteMOP.db.nameplate.height = value
            if AzeriteMOP.Nameplate then
                -- Update height for all active nameplates
                for frame, customPlate in pairs(AzeriteMOP.Nameplate.activePlates or {}) do
                    if customPlate then
                        -- Update container and all height-dependent elements
                        if customPlate.container then
                            customPlate.container:SetHeight(value)
                        end
                        if customPlate.healthBar then
                            customPlate.healthBar:SetHeight(value)
                        end
                        -- Update backdrop and border to match new height
                        if customPlate.backdrop then
                            customPlate.backdrop:SetPoint("TOPLEFT", customPlate.container, "TOPLEFT", -4, 4)
                            customPlate.backdrop:SetPoint("BOTTOMRIGHT", customPlate.container, "BOTTOMRIGHT", 4, -4)
                        end
                        if customPlate.borderTexture then
                            customPlate.borderTexture:SetPoint("TOPLEFT", customPlate.container, "TOPLEFT", -4, 4)
                            customPlate.borderTexture:SetPoint("BOTTOMRIGHT", customPlate.container, "BOTTOMRIGHT", 4, -4)
                        end
                    end
                end
            end
        end
    )
    yOffset = yOffset - 35
    
    -- Cast Bar specific settings
    local castBarLabel = scrollChild:CreateFontString(nil, "OVERLAY")
    castBarLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    castBarLabel:SetPoint("TOPLEFT", 20, yOffset)
    castBarLabel:SetTextColor(0.8, 0.8, 1)
    castBarLabel:SetText("Cast Bar Dimensions:")
    yOffset = yOffset - 25
    
    self:CreateSlider(scrollChild, "Cast Bar Width", 
        60, 200, 5, 
        AzeriteMOP.db.nameplate and AzeriteMOP.db.nameplate.castBarWidth or 120,
        20, yOffset,
        function(value)
            if not AzeriteMOP.db.nameplate then
                AzeriteMOP.db.nameplate = {}
            end
            AzeriteMOP.db.nameplate.castBarWidth = value
            if AzeriteMOP.Nameplate then
                -- Update cast bar width for all active nameplates
                for frame, customPlate in pairs(AzeriteMOP.Nameplate.activePlates or {}) do
                    if customPlate and customPlate.castBar then
                        customPlate.castBar:SetWidth(value)
                        -- Update cast bar backgrounds and borders
                        if customPlate.castBackdrop then
                            customPlate.castBackdrop:SetPoint("TOPLEFT", customPlate.castBar, "TOPLEFT", -4, 4)
                            customPlate.castBackdrop:SetPoint("BOTTOMRIGHT", customPlate.castBar, "BOTTOMRIGHT", 4, -4)
                        end
                        if customPlate.castBorder then
                            customPlate.castBorder:SetPoint("TOPLEFT", customPlate.castBar, "TOPLEFT", -4, 4)
                            customPlate.castBorder:SetPoint("BOTTOMRIGHT", customPlate.castBar, "BOTTOMRIGHT", 4, -4)
                        end
                        -- Update cast text width
                        if customPlate.castText then
                            customPlate.castText:SetWidth(value - 4)
                        end
                    end
                end
            end
        end
    )
    
    self:CreateSlider(scrollChild, "Cast Bar Height", 
        5, 30, 1, 
        AzeriteMOP.db.nameplate and AzeriteMOP.db.nameplate.castBarHeight or 10,
        250, yOffset,
        function(value)
            if not AzeriteMOP.db.nameplate then
                AzeriteMOP.db.nameplate = {}
            end
            AzeriteMOP.db.nameplate.castBarHeight = value
            if AzeriteMOP.Nameplate then
                -- Update cast bar height for all active nameplates
                for frame, customPlate in pairs(AzeriteMOP.Nameplate.activePlates or {}) do
                    if customPlate and customPlate.castBar then
                        customPlate.castBar:SetHeight(value)
                        -- Update cast bar backgrounds and borders
                        if customPlate.castBackdrop then
                            customPlate.castBackdrop:SetPoint("TOPLEFT", customPlate.castBar, "TOPLEFT", -4, 4)
                            customPlate.castBackdrop:SetPoint("BOTTOMRIGHT", customPlate.castBar, "BOTTOMRIGHT", 4, -4)
                        end
                        if customPlate.castBorder then
                            customPlate.castBorder:SetPoint("TOPLEFT", customPlate.castBar, "TOPLEFT", -4, 4)
                            customPlate.castBorder:SetPoint("BOTTOMRIGHT", customPlate.castBar, "BOTTOMRIGHT", 4, -4)
                        end
                        -- Update cast text height
                        if customPlate.castText then
                            customPlate.castText:SetHeight(value)
                        end
                        if customPlate.castTextFrame then
                            customPlate.castTextFrame:SetAllPoints(customPlate.castBar)
                        end
                    end
                end
            end
        end
    )
    yOffset = yOffset - 35
    
    -- Target Frame Cast Bar settings
    local targetCastBarLabel = scrollChild:CreateFontString(nil, "OVERLAY")
    targetCastBarLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    targetCastBarLabel:SetPoint("TOPLEFT", 20, yOffset)
    targetCastBarLabel:SetTextColor(1, 0.8, 0.8)
    targetCastBarLabel:SetText("Target Frame Cast Bar:")
    yOffset = yOffset - 25
    
    self:CreateSlider(scrollChild, "Target Cast Bar Width", 
        100, 300, 5, 
        AzeriteMOP.db.targetFrame and AzeriteMOP.db.targetFrame.castBarWidth or 200,
        20, yOffset,
        function(value)
            if not AzeriteMOP.db.targetFrame then
                AzeriteMOP.db.targetFrame = {}
            end
            AzeriteMOP.db.targetFrame.castBarWidth = value
            if AzeriteMOP.TargetFrame and AzeriteMOP.TargetFrame.castBG then
                AzeriteMOP.TargetFrame.castBG:SetWidth(value)
                AzeriteMOP.TargetFrame.castBar:SetWidth(value)
            end
        end
    )
    
    self:CreateSlider(scrollChild, "Target Cast Bar Height", 
        10, 40, 1, 
        AzeriteMOP.db.targetFrame and AzeriteMOP.db.targetFrame.castBarHeight or 20,
        250, yOffset,
        function(value)
            if not AzeriteMOP.db.targetFrame then
                AzeriteMOP.db.targetFrame = {}
            end
            AzeriteMOP.db.targetFrame.castBarHeight = value
            if AzeriteMOP.TargetFrame and AzeriteMOP.TargetFrame.castBG then
                AzeriteMOP.TargetFrame.castBG:SetHeight(value)
                AzeriteMOP.TargetFrame.castBar:SetHeight(value)
            end
        end
    )
    
    self:CreateButton(scrollChild, "Reset Nameplates", 
        120, 25, 470, yOffset,
        function()
            if AzeriteMOP.db.nameplate then
                AzeriteMOP.db.nameplate.scale = 1.0
                AzeriteMOP.db.nameplate.castBarHeight = 10
            end
            if AzeriteMOP.Nameplate then
                -- Reset all nameplate scales
                for frame, customPlate in pairs(AzeriteMOP.Nameplate.activePlates or {}) do
                    if customPlate and customPlate.container then
                        customPlate.container:SetScale(1.0)
                    end
                    if customPlate and customPlate.castBar then
                        customPlate.castBar:SetHeight(10)
                    end
                end
            end
        end
    )
    
    tabFrames["Frames"] = frame
end

-- Explorer Mode Tab
function SettingsMenu:CreateExplorerTab()
    local frame = CreateFrame("Frame", nil, self.contentArea)
    frame:SetAllPoints()
    frame:Hide()
    
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetTextColor(1, 0.8, 0)
    title:SetText("Explorer Mode Settings")
    
    -- Enable Explorer Mode
    self:CreateCheckbox(frame, "Enable Explorer Mode", 
        AzeriteMOP.db.explorerMode.enabled, 
        20, -60,
        function(checked)
            AzeriteMOP.db.explorerMode.enabled = checked
            if AzeriteMOP.ExplorerMode then
                if checked then
                    AzeriteMOP.ExplorerMode:ForceEnable()
                else
                    AzeriteMOP.ExplorerMode:ForceDisable()
                end
            end
        end
    )
    
    -- Hide options
    self:CreateCheckbox(frame, "Hide Quest Log", 
        AzeriteMOP.db.explorerMode.hideQuestLog, 
        20, -90,
        function(checked)
            AzeriteMOP.db.explorerMode.hideQuestLog = checked
        end
    )
    
    self:CreateCheckbox(frame, "Hide Chat Frame", 
        AzeriteMOP.db.explorerMode.hideChatFrame, 
        200, -90,
        function(checked)
            AzeriteMOP.db.explorerMode.hideChatFrame = checked
        end
    )
    
    self:CreateCheckbox(frame, "Hide Minimap", 
        AzeriteMOP.db.explorerMode.hideMinimap, 
        380, -90,
        function(checked)
            AzeriteMOP.db.explorerMode.hideMinimap = checked
        end
    )
    
    self:CreateCheckbox(frame, "Hide Action Bars", 
        AzeriteMOP.db.explorerMode.hideActionBars, 
        20, -120,
        function(checked)
            AzeriteMOP.db.explorerMode.hideActionBars = checked
        end
    )
    
    self:CreateCheckbox(frame, "Hide Buffs/Debuffs", 
        AzeriteMOP.db.explorerMode.hideBuffs ~= false, 
        200, -120,
        function(checked)
            AzeriteMOP.db.explorerMode.hideBuffs = checked
        end
    )
    
    self:CreateCheckbox(frame, "Hide Unit Frames", 
        AzeriteMOP.db.explorerMode.hideUnitFrames ~= false, 
        380, -120,
        function(checked)
            AzeriteMOP.db.explorerMode.hideUnitFrames = checked
        end
    )
    
    -- Stationary delay slider
    self:CreateSlider(frame, "UI Hide Delay (seconds)", 
        5, 60, 1, 
        AzeriteMOP.db.explorerMode.stationaryDelay or 30,
        20, -170,
        function(value)
            AzeriteMOP.db.explorerMode.stationaryDelay = value
        end
    )
    
    -- Movement threshold
    self:CreateSlider(frame, "Movement Sensitivity", 
        0.01, 1.0, 0.01, 
        AzeriteMOP.db.explorerMode.movementThreshold or 0.1,
        250, -170,
        function(value)
            AzeriteMOP.db.explorerMode.movementThreshold = value
        end
    )
    
    -- Keybind info
    local keybindInfo = frame:CreateFontString(nil, "OVERLAY")
    keybindInfo:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    keybindInfo:SetPoint("TOPLEFT", 20, -230)
    keybindInfo:SetTextColor(0.7, 0.7, 0.7)
    keybindInfo:SetText("Tip: Press ALT+Z to quickly toggle the UI visibility")
    
    tabFrames["Explorer"] = frame
end

-- Chat Settings Tab
function SettingsMenu:CreateChatTab()
    local frame = CreateFrame("Frame", nil, self.contentArea)
    frame:SetAllPoints()
    frame:Hide()
    
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetTextColor(1, 0.8, 0)
    title:SetText("Chat Settings")
    
    -- Enable chat enhancements
    self:CreateCheckbox(frame, "Enable Chat Enhancements", 
        AzeriteMOP.db.chatFrame.enabled, 
        20, -60,
        function(checked)
            AzeriteMOP.db.chatFrame.enabled = checked
            if AzeriteMOP.ChatFrame then
                AzeriteMOP.ChatFrame:Toggle()
            end
        end
    )
    
    -- Chat options
    self:CreateCheckbox(frame, "Enable Chat Fade", 
        AzeriteMOP.db.chatFrame.fadeChat, 
        20, -90,
        function(checked)
            AzeriteMOP.db.chatFrame.fadeChat = checked
        end
    )
    
    self:CreateCheckbox(frame, "Hide Edit Box When Not Typing", 
        AzeriteMOP.db.chatFrame.hideEditBox, 
        250, -90,
        function(checked)
            AzeriteMOP.db.chatFrame.hideEditBox = checked
        end
    )
    
    self:CreateCheckbox(frame, "Show Timestamps", 
        AzeriteMOP.db.chatFrame.showTimestamps, 
        20, -120,
        function(checked)
            AzeriteMOP.db.chatFrame.showTimestamps = checked
        end
    )
    
    self:CreateCheckbox(frame, "Show Emojis", 
        AzeriteMOP.db.chatFrame.showEmojis ~= false, 
        250, -120,
        function(checked)
            AzeriteMOP.db.chatFrame.showEmojis = checked
        end
    )
    
    self:CreateCheckbox(frame, "Show URLs as Links", 
        AzeriteMOP.db.chatFrame.showURLs ~= false, 
        20, -150,
        function(checked)
            AzeriteMOP.db.chatFrame.showURLs = checked
        end
    )
    
    self:CreateCheckbox(frame, "Show Chat Bubbles", 
        AzeriteMOP.db.chatFrame.showChatBubbles ~= false, 
        250, -150,
        function(checked)
            AzeriteMOP.db.chatFrame.showChatBubbles = checked
        end
    )
    
    -- Scroll settings
    self:CreateSlider(frame, "Lines to Scroll", 
        1, 10, 1, 
        AzeriteMOP.db.chatFrame.numScrollMessages or 3,
        20, -200,
        function(value)
            AzeriteMOP.db.chatFrame.numScrollMessages = value
        end
    )
    
    self:CreateSlider(frame, "Max Copy Lines", 
        50, 500, 10, 
        AzeriteMOP.db.chatFrame.maxCopyLines or 100,
        250, -200,
        function(value)
            AzeriteMOP.db.chatFrame.maxCopyLines = value
        end
    )
    
    -- Copy chat button
    self:CreateButton(frame, "Open Copy Chat Window", 
        180, 30, 20, -260,
        function()
            -- Implement copy chat window
            print("|cFF4488FF[AzeriteMOP]|r Copy chat feature coming soon!")
        end
    )
    
    tabFrames["Chat"] = frame
end

-- Colors Tab
function SettingsMenu:CreateColorsTab()
    local frame = CreateFrame("ScrollFrame", nil, self.contentArea)
    frame:SetAllPoints()
    frame:Hide()
    
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(MENU_WIDTH - 40, 1600)  -- Increased for cast bar and nameplate colors
    frame:SetScrollChild(scrollChild)
    
    -- Create scrollbar
    local scrollBar = CreateFrame("Slider", nil, frame)
    scrollBar:SetPoint("TOPRIGHT", -5, -5)
    scrollBar:SetPoint("BOTTOMRIGHT", -5, 5)
    scrollBar:SetWidth(16)
    
    -- Set scrollbar range after frame is shown
    local function UpdateScrollRange()
        local contentHeight = 1600  -- Total content height for Colors tab (increased)
        local frameHeight = frame:GetHeight()
        if frameHeight and frameHeight > 0 then
            local scrollRange = math.max(0, contentHeight - frameHeight)
            scrollBar:SetMinMaxValues(0, scrollRange)
        else
            scrollBar:SetMinMaxValues(0, 1000)  -- Default fallback (increased)
        end
    end
    
    frame:SetScript("OnShow", UpdateScrollRange)
    scrollBar:SetMinMaxValues(0, 600)  -- Initial values
    scrollBar:SetValue(0)
    scrollBar:SetValueStep(20)
    
    local scrollBg = scrollBar:CreateTexture(nil, "BACKGROUND")
    scrollBg:SetAllPoints()
    scrollBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    
    local scrollThumb = scrollBar:CreateTexture(nil, "OVERLAY")
    scrollThumb:SetSize(16, 30)
    scrollThumb:SetColorTexture(0.6, 0.6, 0.6, 0.8)
    scrollBar:SetThumbTexture(scrollThumb)
    
    scrollBar:SetScript("OnValueChanged", function(self, value)
        frame:SetVerticalScroll(value)
    end)
    
    -- Enable mouse wheel scrolling
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        local newValue = current - (delta * 20)
        
        -- Clamp the value to valid range
        if newValue < min then
            newValue = min
        elseif newValue > max then
            newValue = max
        end
        
        scrollBar:SetValue(newValue)
    end)
    
    local title = scrollChild:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetTextColor(1, 0.8, 0)
    title:SetText("Color Settings")
    
    local yOffset = -60
    
    -- Helper function to create color display
    local function CreateColorDisplay(parent, label, colorKey, x, y)
        local container = CreateFrame("Frame", nil, parent)
        container:SetSize(250, 30)
        container:SetPoint("TOPLEFT", x, y)
        
        local text = container:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        text:SetPoint("LEFT")
        text:SetWidth(150)
        text:SetJustifyH("LEFT")
        text:SetText(label)
        
        local swatch = CreateFrame("Button", nil, container)
        swatch:SetSize(24, 24)
        swatch:SetPoint("LEFT", text, "RIGHT", 5, 0)
        
        local bg = swatch:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 1)
        
        local color = swatch:CreateTexture(nil, "OVERLAY")
        color:SetPoint("TOPLEFT", bg, "TOPLEFT", 2, -2)
        color:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -2, 2)
        
        local r, g, b = AzeriteMOP:GetColor(colorKey)
        color:SetColorTexture(r, g, b, 1)
        
        local resetBtn = CreateFrame("Button", nil, container)
        resetBtn:SetSize(40, 20)
        resetBtn:SetPoint("LEFT", swatch, "RIGHT", 5, 0)
        
        local resetBg = resetBtn:CreateTexture(nil, "BACKGROUND")
        resetBg:SetAllPoints()
        resetBg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
        
        local resetText = resetBtn:CreateFontString(nil, "OVERLAY")
        resetText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        resetText:SetPoint("CENTER")
        resetText:SetText("Reset")
        
        swatch:SetScript("OnClick", function()
            -- Create a color palette popup
            local popup = CreateFrame("Frame", "AzeriteMOPColorPalette", UIParent)
            popup:SetSize(340, 480)  -- Larger to fit more colors
            popup:SetPoint("CENTER")
            popup:SetFrameStrata("DIALOG")
            popup:SetFrameLevel(100)
            
            -- Background
            local popupBg = popup:CreateTexture(nil, "BACKGROUND")
            popupBg:SetAllPoints()
            popupBg:SetColorTexture(0.1, 0.1, 0.1, 0.95)
            
            -- Border
            local popupBorder = popup:CreateTexture(nil, "BORDER")
            popupBorder:SetPoint("TOPLEFT", -2, 2)
            popupBorder:SetPoint("BOTTOMRIGHT", 2, -2)
            popupBorder:SetColorTexture(0.4, 0.4, 0.4, 1)
            
            -- Title
            local popupTitle = popup:CreateFontString(nil, "OVERLAY")
            popupTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
            popupTitle:SetPoint("TOP", 0, -10)
            popupTitle:SetText("Choose Color for " .. label)
            popupTitle:SetTextColor(1, 0.8, 0)
            
            -- Preset colors (10x12 grid = 120 colors) organized by hue
            local presetColors = {
                -- Row 1: WoW Class Colors (11 classes + extra)
                {0.78, 0.61, 0.43}, -- Warrior
                {0.96, 0.55, 0.73}, -- Paladin
                {0.67, 0.83, 0.45}, -- Hunter
                {1.00, 0.96, 0.41}, -- Rogue
                {1.00, 1.00, 1.00}, -- Priest
                {0.77, 0.12, 0.23}, -- Death Knight
                {0.00, 0.44, 0.87}, -- Shaman
                {0.41, 0.80, 0.94}, -- Mage
                {0.58, 0.51, 0.79}, -- Warlock
                {0.00, 1.00, 0.59}, -- Monk
                
                -- Row 2: Reds (Deep to Light)
                {0.3, 0.0, 0.0},    -- Very Dark Red
                {0.5, 0.0, 0.0},    -- Dark Red
                {0.7, 0.0, 0.0},    -- Crimson
                {0.9, 0.0, 0.0},    -- Red
                {1.0, 0.0, 0.0},    -- Pure Red
                {1.0, 0.1, 0.1},    -- Bright Red
                {1.0, 0.3, 0.3},    -- Light Red
                {1.0, 0.5, 0.5},    -- Salmon
                {1.0, 0.7, 0.7},    -- Light Salmon
                {1.0, 0.85, 0.85},  -- Very Light Red
                
                -- Row 3: Red-Oranges and Corals
                {0.8, 0.2, 0.0},    -- Dark Orange Red
                {0.9, 0.3, 0.1},    -- Rust
                {1.0, 0.4, 0.2},    -- Coral
                {1.0, 0.5, 0.3},    -- Light Coral
                {1.0, 0.6, 0.4},    -- Peach
                {1.0, 0.27, 0.0},   -- Red Orange
                {1.0, 0.39, 0.28},  -- Light Salmon
                {0.98, 0.5, 0.45},  -- Salmon Pink
                {0.94, 0.5, 0.5},   -- Light Coral
                {1.0, 0.63, 0.48},  -- Light Peach
                
                -- Row 4: Oranges
                {0.8, 0.4, 0.0},    -- Dark Orange
                {1.0, 0.5, 0.0},    -- Orange
                {1.0, 0.6, 0.0},    -- Bright Orange
                {1.0, 0.65, 0.0},   -- Dark Goldenrod
                {1.0, 0.7, 0.0},    -- Gold
                {1.0, 0.75, 0.0},   -- Amber
                {1.0, 0.55, 0.15},  -- Tangerine
                {1.0, 0.65, 0.3},   -- Light Orange
                {1.0, 0.75, 0.45},  -- Pale Orange
                {1.0, 0.85, 0.6},   -- Very Light Orange
                
                -- Row 5: Yellows and Golds
                {0.7, 0.7, 0.0},    -- Dark Yellow
                {0.85, 0.85, 0.0},  -- Gold Yellow
                {1.0, 1.0, 0.0},    -- Pure Yellow
                {1.0, 1.0, 0.2},    -- Light Yellow
                {1.0, 1.0, 0.4},    -- Pale Yellow
                {1.0, 1.0, 0.6},    -- Cream
                {1.0, 0.84, 0.0},   -- Golden
                {1.0, 0.9, 0.4},    -- Khaki
                {0.94, 0.9, 0.55},  -- Light Khaki
                {1.0, 0.96, 0.8},   -- Lemon Chiffon
                
                -- Row 6: Yellow-Greens and Limes
                {0.5, 0.7, 0.0},    -- Olive Green
                {0.6, 0.8, 0.2},    -- Yellow Green
                {0.7, 0.9, 0.3},    -- Spring Green
                {0.8, 1.0, 0.2},    -- Lime Yellow
                {0.75, 1.0, 0.0},   -- Chartreuse
                {0.5, 1.0, 0.0},    -- Lime
                {0.6, 1.0, 0.4},    -- Light Lime
                {0.7, 1.0, 0.6},    -- Pale Lime
                {0.8, 1.0, 0.8},    -- Very Light Lime
                {0.9, 1.0, 0.9},    -- Near White Green
                
                -- Row 7: Greens
                {0.0, 0.3, 0.0},    -- Very Dark Green
                {0.0, 0.5, 0.0},    -- Dark Green
                {0.0, 0.7, 0.0},    -- Forest Green
                {0.0, 0.9, 0.0},    -- Green
                {0.0, 1.0, 0.0},    -- Pure Green
                {0.2, 1.0, 0.2},    -- Light Green
                {0.4, 1.0, 0.4},    -- Pale Green
                {0.13, 0.55, 0.13}, -- Forest
                {0.0, 0.39, 0.0},   -- Dark Olive
                {0.56, 0.93, 0.56}, -- Light Green
                
                -- Row 8: Teals and Aquas
                {0.0, 0.5, 0.5},    -- Dark Teal
                {0.0, 0.7, 0.7},    -- Teal
                {0.0, 0.9, 0.9},    -- Light Teal
                {0.0, 1.0, 1.0},    -- Cyan/Aqua
                {0.2, 1.0, 1.0},    -- Light Cyan
                {0.4, 1.0, 1.0},    -- Pale Cyan
                {0.0, 0.8, 0.8},    -- Dark Cyan
                {0.25, 0.88, 0.82}, -- Turquoise
                {0.4, 0.9, 0.9},    -- Pale Turquoise
                {0.69, 0.88, 0.9},  -- Powder Blue
                
                -- Row 9: Blues
                {0.0, 0.0, 0.3},    -- Very Dark Blue
                {0.0, 0.0, 0.5},    -- Dark Blue
                {0.0, 0.0, 0.7},    -- Navy
                {0.0, 0.0, 0.9},    -- Blue
                {0.0, 0.0, 1.0},    -- Pure Blue
                {0.2, 0.2, 1.0},    -- Light Blue
                {0.4, 0.4, 1.0},    -- Sky Blue
                {0.6, 0.6, 1.0},    -- Pale Blue
                {0.8, 0.8, 1.0},    -- Very Light Blue
                {0.1, 0.3, 0.8},    -- Royal Blue
                
                -- Row 10: Blue-Purples and Indigos
                {0.2, 0.0, 0.5},    -- Dark Indigo
                {0.3, 0.0, 0.7},    -- Indigo
                {0.4, 0.0, 0.9},    -- Blue Purple
                {0.5, 0.0, 1.0},    -- Blue Violet
                {0.54, 0.17, 0.89}, -- Blue Purple
                {0.58, 0.0, 0.83},  -- Dark Violet
                {0.6, 0.2, 1.0},    -- Light Indigo
                {0.7, 0.4, 1.0},    -- Pale Indigo
                {0.29, 0.0, 0.51},  -- Indigo
                {0.42, 0.35, 0.8},  -- Slate Blue
                
                -- Row 11: Purples and Magentas
                {0.5, 0.0, 0.5},    -- Dark Purple
                {0.7, 0.0, 0.7},    -- Purple
                {0.9, 0.0, 0.9},    -- Magenta
                {1.0, 0.0, 1.0},    -- Pure Magenta
                {1.0, 0.2, 1.0},    -- Light Magenta
                {1.0, 0.4, 1.0},    -- Pale Magenta
                {0.8, 0.0, 0.8},    -- Dark Magenta
                {0.73, 0.33, 0.83}, -- Medium Orchid
                {0.86, 0.44, 0.84}, -- Orchid
                {0.87, 0.63, 0.87}, -- Plum
                
                -- Row 12: Grays, Browns, and Neutrals
                {1.0, 1.0, 1.0},    -- White
                {0.9, 0.9, 0.9},    -- Very Light Gray
                {0.75, 0.75, 0.75}, -- Light Gray
                {0.5, 0.5, 0.5},    -- Gray
                {0.3, 0.3, 0.3},    -- Dark Gray
                {0.1, 0.1, 0.1},    -- Very Dark Gray
                {0.0, 0.0, 0.0},    -- Black
                {0.55, 0.27, 0.07}, -- Brown
                {0.82, 0.41, 0.12}, -- Tan
                {0.87, 0.72, 0.53}, -- Beige
            }
            
            -- Create color swatches
            local swatchSize = 26  -- Slightly smaller to fit more
            local spacing = 3
            local startX = 10
            local startY = -40
            
            for i, colorData in ipairs(presetColors) do
                local row = math.floor((i - 1) / 10)  -- 10 columns
                local col = (i - 1) % 10
                
                local colorSwatch = CreateFrame("Button", nil, popup)
                colorSwatch:SetSize(swatchSize, swatchSize)
                colorSwatch:SetPoint("TOPLEFT", startX + col * (swatchSize + spacing), startY - row * (swatchSize + spacing))
                
                -- Swatch background
                local swatchBg = colorSwatch:CreateTexture(nil, "BACKGROUND")
                swatchBg:SetAllPoints()
                swatchBg:SetColorTexture(0, 0, 0, 1)
                
                -- Swatch color
                local swatchColor = colorSwatch:CreateTexture(nil, "OVERLAY")
                swatchColor:SetPoint("TOPLEFT", 2, -2)
                swatchColor:SetPoint("BOTTOMRIGHT", -2, 2)
                swatchColor:SetColorTexture(colorData[1], colorData[2], colorData[3], 1)
                
                -- Highlight on hover
                colorSwatch:SetScript("OnEnter", function(self)
                    swatchBg:SetColorTexture(1, 1, 0, 1)
                end)
                colorSwatch:SetScript("OnLeave", function(self)
                    swatchBg:SetColorTexture(0, 0, 0, 1)
                end)
                
                -- Select color on click
                colorSwatch:SetScript("OnClick", function()
                    AzeriteMOP:SetColor(colorKey, colorData[1], colorData[2], colorData[3])
                    color:SetColorTexture(colorData[1], colorData[2], colorData[3], 1)
                    AzeriteMOP:UpdateAllColors()
                    popup:Hide()
                end)
            end
            
            -- Close button
            local closeBtn = CreateFrame("Button", nil, popup)
            closeBtn:SetSize(80, 25)
            closeBtn:SetPoint("BOTTOM", 0, 10)
            
            local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
            closeBg:SetAllPoints()
            closeBg:SetColorTexture(0.5, 0.2, 0.2, 0.8)
            
            local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
            closeText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            closeText:SetPoint("CENTER")
            closeText:SetText("Cancel")
            
            closeBtn:SetScript("OnClick", function()
                popup:Hide()
            end)
            
            -- Show popup
            popup:Show()
            
            -- Close on escape
            popup:SetScript("OnKeyDown", function(self, key)
                if key == "ESCAPE" then
                    self:Hide()
                end
            end)
            popup:EnableKeyboard(true)
        end)
        
        resetBtn:SetScript("OnClick", function()
            -- Reset to default color
            AzeriteMOP:SetColor(colorKey, nil)
            local r, g, b = AzeriteMOP:GetColor(colorKey)
            color:SetColorTexture(r, g, b, 1)
            AzeriteMOP:UpdateAllColors()
        end)
        
        return container
    end
    
    -- Player Frame Colors
    local playerTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    playerTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    playerTitle:SetPoint("TOPLEFT", 20, yOffset)
    playerTitle:SetTextColor(0.8, 1, 0.8)
    playerTitle:SetText("Player Frame")
    yOffset = yOffset - 30
    
    CreateColorDisplay(scrollChild, "Health Bar", "playerHealth", 20, yOffset)
    CreateColorDisplay(scrollChild, "Power Bar", "playerPower", 280, yOffset)
    yOffset = yOffset - 35
    
    CreateColorDisplay(scrollChild, "Text Color", "playerText", 20, yOffset)
    CreateColorDisplay(scrollChild, "Level Text", "playerLevelText", 280, yOffset)
    yOffset = yOffset - 45
    
    -- Target Frame Colors
    local targetTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    targetTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    targetTitle:SetPoint("TOPLEFT", 20, yOffset)
    targetTitle:SetTextColor(1, 0.8, 0.8)
    targetTitle:SetText("Target Frame")
    yOffset = yOffset - 30
    
    CreateColorDisplay(scrollChild, "Friendly Health", "targetHealthFriendly", 20, yOffset)
    CreateColorDisplay(scrollChild, "Hostile Health", "targetHealthHostile", 280, yOffset)
    CreateColorDisplay(scrollChild, "Neutral Health", "targetHealthNeutral", 540, yOffset)
    yOffset = yOffset - 35
    
    CreateColorDisplay(scrollChild, "Text Color", "targetText", 20, yOffset)
    CreateColorDisplay(scrollChild, "Level Text", "targetLevelText", 280, yOffset)
    yOffset = yOffset - 45
    
    -- Cast Bar Colors
    local castTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    castTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    castTitle:SetPoint("TOPLEFT", 20, yOffset)
    castTitle:SetTextColor(0.8, 0.8, 1)
    castTitle:SetText("Cast Bars")
    yOffset = yOffset - 30
    
    CreateColorDisplay(scrollChild, "Normal Cast", "castBarNormal", 20, yOffset)
    CreateColorDisplay(scrollChild, "Channeled Cast", "castBarChannel", 280, yOffset)
    CreateColorDisplay(scrollChild, "Cast Background", "castBarBg", 540, yOffset)
    yOffset = yOffset - 35
    
    CreateColorDisplay(scrollChild, "Cast Text", "castBarText", 20, yOffset)
    CreateColorDisplay(scrollChild, "Cast Time Text", "castBarTimeText", 280, yOffset)
    yOffset = yOffset - 45
    
    -- Nameplate Colors
    local nameplateTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    nameplateTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    nameplateTitle:SetPoint("TOPLEFT", 20, yOffset)
    nameplateTitle:SetTextColor(1, 0.8, 1)
    nameplateTitle:SetText("Nameplates")
    yOffset = yOffset - 30
    
    CreateColorDisplay(scrollChild, "Friendly Health", "nameplateHealthFriendly", 20, yOffset)
    CreateColorDisplay(scrollChild, "Hostile Health", "nameplateHealthHostile", 280, yOffset)
    CreateColorDisplay(scrollChild, "Neutral Health", "nameplateHealthNeutral", 540, yOffset)
    yOffset = yOffset - 35
    
    CreateColorDisplay(scrollChild, "Nameplate Cast Bar", "nameplateCastBar", 20, yOffset)
    CreateColorDisplay(scrollChild, "Nameplate Text", "nameplateNameText", 280, yOffset)
    CreateColorDisplay(scrollChild, "Nameplate Level", "nameplateLevelText", 540, yOffset)
    yOffset = yOffset - 45
    
    -- Reset all colors button
    self:CreateButton(scrollChild, "Reset All Colors", 
        150, 30, 20, yOffset,
        function()
            -- Reset all colors to defaults
            for key, _ in pairs(AzeriteMOP.db.colors) do
                if type(AzeriteMOP.db.colors[key]) == "table" and AzeriteMOP.db.colors[key].r then
                    AzeriteMOP:SetColor(key, nil)
                end
            end
            AzeriteMOP:UpdateAllColors()
            print("|cFF4488FF[AzeriteMOP]|r All colors reset to defaults!")
        end
    )
    
    tabFrames["Colors"] = frame
end

-- Profiles Tab
function SettingsMenu:CreateProfilesTab()
    local frame = CreateFrame("Frame", nil, self.contentArea)
    frame:SetAllPoints()
    frame:Hide()
    
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetTextColor(1, 0.8, 0)
    title:SetText("Profile Management")
    
    -- Current profile
    local currentLabel = frame:CreateFontString(nil, "OVERLAY")
    currentLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    currentLabel:SetPoint("TOPLEFT", 20, -60)
    currentLabel:SetText("Current Profile:")
    
    self.currentProfileText = frame:CreateFontString(nil, "OVERLAY")
    self.currentProfileText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.currentProfileText:SetPoint("LEFT", currentLabel, "RIGHT", 10, 0)
    self.currentProfileText:SetTextColor(1, 0.8, 0)
    self.currentProfileText:SetText(AzeriteMOP.db.currentProfile or "Default")
    
    -- Profile list
    local listTitle = frame:CreateFontString(nil, "OVERLAY")
    listTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    listTitle:SetPoint("TOPLEFT", 20, -100)
    listTitle:SetText("Available Profiles:")
    
    -- Profile list frame
    local listFrame = CreateFrame("Frame", nil, frame)
    listFrame:SetPoint("TOPLEFT", 20, -120)
    listFrame:SetSize(350, 200)
    
    local listBg = listFrame:CreateTexture(nil, "BACKGROUND")
    listBg:SetAllPoints()
    listBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    
    -- We'll populate this with actual profiles
    local profiles = AzeriteMOP.db.profiles or {}
    local yPos = -5
    
    for name, _ in pairs(profiles) do
        local profileBtn = CreateFrame("Button", nil, listFrame)
        profileBtn:SetSize(340, 25)
        profileBtn:SetPoint("TOPLEFT", 5, yPos)
        
        local btnBg = profileBtn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints()
        btnBg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
        profileBtn.bg = btnBg
        
        local btnText = profileBtn:CreateFontString(nil, "OVERLAY")
        btnText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        btnText:SetPoint("LEFT", 10, 0)
        btnText:SetText(name)
        
        profileBtn:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.3, 0.3, 0.3, 0.7)
        end)
        
        profileBtn:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
        end)
        
        profileBtn:SetScript("OnClick", function()
            AzeriteMOP:LoadProfile(name)
            SettingsMenu.currentProfileText:SetText(name)
            print("|cFF4488FF[AzeriteMOP]|r Loaded profile: " .. name)
        end)
        
        yPos = yPos - 30
    end
    
    -- New profile input
    local inputLabel = frame:CreateFontString(nil, "OVERLAY")
    inputLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    inputLabel:SetPoint("TOPLEFT", 20, -330)
    inputLabel:SetText("Profile Name:")
    
    local profileInput = CreateFrame("EditBox", nil, frame)
    profileInput:SetSize(200, 25)
    profileInput:SetPoint("LEFT", inputLabel, "RIGHT", 10, 0)
    profileInput:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    profileInput:SetAutoFocus(false)
    profileInput:SetMaxLetters(20)
    
    local inputBg = profileInput:CreateTexture(nil, "BACKGROUND")
    inputBg:SetAllPoints()
    inputBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    
    profileInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    profileInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    
    -- Profile action buttons
    self:CreateButton(frame, "Save Profile", 
        100, 30, 400, -120,
        function()
            local name = profileInput:GetText()
            if name and name ~= "" then
                AzeriteMOP:SaveProfile(name)
                profileInput:SetText("")
                print("|cFF4488FF[AzeriteMOP]|r Saved profile: " .. name)
            end
        end
    )
    
    self:CreateButton(frame, "Load Profile", 
        100, 30, 400, -160,
        function()
            local name = profileInput:GetText()
            if name and name ~= "" then
                if AzeriteMOP:LoadProfile(name) then
                    SettingsMenu.currentProfileText:SetText(name)
                    print("|cFF4488FF[AzeriteMOP]|r Loaded profile: " .. name)
                else
                    print("|cFF4488FF[AzeriteMOP]|r Profile not found: " .. name)
                end
            end
        end
    )
    
    self:CreateButton(frame, "Delete Profile", 
        100, 30, 400, -200,
        function()
            local name = profileInput:GetText()
            if name and name ~= "" then
                AzeriteMOP:DeleteProfile(name)
                profileInput:SetText("")
                print("|cFF4488FF[AzeriteMOP]|r Deleted profile: " .. name)
            end
        end
    )
    
    -- Preset profiles info
    local presetInfo = frame:CreateFontString(nil, "OVERLAY")
    presetInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    presetInfo:SetPoint("TOPLEFT", 20, -370)
    presetInfo:SetTextColor(0.6, 0.6, 0.6)
    presetInfo:SetText("Preset profiles available: Default, Compact, Large, PvP, Raid")
    
    tabFrames["Profiles"] = frame
end

-- Show/Hide/Toggle functions
function SettingsMenu:Show()
    self.mainFrame:Show()
    if self.currentProfileText then
        self.currentProfileText:SetText(AzeriteMOP.db.currentProfile or "Default")
    end
end

function SettingsMenu:Hide()
    self.mainFrame:Hide()
end

function SettingsMenu:Toggle()
    if self.mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Export the module
AzeriteMOP.SettingsMenu = SettingsMenu