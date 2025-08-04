-- AzeriteMOP Settings Menu Module
-- Provides a GUI for configuring all addon settings

local ADDON_NAME, Addon = ...
local AzeriteMOP = Addon.AzeriteMOP

-- Create SettingsMenu module
AzeriteMOP.SettingsMenu = {}
local SettingsMenu = AzeriteMOP.SettingsMenu

-- Constants
local MENU_WIDTH = 800
local MENU_HEIGHT = 600
local TAB_HEIGHT = 32
local CONTENT_PADDING = 20

-- Local variables
local activeTab = nil
local tabs = {}
local tabContents = {}

function SettingsMenu:Initialize()
    AzeriteMOP:Debug("Initializing Settings Menu...")
    
    -- Create the main settings frame
    self:CreateMainFrame()
    
    -- Create tabs
    self:CreateTabs()
    
    -- Create content for each tab
    self:CreateGeneralTab()
    self:CreateFramesTab()
    self:CreateColorsTab()
    self:CreateTexturesTab()
    self:CreateProfilesTab()
    
    -- Set default tab
    self:SelectTab("General")
    
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
    
    -- Border using textures instead of SetBackdrop
    self:CreateBorder(self.mainFrame)
    
    -- Title
    self.mainFrame.title = self.mainFrame:CreateFontString(nil, "OVERLAY")
    self.mainFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    self.mainFrame.title:SetPoint("TOP", 0, -15)
    self.mainFrame.title:SetTextColor(1, 0.8, 0)
    self.mainFrame.title:SetText("AzeriteMOP Settings")
    
    -- Close button
    self.mainFrame.closeButton = CreateFrame("Button", nil, self.mainFrame)
    self.mainFrame.closeButton:SetSize(32, 32)
    self.mainFrame.closeButton:SetPoint("TOPRIGHT", -5, -5)
    self.mainFrame.closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    self.mainFrame.closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    self.mainFrame.closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    self.mainFrame.closeButton:SetScript("OnClick", function()
        SettingsMenu:Hide()
    end)
    
    -- Tab container
    self.tabContainer = CreateFrame("Frame", nil, self.mainFrame)
    self.tabContainer:SetPoint("TOPLEFT", 20, -50)
    self.tabContainer:SetPoint("TOPRIGHT", -20, -50)
    self.tabContainer:SetHeight(TAB_HEIGHT)
    
    -- Content container
    self.contentContainer = CreateFrame("Frame", nil, self.mainFrame)
    self.contentContainer:SetPoint("TOPLEFT", 20, -90)
    self.contentContainer:SetPoint("BOTTOMRIGHT", -20, 60)
    self.contentContainer.bg = self.contentContainer:CreateTexture(nil, "BACKGROUND")
    self.contentContainer.bg:SetAllPoints()
    self.contentContainer.bg:SetColorTexture(0.05, 0.05, 0.05, 0.8)
    
    -- Apply/Save button
    self.applyButton = self:CreateButton(self.mainFrame, "Apply", 100, 30)
    self.applyButton:SetPoint("BOTTOMRIGHT", -20, 20)
    self.applyButton:SetScript("OnClick", function()
        SettingsMenu:ApplySettings()
    end)
    
    -- Cancel button
    self.cancelButton = self:CreateButton(self.mainFrame, "Cancel", 100, 30)
    self.cancelButton:SetPoint("RIGHT", self.applyButton, "LEFT", -10, 0)
    self.cancelButton:SetScript("OnClick", function()
        SettingsMenu:Hide()
    end)
end

function SettingsMenu:CreateTabs()
    local tabNames = {"General", "Frames", "Colors", "Textures", "Profiles"}
    local tabWidth = (MENU_WIDTH - 40) / #tabNames
    
    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", nil, self.tabContainer)
        tab:SetSize(tabWidth - 5, TAB_HEIGHT)
        tab:SetPoint("LEFT", (i - 1) * tabWidth, 0)
        
        -- Tab background
        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints()
        tab.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        -- Tab text
        tab.text = tab:CreateFontString(nil, "OVERLAY")
        tab.text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(name)
        
        -- Tab highlight
        tab.highlight = tab:CreateTexture(nil, "HIGHLIGHT")
        tab.highlight:SetAllPoints()
        tab.highlight:SetColorTexture(1, 1, 1, 0.1)
        
        -- Tab selected indicator
        tab.selected = tab:CreateTexture(nil, "ARTWORK")
        tab.selected:SetHeight(3)
        tab.selected:SetPoint("BOTTOMLEFT")
        tab.selected:SetPoint("BOTTOMRIGHT")
        tab.selected:SetColorTexture(1, 0.8, 0)
        tab.selected:Hide()
        
        -- Tab click handler
        tab:SetScript("OnClick", function()
            SettingsMenu:SelectTab(name)
        end)
        
        tabs[name] = tab
    end
end

function SettingsMenu:SelectTab(tabName)
    -- Hide all tab contents
    for name, content in pairs(tabContents) do
        if content then
            content:Hide()
        end
        if tabs[name] then
            tabs[name].selected:Hide()
            tabs[name].bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        end
    end
    
    -- Show selected tab content
    if tabContents[tabName] then
        tabContents[tabName]:Show()
    end
    
    -- Highlight selected tab
    if tabs[tabName] then
        tabs[tabName].selected:Show()
        tabs[tabName].bg:SetColorTexture(0.3, 0.3, 0.3, 0.9)
    end
    
    activeTab = tabName
end

function SettingsMenu:CreateGeneralTab()
    local content = CreateFrame("Frame", nil, self.contentContainer)
    content:SetAllPoints()
    content:Hide()
    
    local yOffset = -20
    
    -- Title
    local title = content:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    title:SetTextColor(1, 0.8, 0)
    title:SetText("General Settings")
    yOffset = yOffset - 40
    
    -- Enable addon checkbox
    local enableCheck = CreateFrame("CheckButton", nil, content)
    enableCheck:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    -- Create checkbox texture
    local checkBg = enableCheck:CreateTexture(nil, "BACKGROUND")
    checkBg:SetSize(20, 20)
    checkBg:SetPoint("LEFT")
    checkBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    enableCheck.bg = checkBg
    
    local checkMark = enableCheck:CreateTexture(nil, "OVERLAY")
    checkMark:SetSize(16, 16)
    checkMark:SetPoint("CENTER", checkBg)
    checkMark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkMark:Hide()
    enableCheck.checkMark = checkMark
    
    enableCheck:SetSize(20, 20)
    enableCheck.text = enableCheck:CreateFontString(nil, "OVERLAY")
    enableCheck.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    enableCheck.text:SetPoint("LEFT", enableCheck, "RIGHT", 5, 0)
    enableCheck.text:SetText("Enable AzeriteMOP")
    enableCheck:SetChecked(true)
    if enableCheck:GetChecked() then
        enableCheck.checkMark:Show()
    end
    enableCheck:SetScript("OnClick", function(self)
        if self:GetChecked() then
            self.checkMark:Show()
        else
            self.checkMark:Hide()
        end
    end)
    yOffset = yOffset - 35
    
    -- Lock frames checkbox
    local lockCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    lockCheck:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    lockCheck.text = lockCheck:CreateFontString(nil, "OVERLAY")
    lockCheck.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    lockCheck.text:SetPoint("LEFT", lockCheck, "RIGHT", 5, 0)
    lockCheck.text:SetText("Lock All Frames")
    lockCheck:SetChecked(AzeriteMOP.db.playerFrame.locked and AzeriteMOP.db.targetFrame.locked)
    lockCheck:SetScript("OnClick", function(self)
        local locked = self:GetChecked()
        AzeriteMOP.db.playerFrame.locked = locked
        AzeriteMOP.db.targetFrame.locked = locked
        AzeriteMOP:UpdateFrameLocks()
    end)
    yOffset = yOffset - 35
    
    -- Global UI Scale
    local scaleLabel = content:CreateFontString(nil, "OVERLAY")
    scaleLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    scaleLabel:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    scaleLabel:SetText("Global UI Scale:")
    
    local scaleSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    scaleSlider:SetPoint("LEFT", scaleLabel, "RIGHT", 20, 0)
    scaleSlider:SetSize(200, 20)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValue(AzeriteMOP.db.global.uiScale or 1.0)
    scaleSlider:SetValueStep(0.05)
    scaleSlider.Low:SetText("0.5")
    scaleSlider.High:SetText("2.0")
    
    scaleSlider.value = scaleSlider:CreateFontString(nil, "OVERLAY")
    scaleSlider.value:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    scaleSlider.value:SetPoint("TOP", scaleSlider, "BOTTOM", 0, -5)
    scaleSlider.value:SetText(string.format("%.2f", scaleSlider:GetValue()))
    
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        self.value:SetText(string.format("%.2f", value))
        AzeriteMOP.db.global.uiScale = value
        if AzeriteMOP.db.global.useGlobalScale then
            AzeriteMOP:ApplyGlobalScale()
        end
    end)
    
    local globalScaleCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    globalScaleCheck:SetPoint("LEFT", scaleSlider, "RIGHT", 20, 0)
    globalScaleCheck.text = globalScaleCheck:CreateFontString(nil, "OVERLAY")
    globalScaleCheck.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    globalScaleCheck.text:SetPoint("LEFT", globalScaleCheck, "RIGHT", 5, 0)
    globalScaleCheck.text:SetText("Use Global Scale")
    globalScaleCheck:SetChecked(AzeriteMOP.db.global.useGlobalScale)
    globalScaleCheck:SetScript("OnClick", function(self)
        AzeriteMOP.db.global.useGlobalScale = self:GetChecked()
        if self:GetChecked() then
            AzeriteMOP:ApplyGlobalScale()
        else
            AzeriteMOP:RestoreIndividualScales()
        end
    end)
    yOffset = yOffset - 50
    
    -- Explorer Mode section
    local explorerTitle = content:CreateFontString(nil, "OVERLAY")
    explorerTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    explorerTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    explorerTitle:SetTextColor(1, 0.8, 0)
    explorerTitle:SetText("Explorer Mode")
    yOffset = yOffset - 30
    
    local explorerCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    explorerCheck:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    explorerCheck.text = explorerCheck:CreateFontString(nil, "OVERLAY")
    explorerCheck.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    explorerCheck.text:SetPoint("LEFT", explorerCheck, "RIGHT", 5, 0)
    explorerCheck.text:SetText("Enable Explorer Mode")
    explorerCheck:SetChecked(AzeriteMOP.db.explorerMode.enabled)
    explorerCheck:SetScript("OnClick", function(self)
        AzeriteMOP.db.explorerMode.enabled = self:GetChecked()
        if AzeriteMOP.ExplorerMode then
            if self:GetChecked() then
                AzeriteMOP.ExplorerMode:Enable()
            else
                AzeriteMOP.ExplorerMode:Disable()
            end
        end
    end)
    yOffset = yOffset - 35
    
    -- Chat Frame section
    local chatTitle = content:CreateFontString(nil, "OVERLAY")
    chatTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    chatTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    chatTitle:SetTextColor(1, 0.8, 0)
    chatTitle:SetText("Chat Frame")
    yOffset = yOffset - 30
    
    local chatCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    chatCheck:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    chatCheck.text = chatCheck:CreateFontString(nil, "OVERLAY")
    chatCheck.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    chatCheck.text:SetPoint("LEFT", chatCheck, "RIGHT", 5, 0)
    chatCheck.text:SetText("Enable Chat Frame Styling")
    chatCheck:SetChecked(AzeriteMOP.db.chatFrame.enabled)
    chatCheck:SetScript("OnClick", function(self)
        AzeriteMOP.db.chatFrame.enabled = self:GetChecked()
        if AzeriteMOP.ChatFrame then
            AzeriteMOP.ChatFrame:Toggle()
        end
    end)
    
    tabContents["General"] = content
end

function SettingsMenu:CreateFramesTab()
    local content = CreateFrame("ScrollFrame", nil, self.contentContainer)
    content:SetAllPoints()
    content:Hide()
    
    -- Create scroll bar manually
    local scrollBar = CreateFrame("Slider", nil, content)
    scrollBar:SetPoint("TOPRIGHT", -5, -5)
    scrollBar:SetPoint("BOTTOMRIGHT", -5, 5)
    scrollBar:SetWidth(16)
    scrollBar:SetMinMaxValues(0, 100)
    scrollBar:SetValue(0)
    scrollBar:SetValueStep(1)
    scrollBar:SetObeyStepOnDrag(true)
    
    local scrollBg = scrollBar:CreateTexture(nil, "BACKGROUND")
    scrollBg:SetAllPoints()
    scrollBg:SetColorTexture(0, 0, 0, 0.5)
    
    local scrollThumb = scrollBar:CreateTexture(nil, "OVERLAY")
    scrollThumb:SetColorTexture(0.8, 0.8, 0.8, 0.8)
    scrollThumb:SetSize(16, 30)
    scrollBar:SetThumbTexture(scrollThumb)
    
    content.scrollBar = scrollBar
    
    scrollBar:SetScript("OnValueChanged", function(self, value)
        content:SetVerticalScroll(value)
    end)
    
    content:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        local step = 20
        
        if delta > 0 then
            scrollBar:SetValue(math.max(min, current - step))
        else
            scrollBar:SetValue(math.min(max, current + step))
        end
    end)
    
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(MENU_WIDTH - 80, 800)
    content:SetScrollChild(scrollChild)
    
    local yOffset = -20
    
    -- Title
    local title = scrollChild:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    title:SetTextColor(1, 0.8, 0)
    title:SetText("Frame Settings")
    yOffset = yOffset - 40
    
    -- Player Frame section
    local playerTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    playerTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    playerTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    playerTitle:SetTextColor(0.8, 1, 0.8)
    playerTitle:SetText("Player Frame")
    yOffset = yOffset - 30
    
    -- Player frame scale
    local playerScaleLabel = scrollChild:CreateFontString(nil, "OVERLAY")
    playerScaleLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    playerScaleLabel:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    playerScaleLabel:SetText("Scale:")
    
    local playerScaleSlider = CreateFrame("Slider", nil, scrollChild, "OptionsSliderTemplate")
    playerScaleSlider:SetPoint("LEFT", playerScaleLabel, "RIGHT", 20, 0)
    playerScaleSlider:SetSize(200, 20)
    playerScaleSlider:SetMinMaxValues(0.5, 2.0)
    playerScaleSlider:SetValue(AzeriteMOP.db.playerFrame.scale or 1.0)
    playerScaleSlider:SetValueStep(0.05)
    playerScaleSlider.Low:SetText("0.5")
    playerScaleSlider.High:SetText("2.0")
    
    playerScaleSlider.value = playerScaleSlider:CreateFontString(nil, "OVERLAY")
    playerScaleSlider.value:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    playerScaleSlider.value:SetPoint("TOP", playerScaleSlider, "BOTTOM", 0, -5)
    playerScaleSlider.value:SetText(string.format("%.2f", playerScaleSlider:GetValue()))
    
    playerScaleSlider:SetScript("OnValueChanged", function(self, value)
        self.value:SetText(string.format("%.2f", value))
        AzeriteMOP.db.playerFrame.scale = value
        if AzeriteMOP.PlayerFrame and AzeriteMOP.PlayerFrame.frame then
            AzeriteMOP.PlayerFrame.frame:SetScale(value)
        end
    end)
    
    -- Reset player position button
    local resetPlayerBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetPlayerBtn:SetSize(120, 25)
    resetPlayerBtn:SetPoint("LEFT", playerScaleSlider, "RIGHT", 20, 0)
    resetPlayerBtn:SetText("Reset Position")
    resetPlayerBtn:SetScript("OnClick", function()
        AzeriteMOP.db.playerFrame.position = {"CENTER", "UIParent", "CENTER", 0, -150}
        if AzeriteMOP.PlayerFrame and AzeriteMOP.PlayerFrame.frame then
            AzeriteMOP.PlayerFrame.frame:ClearAllPoints()
            AzeriteMOP.PlayerFrame.frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
        end
    end)
    yOffset = yOffset - 50
    
    -- Target Frame section
    local targetTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    targetTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    targetTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    targetTitle:SetTextColor(1, 0.8, 0.8)
    targetTitle:SetText("Target Frame")
    yOffset = yOffset - 30
    
    -- Target frame scale
    local targetScaleLabel = scrollChild:CreateFontString(nil, "OVERLAY")
    targetScaleLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    targetScaleLabel:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    targetScaleLabel:SetText("Scale:")
    
    local targetScaleSlider = CreateFrame("Slider", nil, scrollChild, "OptionsSliderTemplate")
    targetScaleSlider:SetPoint("LEFT", targetScaleLabel, "RIGHT", 20, 0)
    targetScaleSlider:SetSize(200, 20)
    targetScaleSlider:SetMinMaxValues(0.5, 2.0)
    targetScaleSlider:SetValue(AzeriteMOP.db.targetFrame.scale or 1.0)
    targetScaleSlider:SetValueStep(0.05)
    targetScaleSlider.Low:SetText("0.5")
    targetScaleSlider.High:SetText("2.0")
    
    targetScaleSlider.value = targetScaleSlider:CreateFontString(nil, "OVERLAY")
    targetScaleSlider.value:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    targetScaleSlider.value:SetPoint("TOP", targetScaleSlider, "BOTTOM", 0, -5)
    targetScaleSlider.value:SetText(string.format("%.2f", targetScaleSlider:GetValue()))
    
    targetScaleSlider:SetScript("OnValueChanged", function(self, value)
        self.value:SetText(string.format("%.2f", value))
        AzeriteMOP.db.targetFrame.scale = value
        if AzeriteMOP.TargetFrame then
            AzeriteMOP.TargetFrame:UpdateScaling()
        end
    end)
    
    -- Reset target position button
    local resetTargetBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetTargetBtn:SetSize(120, 25)
    resetTargetBtn:SetPoint("LEFT", targetScaleSlider, "RIGHT", 20, 0)
    resetTargetBtn:SetText("Reset Position")
    resetTargetBtn:SetScript("OnClick", function()
        AzeriteMOP.db.targetFrame.position = {"CENTER", "UIParent", "CENTER", 0, 150}
        if AzeriteMOP.TargetFrame and AzeriteMOP.TargetFrame.frame then
            AzeriteMOP.TargetFrame.frame:ClearAllPoints()
            AzeriteMOP.TargetFrame.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        end
    end)
    yOffset = yOffset - 50
    
    -- Nameplate section
    local nameplateTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    nameplateTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    nameplateTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    nameplateTitle:SetTextColor(1, 1, 0.8)
    nameplateTitle:SetText("Nameplates")
    yOffset = yOffset - 30
    
    -- Nameplate scale
    local nameplateScaleLabel = scrollChild:CreateFontString(nil, "OVERLAY")
    nameplateScaleLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    nameplateScaleLabel:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    nameplateScaleLabel:SetText("Scale:")
    
    local nameplateScaleSlider = CreateFrame("Slider", nil, scrollChild, "OptionsSliderTemplate")
    nameplateScaleSlider:SetPoint("LEFT", nameplateScaleLabel, "RIGHT", 20, 0)
    nameplateScaleSlider:SetSize(200, 20)
    nameplateScaleSlider:SetMinMaxValues(0.5, 2.0)
    nameplateScaleSlider:SetValue(AzeriteMOP.db.nameplate and AzeriteMOP.db.nameplate.scale or 1.0)
    nameplateScaleSlider:SetValueStep(0.05)
    nameplateScaleSlider.Low:SetText("0.5")
    nameplateScaleSlider.High:SetText("2.0")
    
    nameplateScaleSlider.value = nameplateScaleSlider:CreateFontString(nil, "OVERLAY")
    nameplateScaleSlider.value:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    nameplateScaleSlider.value:SetPoint("TOP", nameplateScaleSlider, "BOTTOM", 0, -5)
    nameplateScaleSlider.value:SetText(string.format("%.2f", nameplateScaleSlider:GetValue()))
    
    nameplateScaleSlider:SetScript("OnValueChanged", function(self, value)
        self.value:SetText(string.format("%.2f", value))
        if not AzeriteMOP.db.nameplate then
            AzeriteMOP.db.nameplate = {}
        end
        AzeriteMOP.db.nameplate.scale = value
        if AzeriteMOP.Nameplate then
            AzeriteMOP.Nameplate:UpdateAllScales()
        end
    end)
    
    tabContents["Frames"] = content
end

function SettingsMenu:CreateColorsTab()
    local content = CreateFrame("ScrollFrame", nil, self.contentContainer)
    content:SetAllPoints()
    content:Hide()
    
    -- Create scroll bar manually
    local scrollBar = CreateFrame("Slider", nil, content)
    scrollBar:SetPoint("TOPRIGHT", -5, -5)
    scrollBar:SetPoint("BOTTOMRIGHT", -5, 5)
    scrollBar:SetWidth(16)
    scrollBar:SetMinMaxValues(0, 100)
    scrollBar:SetValue(0)
    scrollBar:SetValueStep(1)
    scrollBar:SetObeyStepOnDrag(true)
    
    local scrollBg = scrollBar:CreateTexture(nil, "BACKGROUND")
    scrollBg:SetAllPoints()
    scrollBg:SetColorTexture(0, 0, 0, 0.5)
    
    local scrollThumb = scrollBar:CreateTexture(nil, "OVERLAY")
    scrollThumb:SetColorTexture(0.8, 0.8, 0.8, 0.8)
    scrollThumb:SetSize(16, 30)
    scrollBar:SetThumbTexture(scrollThumb)
    
    content.scrollBar = scrollBar
    
    scrollBar:SetScript("OnValueChanged", function(self, value)
        content:SetVerticalScroll(value)
    end)
    
    content:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        local step = 20
        
        if delta > 0 then
            scrollBar:SetValue(math.max(min, current - step))
        else
            scrollBar:SetValue(math.min(max, current + step))
        end
    end)
    
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(MENU_WIDTH - 80, 1200)
    content:SetScrollChild(scrollChild)
    
    local yOffset = -20
    
    -- Title
    local title = scrollChild:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    title:SetTextColor(1, 0.8, 0)
    title:SetText("Color Settings")
    yOffset = yOffset - 40
    
    -- Use class colors checkbox
    local classColorsCheck = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    classColorsCheck:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    classColorsCheck.text = classColorsCheck:CreateFontString(nil, "OVERLAY")
    classColorsCheck.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    classColorsCheck.text:SetPoint("LEFT", classColorsCheck, "RIGHT", 5, 0)
    classColorsCheck.text:SetText("Use Class Colors for Health Bars")
    classColorsCheck:SetChecked(AzeriteMOP.db.colors.useClassColors)
    classColorsCheck:SetScript("OnClick", function(self)
        AzeriteMOP.db.colors.useClassColors = self:GetChecked()
        AzeriteMOP:UpdateAllColors()
    end)
    yOffset = yOffset - 40
    
    -- Helper function to create color picker
    local function CreateColorPicker(parent, label, colorKey, x, y)
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(200, 30)
        frame:SetPoint("TOPLEFT", x, y)
        
        local labelText = frame:CreateFontString(nil, "OVERLAY")
        labelText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        labelText:SetPoint("LEFT")
        labelText:SetText(label)
        labelText:SetWidth(120)
        labelText:SetJustifyH("LEFT")
        
        local colorSwatch = CreateFrame("Button", nil, frame)
        colorSwatch:SetSize(20, 20)
        colorSwatch:SetPoint("LEFT", labelText, "RIGHT", 5, 0)
        
        local swatchBg = colorSwatch:CreateTexture(nil, "BACKGROUND")
        swatchBg:SetAllPoints()
        swatchBg:SetColorTexture(1, 1, 1, 1)
        
        local swatchColor = colorSwatch:CreateTexture(nil, "ARTWORK")
        swatchColor:SetAllPoints()
        swatchColor:SetInside(swatchBg, 2, 2)
        
        local r, g, b = AzeriteMOP:GetColor(colorKey)
        swatchColor:SetColorTexture(r, g, b, 1)
        
        colorSwatch:SetScript("OnClick", function()
            local currentR, currentG, currentB = AzeriteMOP:GetColor(colorKey)
            ColorPickerFrame:SetColorRGB(currentR, currentG, currentB)
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame.previousValues = {currentR, currentG, currentB}
            ColorPickerFrame.func = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                swatchColor:SetColorTexture(r, g, b, 1)
                AzeriteMOP:SetColor(colorKey, r, g, b)
                AzeriteMOP:UpdateAllColors()
            end
            ColorPickerFrame.cancelFunc = function()
                local r, g, b = unpack(ColorPickerFrame.previousValues)
                swatchColor:SetColorTexture(r, g, b, 1)
                AzeriteMOP:SetColor(colorKey, r, g, b)
                AzeriteMOP:UpdateAllColors()
            end
            ColorPickerFrame:Show()
        end)
        
        return frame
    end
    
    -- Player Frame Colors
    local playerTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    playerTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    playerTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    playerTitle:SetTextColor(0.8, 1, 0.8)
    playerTitle:SetText("Player Frame")
    yOffset = yOffset - 30
    
    CreateColorPicker(scrollChild, "Health Bar", "playerHealth", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Health Background", "playerHealthBg", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 35
    
    CreateColorPicker(scrollChild, "Power Bar", "playerPower", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Power Background", "playerPowerBg", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 35
    
    CreateColorPicker(scrollChild, "Text", "playerText", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Level Text", "playerLevelText", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 45
    
    -- Target Frame Colors
    local targetTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    targetTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    targetTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    targetTitle:SetTextColor(1, 0.8, 0.8)
    targetTitle:SetText("Target Frame")
    yOffset = yOffset - 30
    
    CreateColorPicker(scrollChild, "Friendly Health", "targetHealthFriendly", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Hostile Health", "targetHealthHostile", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 35
    
    CreateColorPicker(scrollChild, "Neutral Health", "targetHealthNeutral", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Health Background", "targetHealthBg", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 35
    
    CreateColorPicker(scrollChild, "Power Bar", "targetPower", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Power Background", "targetPowerBg", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 35
    
    CreateColorPicker(scrollChild, "Text", "targetText", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Level Text", "targetLevelText", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 45
    
    -- Cast Bar Colors
    local castTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    castTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    castTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    castTitle:SetTextColor(1, 1, 0.8)
    castTitle:SetText("Cast Bars")
    yOffset = yOffset - 30
    
    CreateColorPicker(scrollChild, "Normal Cast", "castBarNormal", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Channeled Cast", "castBarChannel", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 35
    
    CreateColorPicker(scrollChild, "Interrupted Cast", "castBarInterrupted", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Cast Background", "castBarBg", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 35
    
    CreateColorPicker(scrollChild, "Cast Text", "castBarText", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Cast Time Text", "castBarTimeText", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 45
    
    -- Nameplate Colors
    local nameplateTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    nameplateTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    nameplateTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    nameplateTitle:SetTextColor(0.8, 0.8, 1)
    nameplateTitle:SetText("Nameplates")
    yOffset = yOffset - 30
    
    CreateColorPicker(scrollChild, "Friendly Health", "nameplateHealthFriendly", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Hostile Health", "nameplateHealthHostile", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 35
    
    CreateColorPicker(scrollChild, "Neutral Health", "nameplateHealthNeutral", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Health Background", "nameplateHealthBg", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 35
    
    CreateColorPicker(scrollChild, "Cast Bar", "nameplateCastBar", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Cast Background", "nameplateCastBarBg", CONTENT_PADDING + 220, yOffset)
    yOffset = yOffset - 35
    
    CreateColorPicker(scrollChild, "Name Text", "nameplateText", CONTENT_PADDING, yOffset)
    CreateColorPicker(scrollChild, "Level Text", "nameplateLevelText", CONTENT_PADDING + 220, yOffset)
    
    tabContents["Colors"] = content
end

function SettingsMenu:CreateTexturesTab()
    local content = CreateFrame("ScrollFrame", nil, self.contentContainer)
    content:SetAllPoints()
    content:Hide()
    
    -- Create scroll bar manually
    local scrollBar = CreateFrame("Slider", nil, content)
    scrollBar:SetPoint("TOPRIGHT", -5, -5)
    scrollBar:SetPoint("BOTTOMRIGHT", -5, 5)
    scrollBar:SetWidth(16)
    scrollBar:SetMinMaxValues(0, 100)
    scrollBar:SetValue(0)
    scrollBar:SetValueStep(1)
    scrollBar:SetObeyStepOnDrag(true)
    
    local scrollBg = scrollBar:CreateTexture(nil, "BACKGROUND")
    scrollBg:SetAllPoints()
    scrollBg:SetColorTexture(0, 0, 0, 0.5)
    
    local scrollThumb = scrollBar:CreateTexture(nil, "OVERLAY")
    scrollThumb:SetColorTexture(0.8, 0.8, 0.8, 0.8)
    scrollThumb:SetSize(16, 30)
    scrollBar:SetThumbTexture(scrollThumb)
    
    content.scrollBar = scrollBar
    
    scrollBar:SetScript("OnValueChanged", function(self, value)
        content:SetVerticalScroll(value)
    end)
    
    content:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        local step = 20
        
        if delta > 0 then
            scrollBar:SetValue(math.max(min, current - step))
        else
            scrollBar:SetValue(math.min(max, current + step))
        end
    end)
    
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(MENU_WIDTH - 80, 600)
    content:SetScrollChild(scrollChild)
    
    local yOffset = -20
    
    -- Title
    local title = scrollChild:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    title:SetTextColor(1, 0.8, 0)
    title:SetText("Texture Settings")
    yOffset = yOffset - 40
    
    -- Get available textures
    local textures = AzeriteMOP:GetTextureList()
    local textureNames = {}
    for name, _ in pairs(textures) do
        table.insert(textureNames, name)
    end
    table.sort(textureNames)
    
    -- Helper function to create texture dropdown
    local function CreateTextureDropdown(parent, label, textureKey, x, y)
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(350, 30)
        frame:SetPoint("TOPLEFT", x, y)
        
        local labelText = frame:CreateFontString(nil, "OVERLAY")
        labelText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        labelText:SetPoint("LEFT")
        labelText:SetText(label)
        labelText:SetWidth(120)
        labelText:SetJustifyH("LEFT")
        
        local dropdown = CreateFrame("Frame", "AzeriteMOP"..textureKey.."Dropdown", frame, "UIDropDownMenuTemplate")
        dropdown:SetPoint("LEFT", labelText, "RIGHT", -15, -2)
        
        local function OnClick(self)
            UIDropDownMenu_SetSelectedValue(dropdown, self.value)
            AzeriteMOP:SetTexture(textureKey, textures[self.value])
            AzeriteMOP:UpdateAllTextures()
        end
        
        local function Initialize(self, level)
            local info = UIDropDownMenu_CreateInfo()
            for _, name in ipairs(textureNames) do
                info.text = name
                info.value = name
                info.func = OnClick
                info.checked = nil
                UIDropDownMenu_AddButton(info, level)
            end
        end
        
        UIDropDownMenu_Initialize(dropdown, Initialize)
        UIDropDownMenu_SetWidth(dropdown, 180)
        
        -- Set current texture
        local currentTexture = AzeriteMOP.db.textures[textureKey]
        for name, path in pairs(textures) do
            if path == currentTexture then
                UIDropDownMenu_SetSelectedValue(dropdown, name)
                UIDropDownMenu_SetText(dropdown, name)
                break
            end
        end
        
        return frame
    end
    
    -- Bar Textures
    local barTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    barTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    barTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    barTitle:SetTextColor(1, 0.8, 0)
    barTitle:SetText("Bar Textures")
    yOffset = yOffset - 30
    
    CreateTextureDropdown(scrollChild, "Health Bars", "healthBar", CONTENT_PADDING, yOffset)
    yOffset = yOffset - 35
    
    CreateTextureDropdown(scrollChild, "Power Bars", "powerBar", CONTENT_PADDING, yOffset)
    yOffset = yOffset - 35
    
    CreateTextureDropdown(scrollChild, "Cast Bars", "castBar", CONTENT_PADDING, yOffset)
    yOffset = yOffset - 45
    
    -- Background Textures
    local bgTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    bgTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    bgTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    bgTitle:SetTextColor(1, 0.8, 0)
    bgTitle:SetText("Background Textures")
    yOffset = yOffset - 30
    
    CreateTextureDropdown(scrollChild, "Bar Backgrounds", "barBackground", CONTENT_PADDING, yOffset)
    yOffset = yOffset - 35
    
    CreateTextureDropdown(scrollChild, "Frame Backgrounds", "frameBackground", CONTENT_PADDING, yOffset)
    yOffset = yOffset - 35
    
    CreateTextureDropdown(scrollChild, "Border Texture", "borderTexture", CONTENT_PADDING, yOffset)
    yOffset = yOffset - 45
    
    -- Custom texture section
    local customTitle = scrollChild:CreateFontString(nil, "OVERLAY")
    customTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    customTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    customTitle:SetTextColor(1, 0.8, 0)
    customTitle:SetText("Custom Texture")
    yOffset = yOffset - 30
    
    local customInfo = scrollChild:CreateFontString(nil, "OVERLAY")
    customInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    customInfo:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    customInfo:SetTextColor(0.7, 0.7, 0.7)
    customInfo:SetText("Use /az texture custom <name> <path> to add custom textures")
    
    tabContents["Textures"] = content
end

function SettingsMenu:CreateProfilesTab()
    local content = CreateFrame("Frame", nil, self.contentContainer)
    content:SetAllPoints()
    content:Hide()
    
    local yOffset = -20
    
    -- Title
    local title = content:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    title:SetTextColor(1, 0.8, 0)
    title:SetText("Profile Management")
    yOffset = yOffset - 40
    
    -- Current profile
    local currentLabel = content:CreateFontString(nil, "OVERLAY")
    currentLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    currentLabel:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    currentLabel:SetText("Current Profile:")
    
    local currentProfile = content:CreateFontString(nil, "OVERLAY")
    currentProfile:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    currentProfile:SetPoint("LEFT", currentLabel, "RIGHT", 10, 0)
    currentProfile:SetTextColor(1, 0.8, 0)
    currentProfile:SetText(AzeriteMOP.db.currentProfile or "Default")
    yOffset = yOffset - 40
    
    -- Profile list
    local listTitle = content:CreateFontString(nil, "OVERLAY")
    listTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    listTitle:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    listTitle:SetText("Available Profiles")
    yOffset = yOffset - 30
    
    -- Profile list frame
    local listFrame = CreateFrame("Frame", nil, content)
    listFrame:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    listFrame:SetSize(300, 200)
    listFrame.bg = listFrame:CreateTexture(nil, "BACKGROUND")
    listFrame.bg:SetAllPoints()
    listFrame.bg:SetColorTexture(0.05, 0.05, 0.05, 0.5)
    
    -- Scrollable list
    local scrollFrame = CreateFrame("ScrollFrame", nil, listFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)
    
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(270, 400)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Profile buttons
    local profileButtons = {}
    local profiles = AzeriteMOP.db.profiles or {}
    local profileY = -5
    
    for name, _ in pairs(profiles) do
        local btn = CreateFrame("Button", nil, scrollChild)
        btn:SetSize(260, 25)
        btn:SetPoint("TOPLEFT", 5, profileY)
        
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY")
        btn.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        btn.text:SetPoint("LEFT", 10, 0)
        btn.text:SetText(name)
        
        btn:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.4, 0.4, 0.4, 0.7)
        end)
        
        btn:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
        end)
        
        btn:SetScript("OnClick", function()
            AzeriteMOP:LoadProfile(name)
            currentProfile:SetText(name)
            print("|cFF4488FF[AzeriteMOP]|r Loaded profile: " .. name)
        end)
        
        profileY = profileY - 30
        table.insert(profileButtons, btn)
    end
    
    -- Profile action buttons
    local loadBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    loadBtn:SetSize(90, 25)
    loadBtn:SetPoint("TOPLEFT", listFrame, "TOPRIGHT", 20, 0)
    loadBtn:SetText("Load")
    loadBtn:SetScript("OnClick", function()
        -- Load selected profile
    end)
    
    local saveBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    saveBtn:SetSize(90, 25)
    saveBtn:SetPoint("TOP", loadBtn, "BOTTOM", 0, -10)
    saveBtn:SetText("Save As...")
    saveBtn:SetScript("OnClick", function()
        StaticPopup_Show("AZERITEMOP_SAVE_PROFILE")
    end)
    
    local deleteBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    deleteBtn:SetSize(90, 25)
    deleteBtn:SetPoint("TOP", saveBtn, "BOTTOM", 0, -10)
    deleteBtn:SetText("Delete")
    deleteBtn:SetScript("OnClick", function()
        -- Delete selected profile
    end)
    
    -- New profile input
    yOffset = yOffset - 220
    local newProfileLabel = content:CreateFontString(nil, "OVERLAY")
    newProfileLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    newProfileLabel:SetPoint("TOPLEFT", CONTENT_PADDING, yOffset)
    newProfileLabel:SetText("New Profile Name:")
    
    local newProfileEdit = CreateFrame("EditBox", nil, content)
    newProfileEdit:SetSize(200, 25)
    newProfileEdit:SetPoint("LEFT", newProfileLabel, "RIGHT", 10, 0)
    newProfileEdit:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    newProfileEdit:SetAutoFocus(false)
    newProfileEdit:SetMaxLetters(20)
    
    local editBg = newProfileEdit:CreateTexture(nil, "BACKGROUND")
    editBg:SetAllPoints()
    editBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    
    newProfileEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    newProfileEdit:SetScript("OnEnterPressed", function(self)
        local name = self:GetText()
        if name and name ~= "" then
            AzeriteMOP:SaveProfile(name)
            self:SetText("")
            self:ClearFocus()
            -- Refresh profile list
            SettingsMenu:CreateProfilesTab()
        end
    end)
    
    local createBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    createBtn:SetSize(80, 25)
    createBtn:SetPoint("LEFT", newProfileEdit, "RIGHT", 10, 0)
    createBtn:SetText("Create")
    createBtn:SetScript("OnClick", function()
        local name = newProfileEdit:GetText()
        if name and name ~= "" then
            AzeriteMOP:SaveProfile(name)
            newProfileEdit:SetText("")
            print("|cFF4488FF[AzeriteMOP]|r Created profile: " .. name)
            -- Refresh the tab
            SettingsMenu:CreateProfilesTab()
            SettingsMenu:SelectTab("Profiles")
        end
    end)
    
    tabContents["Profiles"] = content
end

function SettingsMenu:Show()
    self.mainFrame:Show()
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

function SettingsMenu:ApplySettings()
    -- Settings are applied in real-time, but we can add a confirmation here
    print("|cFF4488FF[AzeriteMOP]|r Settings applied successfully!")
end

-- Static popup for saving profiles
StaticPopupDialogs["AZERITEMOP_SAVE_PROFILE"] = {
    text = "Enter a name for the new profile:",
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 200,
    OnAccept = function(self)
        local name = self.editBox:GetText()
        if name and name ~= "" then
            AzeriteMOP:SaveProfile(name)
            print("|cFF4488FF[AzeriteMOP]|r Saved profile: " .. name)
        end
    end,
    OnShow = function(self)
        self.editBox:SetFocus()
    end,
    OnHide = function(self)
        self.editBox:SetText("")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- Helper function to create a button
function SettingsMenu:CreateButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    
    -- Button background
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    button.bg = bg
    
    -- Button text
    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    buttonText:SetPoint("CENTER")
    buttonText:SetText(text)
    button.text = buttonText
    
    -- Button highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.2)
    
    -- Button pushed texture
    button:SetScript("OnMouseDown", function(self)
        self.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)
    end)
    
    button:SetScript("OnMouseUp", function(self)
        self.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    end)
    
    return button
end

-- Helper function to create a border using textures
function SettingsMenu:CreateBorder(frame)
    -- Top border
    local top = frame:CreateTexture(nil, "BORDER")
    top:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")
    top:SetTexCoord(0.25, 0.75, 0, 0.125)
    top:SetPoint("TOPLEFT", -5, 5)
    top:SetPoint("TOPRIGHT", 5, 5)
    top:SetHeight(32)
    
    -- Bottom border
    local bottom = frame:CreateTexture(nil, "BORDER")
    bottom:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")
    bottom:SetTexCoord(0.25, 0.75, 0.875, 1)
    bottom:SetPoint("BOTTOMLEFT", -5, -5)
    bottom:SetPoint("BOTTOMRIGHT", 5, -5)
    bottom:SetHeight(32)
    
    -- Left border
    local left = frame:CreateTexture(nil, "BORDER")
    left:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")
    left:SetTexCoord(0, 0.125, 0.25, 0.75)
    left:SetPoint("TOPLEFT", -5, -27)
    left:SetPoint("BOTTOMLEFT", -5, 27)
    left:SetWidth(32)
    
    -- Right border
    local right = frame:CreateTexture(nil, "BORDER")
    right:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")
    right:SetTexCoord(0.875, 1, 0.25, 0.75)
    right:SetPoint("TOPRIGHT", 5, -27)
    right:SetPoint("BOTTOMRIGHT", 5, 27)
    right:SetWidth(32)
    
    -- Corners
    local topLeft = frame:CreateTexture(nil, "BORDER")
    topLeft:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")
    topLeft:SetTexCoord(0, 0.25, 0, 0.25)
    topLeft:SetPoint("TOPLEFT", -5, 5)
    topLeft:SetSize(32, 32)
    
    local topRight = frame:CreateTexture(nil, "BORDER")
    topRight:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")
    topRight:SetTexCoord(0.75, 1, 0, 0.25)
    topRight:SetPoint("TOPRIGHT", 5, 5)
    topRight:SetSize(32, 32)
    
    local bottomLeft = frame:CreateTexture(nil, "BORDER")
    bottomLeft:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")
    bottomLeft:SetTexCoord(0, 0.25, 0.75, 1)
    bottomLeft:SetPoint("BOTTOMLEFT", -5, -5)
    bottomLeft:SetSize(32, 32)
    
    local bottomRight = frame:CreateTexture(nil, "BORDER")
    bottomRight:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")
    bottomRight:SetTexCoord(0.75, 1, 0.75, 1)
    bottomRight:SetPoint("BOTTOMRIGHT", 5, -5)
    bottomRight:SetSize(32, 32)
end

-- Export the module
AzeriteMOP.SettingsMenu = SettingsMenu