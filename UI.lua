-- Blizzard UI (цэс, тохиргоо) орчуулга:
--  1) Font объектуудыг кирилл фонтоор солино
--  2) Одоо байгаа бүх FontString/Button-ыг нэг удаа шалгана
--  3) SetText-ийг hook хийж, дараа үүсэх текстийг орчуулна
local DICT = MongolWoW_UI
local FONT = MongolWoW.FONT

local function Active()
    return MongolWoW.IsActive and MongolWoW.IsActive("ui")
end

-- ---------- 1. Font объектууд ----------
local fontsDone = false
local function ReplaceFontObjects()
    if fontsDone then return end
    fontsDone = true
    for name, obj in pairs(_G) do
        if type(name) == "string" and type(obj) == "table" then
            local ok, kind = pcall(function()
                return obj.GetObjectType and obj:GetObjectType()
            end)
            if ok and kind == "Font" then
                local ok2, _, size, flags = pcall(obj.GetFont, obj)
                if ok2 and size and size > 0 then
                    obj:SetFont(FONT, size, flags)
                end
            end
        end
    end
end

-- ---------- 2/3. Текст орчуулах ----------
local busy = false

local function Lookup(text)
    if type(text) ~= "string" or text == "" then return nil end
    local tr = DICT[text]
    if tr then return tr end
    -- төгсгөлд нь ":" эсвэл "..." байвал тусад нь хайна
    local base, tail = text:match("^(.-)(:?%.*)$")
    if tail ~= "" and base and DICT[base] then return DICT[base] .. tail end
    -- Динамик текст ("Level 12", "Rank 3", "Page 1/2"...)
    if #text < 60 and MongolWoW_UIPatterns then
        for i = 1, #MongolWoW_UIPatterns do
            local p = MongolWoW_UIPatterns[i]
            if text:find(p[1]) then
                return (text:gsub(p[1], p[2]))
            end
        end
    end
    return nil
end

-- Tooltip доторх мөрийг энд орчуулахгүй (item/spell нэрийг андуурахаас сэргийлнэ)
local function IsTooltipRegion(obj)
    local parent = obj:GetParent()
    local name = parent and parent.GetName and parent:GetName()
    return name ~= nil and name:find("Tooltip") ~= nil
end

local function SetFontKeepSize(fs)
    if not fs or not fs.GetFont then return end
    local _, size, flags = fs:GetFont()
    if size then fs:SetFont(FONT, size, flags) end
end

local function TranslateFS(fs)
    if busy or not Active() then return end
    if IsTooltipRegion(fs) then return end
    local tr = Lookup(fs:GetText())
    if tr then
        busy = true
        fs:SetText(tr)
        SetFontKeepSize(fs)
        busy = false
    end
end

local function TranslateButton(btn)
    if busy or not Active() then return end
    local tr = Lookup(btn:GetText())
    if tr then
        busy = true
        btn:SetText(tr)
        SetFontKeepSize(btn:GetFontString())
        busy = false
    end
end

local function SweepFrame(f)
    local n = select("#", f:GetRegions())
    for i = 1, n do
        local r = select(i, f:GetRegions())
        if r and r:GetObjectType() == "FontString" then TranslateFS(r) end
    end
    if f:IsObjectType("Button") and f.GetFontString and f:GetFontString() then
        TranslateButton(f)
    end
end

function MongolWoW.SweepAll()
    if not Active() then return end
    local f = EnumerateFrames()
    while f do
        pcall(SweepFrame, f)
        f = EnumerateFrames(f)
    end
end

-- SetText hook (FontString + Button)
local probe = CreateFrame("Frame")
local fsMeta = getmetatable(probe:CreateFontString()).__index
local btnMeta = getmetatable(CreateFrame("Button")).__index
hooksecurefunc(fsMeta, "SetText", function(self) TranslateFS(self) end)
hooksecurefunc(btnMeta, "SetText", function(self) TranslateButton(self) end)

-- Таймер: дараагийн frame-д sweep хийх (LoadOnDemand Blizzard UI-д)
local pending = false
local timer = CreateFrame("Frame")
timer:Hide()
timer:SetScript("OnUpdate", function(self)
    self:Hide()
    pending = false
    MongolWoW.SweepAll()
end)
local function QueueSweep()
    if not pending then pending = true timer:Show() end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, event, name)
    if event == "PLAYER_LOGIN" then
        if Active() then ReplaceFontObjects() end
        QueueSweep()
    elseif event == "ADDON_LOADED" and name and name:find("^Blizzard_") then
        QueueSweep()
    end
end)

-- Цонх нээгдэх бүрт дахин шалгана
for _, frameName in ipairs({
    "GameMenuFrame", "InterfaceOptionsFrame", "VideoOptionsFrame",
    "AudioOptionsFrame", "KeyBindingFrame", "MacroFrame",
    "CharacterFrame", "SpellBookFrame", "FriendsFrame", "QuestLogFrame",
    "WorldMapFrame", "MailFrame", "MerchantFrame", "TradeFrame",
    "PVPFrame", "LFDParentFrame", "GossipFrame", "QuestFrame",
    "ContainerFrame1", "BankFrame", "PetStableFrame", "TaxiFrame",
}) do
    local fr = _G[frameName]
    if fr then fr:HookScript("OnShow", QueueSweep) end
end
if InterfaceOptionsFrame_OpenToCategory then
    hooksecurefunc("InterfaceOptionsFrame_OpenToCategory", QueueSweep)
end
if InterfaceOptionsList_DisplayPanel then
    hooksecurefunc("InterfaceOptionsList_DisplayPanel", QueueSweep)
end
