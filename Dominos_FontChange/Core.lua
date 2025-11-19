local addonName, ns = ...

if not Dominos then
    return
end

-- Ensure the database is initialized with defaults
function ns.ensureDefaults()
    DominosFontChangeDB = DominosFontChangeDB or ns.copyTable(ns.defaults)
    for k, v in pairs(ns.defaults) do
        DominosFontChangeDB[k] = DominosFontChangeDB[k] or ns.copyTable(v)
        if type(v) == "table" then
            for sk, sv in pairs(v) do
                if DominosFontChangeDB[k][sk] == nil then
                    DominosFontChangeDB[k][sk] = ns.copyTable(sv)
                elseif type(sv) == "table" and type(DominosFontChangeDB[k][sk]) ~= "table" then
                    DominosFontChangeDB[k][sk] = ns.copyTable(sv)
                end
            end
        end
    end
end

--- Apply font settings to a specific font string
-- @param fontString The FontString object
-- @param key The type of text (hotkey, macro, count)
function ns.applyFont(fontString, key)
    if not fontString or not key then
        return
    end

    local entry = DominosFontChangeDB[key]
    local fontPath = ns.fetchFontPath(DominosFontChangeDB.font)
    local size = entry.size or ns.defaults[key].size
    local color = ns.getColor(entry, key)
    local offsetX, offsetY = ns.getOffsets(entry, key)
    
    -- Workaround for font update issues:
    -- Briefly switch to a standard font to force a texture refresh, then apply the desired font.
    -- This avoids modifying the text content which caused issues.
    fontString:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
    fontString:SetFont(fontPath, size, "OUTLINE")
    
    if color then
        fontString:SetTextColor(color[1] or 1, color[2] or 1, color[3] or 1)
    end
    
    -- Force geometry update
    local text = fontString:GetText()
    if text then
        fontString:SetText(text)
    end
    
    if fontString:GetParent() then
        fontString:ClearAllPoints()
        fontString:SetPoint("CENTER", fontString:GetParent(), "CENTER", offsetX, offsetY)
    end
    
    if ns.updateColorPickerSwatch then
        ns.updateColorPickerSwatch(key)
    end
end

--- Update all visible buttons in Dominos
function ns.updateVisibleButtons()
    if InCombatLockdown() then
        return
    end

    -- Helper to process a bar if it exists
    local function processBar(bar)
        if bar and bar.buttons then
            for _, btn in pairs(bar.buttons) do
                ns.applyFont(btn.HotKey, "hotkey")
                ns.applyFont(btn.Name, "macro")
                ns.applyFont(btn.Count, "count")
            end
        end
    end

    -- Action Bars 1-10 (Standard Dominos)
    if Dominos.ActionBar then
        for id = 1, 10 do
            processBar(Dominos.ActionBar:Get(id))
        end
    end

    -- Additional Bars (Pet, Class/Stance, Vehicle)
    if Dominos.PetBar then processBar(Dominos.PetBar) end
    if Dominos.ClassBar then processBar(Dominos.ClassBar) end
    if Dominos.VehicleBar then processBar(Dominos.VehicleBar) end
    
    -- Try to catch any other bars registered in Dominos
    if Dominos.Frame and Dominos.Frame.getAll then
        for _, frame in pairs(Dominos.Frame.getAll()) do
            if frame.buttons then
                 processBar(frame)
            end
        end
    end
end

--- Set text size setting
-- @param key The key (hotkey, macro, count)
-- @param value The new size
-- @param sourceIsUI True if called from the options UI (prevents refresh loop)
function ns.setTextSize(key, value, sourceIsUI)
    local entry = DominosFontChangeDB[key]
    if not entry then return end
    
    local size = ns.clampFontSize(value or entry.size or ns.defaults[key].size)
    if entry.size ~= size then
        entry.size = size
        ns.updateVisibleButtons()
    end
    
    if not sourceIsUI and ns.refreshOptionsPanel then
        ns.refreshOptionsPanel()
    end
end

--- Set text color setting
-- @param key The key (hotkey, macro, count)
-- @param r Red (0-1)
-- @param g Green (0-1)
-- @param b Blue (0-1)
-- @param sourceIsUI True if called from the options UI
function ns.setTextColor(key, r, g, b, sourceIsUI)
    local entry = DominosFontChangeDB[key]
    if not entry then return end
    
    local color = entry.color or ns.copyTable(ns.defaults[key].color)
    local nr, ng, nb = ns.clampColorValue(r), ns.clampColorValue(g), ns.clampColorValue(b)
    
    if color[1] ~= nr or color[2] ~= ng or color[3] ~= nb then
        entry.color = { nr, ng, nb }
        ns.updateVisibleButtons()
        if ns.updateColorPickerSwatch then
            ns.updateColorPickerSwatch(key)
        end
    end
    
    if not sourceIsUI and ns.refreshOptionsPanel then
        ns.refreshOptionsPanel()
    end
end

--- Set text offset setting
-- @param key The key (hotkey, macro, count)
-- @param axis "x" or "y"
-- @param value The offset value in pixels
-- @param sourceIsUI True if called from the options UI
function ns.setTextOffset(key, axis, value, sourceIsUI)
    local entry = DominosFontChangeDB[key]
    if not entry then return end
    
    local field = axis == "x" and "offsetX" or "offsetY"
    value = math.floor((value or 0) + 0.5)
    
    if entry[field] ~= value then
        entry[field] = value
        ns.updateVisibleButtons()
    end
    
    if not sourceIsUI and ns.refreshOptionsPanel then
        ns.refreshOptionsPanel()
    end
end

--- Set the global font face
-- @param fontName The name of the font (from LSM)
-- @param sourceIsUI True if called from the options UI
function ns.setFontName(fontName, sourceIsUI)
    if not fontName or fontName == "" then return end
    
    if DominosFontChangeDB.font ~= fontName then
        DominosFontChangeDB.font = fontName
        ns.updateVisibleButtons()
    end
    
    if not sourceIsUI and ns.refreshOptionsPanel then
        ns.refreshOptionsPanel()
    end
end

-- Hooks
hooksecurefunc(Dominos.BindableButton, "UpdateHotkeys", function(self)
    ns.applyFont(self.HotKey, "hotkey")
end)

hooksecurefunc(Dominos.ActionButton, "SetShowMacroText", function(self)
    ns.applyFont(self.Name, "macro")
end)

hooksecurefunc(Dominos.ActionButton, "SetShowCounts", function(self)
    ns.applyFont(self.Count, "count")
end)

-- Event Registration
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        ns.ensureDefaults()
        if ns.InitializeConfig then
            ns.InitializeConfig()
        end
        -- Unregister ADDON_LOADED as we only need it once
        frame:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_ENTERING_WORLD" then
        ns.ensureDefaults() -- Ensure defaults again just in case
        ns.updateVisibleButtons()
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.updateVisibleButtons()
    end
end)
