-- AzeriteMOP ChatFrame Module
-- Simple, working implementation for MoP Classic

local ADDON_NAME, Addon = ...
local AzeriteMOP = AzeriteMOP or {}

-- Local variables
local chatModuleInit = false

-- Module initialization
local ChatFrame = {}

function ChatFrame:Initialize()
    AzeriteMOP:Debug("Initializing ChatFrame module...")
    
    -- Ensure chat frame settings exist in database
    if not AzeriteMOP.db.chatFrame then
        AzeriteMOP.db.chatFrame = {
            enabled = true,
            fade = true,
            editboxHide = true,
            addTimestamp = false,
            numScrollMessages = 3,
            scrollDownInterval = 0,
            maxCopyLines = 100
        }
    end
    
    if not AzeriteMOP.db.chatFrame.enabled then
        AzeriteMOP:Debug("ChatFrame module disabled")
        return
    end

    -- Simple chat frame styling
    self:StyleChatFrames()
    
    -- Add test message
    if ChatFrame1 then
        ChatFrame1:AddMessage("|cFF4488FF[AzeriteMOP]|r ChatFrame module loaded successfully!")
    end
    
    chatModuleInit = true
    AzeriteMOP:Debug("ChatFrame module initialized successfully!")
end

function ChatFrame:StyleChatFrames()
    -- Style each chat frame
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame then
            AzeriteMOP:Debug("Styling ChatFrame" .. i)
            self:StyleSingleChatFrame(frame)
                end
            end
end

function ChatFrame:StyleSingleChatFrame(frame)
    local name = frame:GetName()
    
    -- Don't style if already styled
    if frame.azeriteStyled then
            return
    end
    
    -- Basic styling
    frame:SetClampRectInsets(0, 0, 0, 0)
    frame:SetClampedToScreen(false)
    
    -- Make chat frame more transparent (40% opacity = 60% transparent)
    frame:SetAlpha(0.4)
    
        -- Add chat frame background texture
    if not frame.azeriteBackground then
        local chatBg = frame:CreateTexture(nil, "BACKGROUND")
        chatBg:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\chat\\chatframe_background.tga")
        chatBg:SetAllPoints()
        chatBg:SetTexCoord(.2, 1.1, .2, 1.1)
        frame.azeriteBackground = chatBg
        
        -- Add chat frame border texture (below background)
        local chatBorder = frame:CreateTexture(nil, "BORDER")
        chatBorder:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\chat\\chatframeborder.tga")
        chatBorder:SetAllPoints()
        chatBorder:SetTexCoord(0, 1, 0, 1)
        frame.azeriteBorder = chatBorder
        
        -- Hide default chat frame background
        local defaultBg = _G[name .. "Background"]
        if defaultBg then
            defaultBg:Hide()
    end
end

    -- Style the tab (Classic-compatible approach)
    local tab = _G[name .. "Tab"]
    if tab then
        AzeriteMOP:Debug("Styling tab for " .. name)
        
        -- Make tab transparent to match chat frame (40% opacity = 60% transparent)
        tab:SetAlpha(0.4)
        if tab.Text then
            tab.Text:SetTextColor(1, 1, 1, 1)
        end
        
        -- Classic-compatible tab styling
        -- Get the tab's regions (textures)
        local regions = {tab:GetRegions()}
        AzeriteMOP:Debug("Tab regions found: " .. #regions)
        
        -- Apply textures to tab regions
        for i, region in ipairs(regions) do
            if region:GetObjectType() == "Texture" then
                AzeriteMOP:Debug("Found texture region " .. i)
                region:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\chat\\chattabactive.tga")
                region:SetVertexColor(1, 1, 1, 1)
        end
    end

        -- Create a background texture for the tab
        if not tab.azeriteBackground then
            local tabBg = tab:CreateTexture(nil, "BACKGROUND")
            tabBg:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\chat\\chattabactive.tga")
            tabBg:SetAllPoints()
            tabBg:SetVertexColor(1, 1, 1, 1)
            tab.azeriteBackground = tabBg
            AzeriteMOP:Debug("Created tab background texture")
        end
        
        -- Hook tab alpha changes (Classic-compatible)
        if not tab.azeriteStyled then
            hooksecurefunc(tab, "SetAlpha", function(t, alpha)
                if alpha < 0.6 then
                    t:SetAlpha(0.6)
                end
            end)
            
            tab.azeriteStyled = true
            end
        else
        AzeriteMOP:Debug("Tab not found for " .. name)
    end
    
    -- Style the edit box
    local editBox = frame.editBox
    if editBox then
        -- Make edit box more visible
        editBox:SetTextColor(1, 1, 1, 1)
        
        -- Set custom edit box texture
        if not editBox.azeriteStyled then
            -- Hide ALL default edit box textures first
            local editBoxLeft = _G[name .. "EditBoxLeft"]
            local editBoxMid = _G[name .. "EditBoxMid"]
            local editBoxRight = _G[name .. "EditBoxRight"]
            
            if editBoxLeft then editBoxLeft:Hide() end
            if editBoxMid then editBoxMid:Hide() end
            if editBoxRight then editBoxRight:Hide() end
            
            -- Hide any existing regions in the edit box
            local regions = {editBox:GetRegions()}
            for _, region in ipairs(regions) do
                if region:GetObjectType() == "Texture" then
                    region:Hide()
		end
	end

            -- Create background texture for edit box
            local editBoxBg = editBox:CreateTexture(nil, "BACKGROUND")
            editBoxBg:SetTexture("Interface\\AddOns\\AzeriteMOP\\Textures\\chat\\chateditboxmid.tga")
            editBoxBg:SetAllPoints()
            -- Stretch texture by 20% (0.1 on each side)
            editBoxBg:SetTexCoord(-0.1, 1.1, -0.1, 1.1)
            editBox.background = editBoxBg
            
            -- Clear any default text
            editBox:SetText("")
            
            editBox.azeriteStyled = true
            AzeriteMOP:Debug("Edit box styled with custom texture")
        end
        
                -- Add character count
        if not editBox.charCount then
            local charCount = editBox:CreateFontString(nil, "OVERLAY")
            charCount:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            charCount:SetTextColor(0.7, 0.7, 0.7, 0.8)
            charCount:SetPoint("TOPRIGHT", editBox, "TOPRIGHT", -5, 0)
            charCount:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMRIGHT", -5, 0)
            charCount:SetJustifyH("CENTER")
            charCount:SetWidth(40)
            editBox.charCount = charCount
            
            -- Update character count
            editBox:HookScript("OnTextChanged", function(self)
                local text = self:GetText()
                local count = string.len(text)
                self.charCount:SetText(count)
            end)
            
            AzeriteMOP:Debug("Character count added to edit box")
        end
            end

    -- Add mouse wheel scrolling
    if not frame.scriptsSet then
        frame:SetScript("OnMouseWheel", function(self, delta)
            local numScrollMessages = AzeriteMOP.db.chatFrame.numScrollMessages or 3
    if delta < 0 then
            for _ = 1, numScrollMessages do
                self:ScrollDown()
        end
    elseif delta > 0 then
            for _ = 1, numScrollMessages do
                self:ScrollUp()
            end
        end
        end)
            frame.scriptsSet = true
    end
    
    -- Mark as styled
    frame.azeriteStyled = true
end

-- Additional functions for AzeriteMOP integration
function ChatFrame:Toggle()
    if not AzeriteMOP.db.chatFrame then
        AzeriteMOP.db.chatFrame = {}
    end
    
    AzeriteMOP.db.chatFrame.enabled = not AzeriteMOP.db.chatFrame.enabled
    
    if AzeriteMOP.db.chatFrame.enabled then
        self:Initialize()
        AzeriteMOP:Debug("ChatFrame module enabled")
    else
        AzeriteMOP:Debug("ChatFrame module disabled")
    end
end

function ChatFrame:IsEnabled()
    return AzeriteMOP.db and AzeriteMOP.db.chatFrame and AzeriteMOP.db.chatFrame.enabled
end

-- Export module
AzeriteMOP.ChatFrame = ChatFrame
