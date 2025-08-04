-- AzeriteMOP Settings Menu Module (Simplified for MoP Classic)
-- Provides a GUI for configuring all addon settings

local ADDON_NAME, Addon = ...
local AzeriteMOP = Addon.AzeriteMOP

-- Create SettingsMenu module
AzeriteMOP.SettingsMenu = {}
local SettingsMenu = AzeriteMOP.SettingsMenu

-- Constants
local MENU_WIDTH = 800
local MENU_HEIGHT = 600

function SettingsMenu:Initialize()
    AzeriteMOP:Debug("Initializing Settings Menu...")
    
    -- Create the main settings frame
    self:CreateMainFrame()
    
    -- Initially hide the menu
    self.mainFrame:Hide()
    
    AzeriteMOP:Debug("Settings Menu initialized!")
end

function SettingsMenu:CreateMainFrame()
    -- Main frame
    self.mainFrame = CreateFrame("Frame", "AzeriteMOPSettingsFrame", UIParent)
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
    self.mainFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.95)
    
    -- Title
    self.mainFrame.title = self.mainFrame:CreateFontString(nil, "OVERLAY")
    self.mainFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    self.mainFrame.title:SetPoint("TOP", 0, -15)
    self.mainFrame.title:SetTextColor(1, 0.8, 0)
    self.mainFrame.title:SetText("AzeriteMOP Settings")
    
    -- Close button (simple X)
    self.mainFrame.closeButton = CreateFrame("Button", nil, self.mainFrame)
    self.mainFrame.closeButton:SetSize(30, 30)
    self.mainFrame.closeButton:SetPoint("TOPRIGHT", -10, -10)
    
    local closeBg = self.mainFrame.closeButton:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.5, 0, 0, 0.8)
    
    local closeText = self.mainFrame.closeButton:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    
    self.mainFrame.closeButton:SetScript("OnClick", function()
        SettingsMenu:Hide()
    end)
    
    -- Content area
    local contentY = -60
    
    -- Section: Frame Controls
    local frameTitle = self.mainFrame:CreateFontString(nil, "OVERLAY")
    frameTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    frameTitle:SetPoint("TOPLEFT", 30, contentY)
    frameTitle:SetTextColor(1, 0.8, 0)
    frameTitle:SetText("Frame Controls")
    contentY = contentY - 30
    
    -- Lock frames button
    local lockButton = CreateFrame("Button", nil, self.mainFrame)
    lockButton:SetSize(150, 30)
    lockButton:SetPoint("TOPLEFT", 30, contentY)
    
    local lockBg = lockButton:CreateTexture(nil, "BACKGROUND")
    lockBg:SetAllPoints()
    lockBg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    lockButton.bg = lockBg
    
    local lockText = lockButton:CreateFontString(nil, "OVERLAY")
    lockText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    lockText:SetPoint("CENTER")
    
    local function UpdateLockButton()
        if AzeriteMOP.db.playerFrame.locked then
            lockText:SetText("Unlock Frames")
            lockBg:SetColorTexture(0.5, 0.2, 0.2, 0.8)
        else
            lockText:SetText("Lock Frames")
            lockBg:SetColorTexture(0.2, 0.5, 0.2, 0.8)
        end
    end
    
    UpdateLockButton()
    
    lockButton:SetScript("OnClick", function()
        local locked = not AzeriteMOP.db.playerFrame.locked
        AzeriteMOP.db.playerFrame.locked = locked
        AzeriteMOP.db.targetFrame.locked = locked
        AzeriteMOP:UpdateFrameLocks()
        UpdateLockButton()
    end)
    
    -- Reset positions button
    local resetButton = CreateFrame("Button", nil, self.mainFrame)
    resetButton:SetSize(150, 30)
    resetButton:SetPoint("LEFT", lockButton, "RIGHT", 10, 0)
    
    local resetBg = resetButton:CreateTexture(nil, "BACKGROUND")
    resetBg:SetAllPoints()
    resetBg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    local resetText = resetButton:CreateFontString(nil, "OVERLAY")
    resetText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    resetText:SetPoint("CENTER")
    resetText:SetText("Reset Positions")
    
    resetButton:SetScript("OnClick", function()
        AzeriteMOP:ResetFramePositions()
        print("|cFF4488FF[AzeriteMOP]|r Frame positions reset!")
    end)
    
    contentY = contentY - 50
    
    -- Section: Scale Controls
    local scaleTitle = self.mainFrame:CreateFontString(nil, "OVERLAY")
    scaleTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    scaleTitle:SetPoint("TOPLEFT", 30, contentY)
    scaleTitle:SetTextColor(1, 0.8, 0)
    scaleTitle:SetText("Scale Settings")
    contentY = contentY - 30
    
    -- Global scale slider
    local globalScaleLabel = self.mainFrame:CreateFontString(nil, "OVERLAY")
    globalScaleLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    globalScaleLabel:SetPoint("TOPLEFT", 30, contentY)
    globalScaleLabel:SetText("Global UI Scale:")
    
    local globalScaleSlider = CreateFrame("Slider", nil, self.mainFrame)
    globalScaleSlider:SetSize(200, 20)
    globalScaleSlider:SetPoint("LEFT", globalScaleLabel, "RIGHT", 20, 0)
    globalScaleSlider:SetMinMaxValues(0.5, 2.0)
    globalScaleSlider:SetValue(AzeriteMOP.db.global.uiScale or 1.0)
    globalScaleSlider:SetValueStep(0.05)
    
    local sliderBg = globalScaleSlider:CreateTexture(nil, "BACKGROUND")
    sliderBg:SetAllPoints()
    sliderBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    
    local sliderThumb = globalScaleSlider:CreateTexture(nil, "OVERLAY")
    sliderThumb:SetSize(20, 20)
    sliderThumb:SetColorTexture(1, 0.8, 0, 0.8)
    globalScaleSlider:SetThumbTexture(sliderThumb)
    
    local scaleValue = self.mainFrame:CreateFontString(nil, "OVERLAY")
    scaleValue:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    scaleValue:SetPoint("LEFT", globalScaleSlider, "RIGHT", 10, 0)
    scaleValue:SetText(string.format("%.2f", globalScaleSlider:GetValue()))
    
    globalScaleSlider:SetScript("OnValueChanged", function(self, value)
        scaleValue:SetText(string.format("%.2f", value))
        AzeriteMOP.db.global.uiScale = value
        if AzeriteMOP.db.global.useGlobalScale then
            AzeriteMOP:ApplyGlobalScale()
        end
    end)
    
    -- Use global scale checkbox
    local globalCheck = CreateFrame("Button", nil, self.mainFrame)
    globalCheck:SetSize(20, 20)
    globalCheck:SetPoint("LEFT", scaleValue, "RIGHT", 20, 0)
    
    local checkBg = globalCheck:CreateTexture(nil, "BACKGROUND")
    checkBg:SetAllPoints()
    checkBg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    local checkMark = globalCheck:CreateTexture(nil, "OVERLAY")
    checkMark:SetSize(16, 16)
    checkMark:SetPoint("CENTER")
    checkMark:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
    
    if AzeriteMOP.db.global.useGlobalScale then
        checkMark:Show()
    else
        checkMark:Hide()
    end
    
    globalCheck:SetScript("OnClick", function()
        AzeriteMOP.db.global.useGlobalScale = not AzeriteMOP.db.global.useGlobalScale
        if AzeriteMOP.db.global.useGlobalScale then
            checkMark:Show()
            AzeriteMOP:ApplyGlobalScale()
        else
            checkMark:Hide()
            AzeriteMOP:RestoreIndividualScales()
        end
    end)
    
    local globalCheckLabel = self.mainFrame:CreateFontString(nil, "OVERLAY")
    globalCheckLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    globalCheckLabel:SetPoint("LEFT", globalCheck, "RIGHT", 5, 0)
    globalCheckLabel:SetText("Use Global Scale")
    
    contentY = contentY - 50
    
    -- Section: Profile Management
    local profileTitle = self.mainFrame:CreateFontString(nil, "OVERLAY")
    profileTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    profileTitle:SetPoint("TOPLEFT", 30, contentY)
    profileTitle:SetTextColor(1, 0.8, 0)
    profileTitle:SetText("Profile Management")
    contentY = contentY - 30
    
    -- Current profile display
    local currentProfileLabel = self.mainFrame:CreateFontString(nil, "OVERLAY")
    currentProfileLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    currentProfileLabel:SetPoint("TOPLEFT", 30, contentY)
    currentProfileLabel:SetText("Current Profile:")
    
    self.currentProfileText = self.mainFrame:CreateFontString(nil, "OVERLAY")
    self.currentProfileText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.currentProfileText:SetPoint("LEFT", currentProfileLabel, "RIGHT", 10, 0)
    self.currentProfileText:SetTextColor(1, 0.8, 0)
    self.currentProfileText:SetText(AzeriteMOP.db.currentProfile or "Default")
    
    contentY = contentY - 30
    
    -- Profile input box
    local profileInput = CreateFrame("EditBox", nil, self.mainFrame)
    profileInput:SetSize(200, 25)
    profileInput:SetPoint("TOPLEFT", 30, contentY)
    profileInput:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    profileInput:SetAutoFocus(false)
    profileInput:SetMaxLetters(20)
    
    local inputBg = profileInput:CreateTexture(nil, "BACKGROUND")
    inputBg:SetAllPoints()
    inputBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    
    profileInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    profileInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    
    -- Save profile button
    local saveProfileBtn = CreateFrame("Button", nil, self.mainFrame)
    saveProfileBtn:SetSize(80, 25)
    saveProfileBtn:SetPoint("LEFT", profileInput, "RIGHT", 10, 0)
    
    local saveBg = saveProfileBtn:CreateTexture(nil, "BACKGROUND")
    saveBg:SetAllPoints()
    saveBg:SetColorTexture(0.2, 0.5, 0.2, 0.8)
    
    local saveText = saveProfileBtn:CreateFontString(nil, "OVERLAY")
    saveText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    saveText:SetPoint("CENTER")
    saveText:SetText("Save")
    
    saveProfileBtn:SetScript("OnClick", function()
        local name = profileInput:GetText()
        if name and name ~= "" then
            AzeriteMOP:SaveProfile(name)
            SettingsMenu.currentProfileText:SetText(name)
            profileInput:SetText("")
            print("|cFF4488FF[AzeriteMOP]|r Saved profile: " .. name)
        end
    end)
    
    -- Load profile button
    local loadProfileBtn = CreateFrame("Button", nil, self.mainFrame)
    loadProfileBtn:SetSize(80, 25)
    loadProfileBtn:SetPoint("LEFT", saveProfileBtn, "RIGHT", 10, 0)
    
    local loadBg = loadProfileBtn:CreateTexture(nil, "BACKGROUND")
    loadBg:SetAllPoints()
    loadBg:SetColorTexture(0.3, 0.3, 0.5, 0.8)
    
    local loadText = loadProfileBtn:CreateFontString(nil, "OVERLAY")
    loadText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    loadText:SetPoint("CENTER")
    loadText:SetText("Load")
    
    loadProfileBtn:SetScript("OnClick", function()
        local name = profileInput:GetText()
        if name and name ~= "" then
            if AzeriteMOP:LoadProfile(name) then
                SettingsMenu.currentProfileText:SetText(name)
                profileInput:SetText("")
                print("|cFF4488FF[AzeriteMOP]|r Loaded profile: " .. name)
            else
                print("|cFF4488FF[AzeriteMOP]|r Profile not found: " .. name)
            end
        end
    end)
    
    contentY = contentY - 30
    
    -- Profile list label
    local profileListLabel = self.mainFrame:CreateFontString(nil, "OVERLAY")
    profileListLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    profileListLabel:SetPoint("TOPLEFT", 30, contentY)
    profileListLabel:SetTextColor(0.7, 0.7, 0.7)
    profileListLabel:SetText("Available profiles: Default, Compact, Large, PvP, Raid")
    
    contentY = contentY - 50
    
    -- Section: Quick Settings
    local quickTitle = self.mainFrame:CreateFontString(nil, "OVERLAY")
    quickTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    quickTitle:SetPoint("TOPLEFT", 30, contentY)
    quickTitle:SetTextColor(1, 0.8, 0)
    quickTitle:SetText("Quick Settings")
    contentY = contentY - 30
    
    -- Explorer mode toggle
    local explorerBtn = CreateFrame("Button", nil, self.mainFrame)
    explorerBtn:SetSize(180, 30)
    explorerBtn:SetPoint("TOPLEFT", 30, contentY)
    
    local explorerBg = explorerBtn:CreateTexture(nil, "BACKGROUND")
    explorerBg:SetAllPoints()
    explorerBtn.bg = explorerBg
    
    local explorerText = explorerBtn:CreateFontString(nil, "OVERLAY")
    explorerText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    explorerText:SetPoint("CENTER")
    
    local function UpdateExplorerButton()
        if AzeriteMOP.db.explorerMode.enabled then
            explorerText:SetText("Explorer Mode: ON")
            explorerBg:SetColorTexture(0.2, 0.5, 0.2, 0.8)
        else
            explorerText:SetText("Explorer Mode: OFF")
            explorerBg:SetColorTexture(0.5, 0.2, 0.2, 0.8)
        end
    end
    
    UpdateExplorerButton()
    
    explorerBtn:SetScript("OnClick", function()
        AzeriteMOP.db.explorerMode.enabled = not AzeriteMOP.db.explorerMode.enabled
        if AzeriteMOP.ExplorerMode then
            if AzeriteMOP.db.explorerMode.enabled then
                AzeriteMOP.ExplorerMode:ForceEnable()
            else
                AzeriteMOP.ExplorerMode:ForceDisable()
            end
        end
        UpdateExplorerButton()
    end)
    
    -- Class colors toggle
    local classColorsBtn = CreateFrame("Button", nil, self.mainFrame)
    classColorsBtn:SetSize(180, 30)
    classColorsBtn:SetPoint("LEFT", explorerBtn, "RIGHT", 10, 0)
    
    local classColorsBg = classColorsBtn:CreateTexture(nil, "BACKGROUND")
    classColorsBg:SetAllPoints()
    classColorsBtn.bg = classColorsBg
    
    local classColorsText = classColorsBtn:CreateFontString(nil, "OVERLAY")
    classColorsText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    classColorsText:SetPoint("CENTER")
    
    local function UpdateClassColorsButton()
        if AzeriteMOP.db.colors.useClassColors then
            classColorsText:SetText("Class Colors: ON")
            classColorsBg:SetColorTexture(0.2, 0.5, 0.2, 0.8)
        else
            classColorsText:SetText("Class Colors: OFF")
            classColorsBg:SetColorTexture(0.5, 0.2, 0.2, 0.8)
        end
    end
    
    UpdateClassColorsButton()
    
    classColorsBtn:SetScript("OnClick", function()
        AzeriteMOP.db.colors.useClassColors = not AzeriteMOP.db.colors.useClassColors
        AzeriteMOP:UpdateAllColors()
        UpdateClassColorsButton()
    end)
    
    contentY = contentY - 50
    
    -- Help text
    local helpText = self.mainFrame:CreateFontString(nil, "OVERLAY")
    helpText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    helpText:SetPoint("TOPLEFT", 30, contentY)
    helpText:SetTextColor(0.6, 0.6, 0.6)
    helpText:SetText("For advanced settings, use slash commands. Type /az help for a full list.")
    
    -- Info text at bottom
    local infoText = self.mainFrame:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    infoText:SetPoint("BOTTOM", 0, 20)
    infoText:SetTextColor(0.5, 0.5, 0.5)
    infoText:SetText("AzeriteMOP v1.0.0 - MoP Classic UI")
end

function SettingsMenu:Show()
    self.mainFrame:Show()
    -- Update current profile display
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