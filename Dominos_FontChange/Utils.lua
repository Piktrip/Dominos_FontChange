local addonName, ns = ...

-- LibSharedMedia support
ns.LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

--- Get LibSharedMedia instance (lazy load)
function ns.GetLSM()
    if not ns.LSM then
        ns.LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    end
    return ns.LSM
end

-- ... (rest of file)

--- Fetch the font path from LibSharedMedia or return default
-- @param name The name of the font
-- @return The file path to the font
function ns.fetchFontPath(name)
    local lsm = ns.GetLSM()
    if lsm then
        local font = lsm:Fetch("font", name, true)
        if font then
            return font
        end
    end
    return STANDARD_TEXT_FONT
end

-- Default settings
ns.defaults = {
    font = "Friz Quadrata TT",
    hotkey = { size = 14, color = { 1, 0.82, 0 }, offsetX = 0, offsetY = 0 },
    macro = { size = 12, color = { 1, 1, 1 }, offsetX = 0, offsetY = 0 },
    count = { size = 12, color = { 1, 1, 1 }, offsetX = 0, offsetY = 0 },
}

-- Constants
ns.MIN_FONT_SIZE = 6
ns.MAX_FONT_SIZE = 32

--- Deep copy a table
-- @param src The source table
-- @return A deep copy of the table
function ns.copyTable(src)
    if type(src) ~= "table" then
        return src
    end
    local dst = {}
    for k, v in pairs(src) do
        dst[k] = ns.copyTable(v)
    end
    return dst
end

--- Clamp a color value between 0 and 1
-- @param value The value to clamp
-- @return The clamped value
function ns.clampColorValue(value)
    value = tonumber(value) or 1
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

--- Clamp font size between MIN and MAX
-- @param value The font size
-- @return The clamped font size
function ns.clampFontSize(value)
    return math.max(ns.MIN_FONT_SIZE, math.min(ns.MAX_FONT_SIZE, math.floor(value + 0.5)))
end

--- Get color for a specific entry type
-- @param entry The database entry (can be nil)
-- @param key The key type (hotkey, macro, count)
-- @return A table {r, g, b}
function ns.getColor(entry, key)
    local color = entry and entry.color
    if not color then
        color = ns.defaults[key].color
    end
    return { color[1], color[2], color[3] }
end

--- Get offsets for a specific entry type
-- @param entry The database entry (can be nil)
-- @param key The key type (hotkey, macro, count)
-- @return offsetX, offsetY
function ns.getOffsets(entry, key)
    local data = entry or ns.defaults[key]
    return data.offsetX or 0, data.offsetY or 0
end


