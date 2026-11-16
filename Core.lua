local L = MongolWoW_L
MongolWoW = { L = L, enabled = true }

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffMongolWoW:|r " .. msg)
end
MongolWoW.Print = Print

MongolWoW.DEFAULTS = { enabled = true, ui = true, quests = true, tooltips = true, chat = true }

-- Модулиуд ашиглана: үндсэн + тухайн модуль хоёулаа асаалттай эсэх
function MongolWoW.IsActive(module)
    if not MongolWoWDB or not MongolWoWDB.enabled then return false end
    return module == nil or MongolWoWDB[module] ~= false
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
    if name ~= "MongolWoW" then return end
    MongolWoWDB = MongolWoWDB or {}
    for k, v in pairs(MongolWoW.DEFAULTS) do
        if MongolWoWDB[k] == nil then MongolWoWDB[k] = v end
    end
    MongolWoWDB.captured = MongolWoWDB.captured or {}
    MongolWoW.enabled = MongolWoWDB.enabled
    if MongolWoW.optionsPanel then MongolWoW.optionsPanel.refresh() end
    Print(L["loaded"])
    self:UnregisterEvent("ADDON_LOADED")
end)

SLASH_MONGOLWOW1 = "/mn"
SlashCmdList["MONGOLWOW"] = function(msg)
    msg = strlower(strtrim(msg or ""))
    if msg == "on" or msg == "off" then
        MongolWoW.enabled = (msg == "on")
        MongolWoWDB.enabled = MongolWoW.enabled
        Print(MongolWoW.enabled and L["enabled"] or L["disabled"])
        if MongolWoW.optionsPanel then MongolWoW.optionsPanel.refresh() end
    elseif msg == "fonttest" then
        MongolWoW.FontTest()
    elseif msg == "quests" then
        MongolWoW.QuestStats()
    elseif msg == "config" or msg == "options" then
        MongolWoW.OpenOptions()
    else
        Print(L["help"])
    end
end
