local _, ns = ...

-- Constants
local MIN_WIDTH = 276
local MIN_HEIGHT = 330

-- Helper: Create a Header (mimics Dominos Panel:NewHeader)
local function NewHeader(parent, name, lastWidget)
    local frame = CreateFrame('Frame', nil, parent)
    
    local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    text:SetJustifyH('LEFT')
    text:SetPoint('BOTTOMLEFT', 0, 1)
    text:SetText(name)
    
    local border = frame:CreateTexture(nil, 'ARTWORK')
    border:SetPoint('TOPLEFT', text, 'BOTTOMLEFT')
    border:SetPoint('RIGHT')
    border:SetHeight(1)
    border:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    if lastWidget then
        frame:SetPoint('TOPLEFT', lastWidget, 'BOTTOMLEFT', 0, -30)
    else
        frame:SetPoint('TOPLEFT', 10, -4)
    end
    frame:SetPoint('RIGHT')
    
    local width, height = text:GetSize()
    frame:SetSize(width + 4, height + 4)
    
    return frame
end

-- Helper: Create a Slider (mimics Dominos Slider:New)
local function NewSlider(parent, name, min, max, step, getFunc, setFunc, lastWidget)
    local sliderName = "DominosFontChangeSlider" .. name:gsub("%s+", "") .. math.random(1000)
    
    -- Use standard template
    local slider = CreateFrame('Slider', sliderName, parent, 'OptionsSliderTemplate')
    
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    
    local low = _G[sliderName .. 'Low'] or slider.Low
    local high = _G[sliderName .. 'High'] or slider.High
    local text = _G[sliderName .. 'Text'] or slider.Text

    if low then low:SetText(min) end
    if high then high:SetText(max) end
    if text then text:SetText(name) end
    
    slider:SetScript('OnValueChanged', function(self, value)
        -- Round to step
        value = math.floor(value / step + 0.5) * step
        
        if not self.isRefreshing then
            setFunc(value)
        end
        
        if text then text:SetText(string.format("%s: %d", name, value)) end
    end)
    
    function slider:Refresh()
        self.isRefreshing = true
        self:SetValue(getFunc())
        self.isRefreshing = false
    end

    -- Initial value
    slider:Refresh()
    
    -- Positioning
    if lastWidget then
        slider:SetPoint('TOPLEFT', lastWidget, 'BOTTOMLEFT', 0, -20)
    else
        slider:SetPoint('TOPLEFT', 10, -20)
    end
    slider:SetWidth(170)
    
    return slider
end

-- Helper: Create Color Picker Button
-- Helper: Create Color Picker Button
local function NewColorPicker(parent, name, getFunc, setFunc, lastWidget)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(16, 16)
    
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1)
    button.bg = bg
    
    local swatch = button:CreateTexture(nil, "OVERLAY")
    swatch:SetPoint("CENTER")
    swatch:SetSize(14, 14)
    
    local function getColor()
        local r, g, b = getFunc()
        if type(r) == "table" then
            return r[1], r[2], r[3]
        end
        return r, g, b
    end

    local r, g, b = getColor()
    swatch:SetColorTexture(r, g, b)
    button.swatch = swatch
    
    local text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", button, "RIGHT", 5, 0)
    text:SetText(name)
    
    button:SetScript("OnClick", function()
        local r, g, b = getColor()
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b,
            swatchFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                swatch:SetColorTexture(newR, newG, newB)
                setFunc(newR, newG, newB)
            end,
            cancelFunc = function()
                swatch:SetColorTexture(r, g, b)
                setFunc(r, g, b)
            end,
        })
    end)
    
    if lastWidget then
        button:SetPoint("TOPLEFT", lastWidget, 'BOTTOMLEFT', 0, -10)
    else
        button:SetPoint("TOPLEFT", 10, -10)
    end
    
    function button:Refresh()
        local r, g, b = getColor()
        swatch:SetColorTexture(r, g, b)
    end
    
    return button
end

-- Helper: Create Reset Button
local function NewResetButton(parent, name, onClick, lastWidget)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetText(name)
    button:SetSize(100, 22)
    button:SetScript("OnClick", onClick)
    
    if lastWidget then
        button:SetPoint("TOPLEFT", lastWidget, "BOTTOMLEFT", 0, -10)
    else
        button:SetPoint("TOPLEFT", 10, -10)
    end
    
    return button
end

-- Helper: Create Dropdown
local function NewDropdown(parent, name, items, getFunc, setFunc, lastWidget)
    local dropdown = CreateFrame("Frame", "DominosFontChangeDropdown" .. name:gsub("%s+", ""), parent, "UIDropDownMenuTemplate")
    
    local label = dropdown:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 16, 3)
    label:SetText(name)
    
    UIDropDownMenu_SetWidth(dropdown, 200)
    UIDropDownMenu_SetText(dropdown, getFunc())
    
    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            setFunc(self.value)
            UIDropDownMenu_SetText(dropdown, self.value)
            CloseDropDownMenus()
        end
        
        local list = items
        if type(items) == "function" then
            list = items()
        end
        
        for _, item in ipairs(list) do
            info.text = item
            info.value = item
            info.checked = (item == getFunc())
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    if lastWidget then
        dropdown:SetPoint("TOPLEFT", lastWidget, "BOTTOMLEFT", 0, -20)
    else
        dropdown:SetPoint("TOPLEFT", 0, -20)
    end
    
    function dropdown:Refresh()
        UIDropDownMenu_SetText(dropdown, getFunc())
    end

    return dropdown
end

-- Helper: Get Available Fonts
local function getAvailableFonts()
    local fonts = {}
    local lsm = ns.GetLSM()
    if lsm then
        for _, fontName in ipairs(lsm:List("font")) do
            table.insert(fonts, fontName)
        end
    end
    if #fonts == 0 then
        fonts = { "Friz Quadrata TT", "Arial Narrow", "Morpheus", "Skurri" }
    end
    table.sort(fonts)
    return fonts
end

function ns.refreshOptionsPanel()
    if not ns.optionsPanel or not ns.optionsPanel.content then return end
    for _, child in ipairs({ns.optionsPanel.content:GetChildren()}) do
        if child.Refresh then
            child:Refresh()
        end
    end
end

local function resetTextSettings(key)
    if not ns.defaults[key] then return end
    DominosFontChangeDB[key] = ns.copyTable(ns.defaults[key])
    ns.updateVisibleButtons()
    if ns.updateColorPickerSwatch then
        ns.updateColorPickerSwatch(key)
    end
    ns.refreshOptionsPanel()
    print("Dominos FontChange: " .. key .. " settings reset.")
end
function ns.buildOptionsPanel()
    local panel = CreateFrame("Frame", "DominosFontChangeOptions", UIParent)
    panel.name = "Dominos FontChange"
    
    -- Content Frame (Directly attached, no scroll)
    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", 20, -20)
    content:SetPoint("BOTTOMRIGHT", -20, 20)
    panel.content = content
    
    -- Title
    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("Dominos FontChange")
    
    local lastWidget = title
    
    -- 1. Global Settings
    lastWidget = NewDropdown(content, "Font", getAvailableFonts, 
        function() return DominosFontChangeDB.font end,
        function(val) ns.setFontName(val) end,
        lastWidget
    )
    
    -- 2. Hotkey Settings
    lastWidget = NewHeader(content, "Hotkeys", lastWidget)
    
    local hotkeySize = NewSlider(content, "Size", 5, 32, 1,
        function() return DominosFontChangeDB.hotkey.size end,
        function(val) ns.setTextSize("hotkey", val) end,
        lastWidget
    )
    
    local hotkeyX = NewSlider(content, "Offset X", -20, 20, 1,
        function() return DominosFontChangeDB.hotkey.offsetX end,
        function(val) ns.setTextOffset("hotkey", "x", val) end,
        hotkeySize -- Place next to size? No, let's stack for now as per simple layout
    )
    hotkeyX:ClearAllPoints()
    hotkeyX:SetPoint("LEFT", hotkeySize, "RIGHT", 10, 0)
    
    local hotkeyY = NewSlider(content, "Offset Y", -20, 20, 1,
        function() return DominosFontChangeDB.hotkey.offsetY end,
        function(val) ns.setTextOffset("hotkey", "y", val) end,
        hotkeyX
    )
    hotkeyY:ClearAllPoints()
    hotkeyY:SetPoint("LEFT", hotkeyX, "RIGHT", 10, 0)
    
    lastWidget = hotkeySize -- Reset lastWidget to the row start for next elements
    
    local hotkeyColor = NewColorPicker(content, "Color",
        function() return ns.getColor(DominosFontChangeDB.hotkey, "hotkey") end,
        function(r, g, b) ns.setTextColor("hotkey", r, g, b) end,
        lastWidget
    )
    hotkeyColor:ClearAllPoints()
    hotkeyColor:SetPoint("TOPLEFT", hotkeySize, "BOTTOMLEFT", 0, -20)
    
    local hotkeyReset = NewResetButton(content, "Reset Hotkeys",
        function() resetTextSettings("hotkey") end,
        hotkeyColor
    )
    hotkeyReset:ClearAllPoints()
    hotkeyReset:SetPoint("TOPRIGHT", hotkeyY, "BOTTOMRIGHT", 0, -17)
    
    lastWidget = hotkeyColor
    
    -- 3. Macro Settings
    lastWidget = NewHeader(content, "Macros", lastWidget)
    
    local macroSize = NewSlider(content, "Size", 5, 32, 1,
        function() return DominosFontChangeDB.macro.size end,
        function(val) ns.setTextSize("macro", val) end,
        lastWidget
    )
    
    local macroX = NewSlider(content, "Offset X", -20, 20, 1,
        function() return DominosFontChangeDB.macro.offsetX end,
        function(val) ns.setTextOffset("macro", "x", val) end,
        macroSize
    )
    macroX:ClearAllPoints()
    macroX:SetPoint("LEFT", macroSize, "RIGHT", 10, 0)
    
    local macroY = NewSlider(content, "Offset Y", -20, 20, 1,
        function() return DominosFontChangeDB.macro.offsetY end,
        function(val) ns.setTextOffset("macro", "y", val) end,
        macroX
    )
    macroY:ClearAllPoints()
    macroY:SetPoint("LEFT", macroX, "RIGHT", 10, 0)
    
    local macroColor = NewColorPicker(content, "Color",
        function() return ns.getColor(DominosFontChangeDB.macro, "macro") end,
        function(r, g, b) ns.setTextColor("macro", r, g, b) end,
        macroSize
    )
    macroColor:ClearAllPoints()
    macroColor:SetPoint("TOPLEFT", macroSize, "BOTTOMLEFT", 0, -20)
    
    local macroReset = NewResetButton(content, "Reset Macros",
        function() resetTextSettings("macro") end,
        macroColor
    )
    macroReset:ClearAllPoints()
    macroReset:SetPoint("TOPRIGHT", macroY, "BOTTOMRIGHT", 0, -17)
    
    lastWidget = macroColor
    
    -- 4. Count Settings
    lastWidget = NewHeader(content, "Counts", lastWidget)
    
    local countSize = NewSlider(content, "Size", 5, 32, 1,
        function() return DominosFontChangeDB.count.size end,
        function(val) ns.setTextSize("count", val) end,
        lastWidget
    )
    
    local countX = NewSlider(content, "Offset X", -20, 20, 1,
        function() return DominosFontChangeDB.count.offsetX end,
        function(val) ns.setTextOffset("count", "x", val) end,
        countSize
    )
    countX:ClearAllPoints()
    countX:SetPoint("LEFT", countSize, "RIGHT", 10, 0)
    
    local countY = NewSlider(content, "Offset Y", -20, 20, 1,
        function() return DominosFontChangeDB.count.offsetY end,
        function(val) ns.setTextOffset("count", "y", val) end,
        countX
    )
    countY:ClearAllPoints()
    countY:SetPoint("LEFT", countX, "RIGHT", 10, 0)
    
    local countColor = NewColorPicker(content, "Color",
        function() return ns.getColor(DominosFontChangeDB.count, "count") end,
        function(r, g, b) ns.setTextColor("count", r, g, b) end,
        countSize
    )
    countColor:ClearAllPoints()
    countColor:SetPoint("TOPLEFT", countSize, "BOTTOMLEFT", 0, -20)
    
    local countReset = NewResetButton(content, "Reset Counts",
        function() resetTextSettings("count") end,
        countColor
    )
    countReset:ClearAllPoints()
    countReset:SetPoint("TOPRIGHT", countY, "BOTTOMRIGHT", 0, -17)
    
    
    -- Register Panel
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        ns.optionsCategory = category
    else
        -- Fallback for older clients (though we target Retail)
        InterfaceOptions_AddCategory(panel)
    end
    
    ns.optionsPanel = panel
end

function ns.InitializeConfig()
    ns.buildOptionsPanel()
end

-- Slash Command Handler
local function PrintUsage()
    print("|cff33ff99Dominos FontChange|r Usage:")
    print("  /domf options - Open the configuration panel")
end

local function HandleSlash(msg)
    local command = msg:trim():lower()
    if command == "options" or command == "config" then
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(ns.optionsCategory:GetID())
        else
            InterfaceOptionsFrame_OpenToCategory(ns.optionsPanel)
        end
    else
        PrintUsage()
    end
end

SLASH_DOMINOSFONTCHANGE1 = "/domf"
SLASH_DOMINOSFONTCHANGE2 = "/dominosfont"
SlashCmdList["DOMINOSFONTCHANGE"] = HandleSlash
