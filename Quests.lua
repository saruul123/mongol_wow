-- Quest орчуулга: NPC-ийн quest цонх (detail/progress/reward) + Quest log.
-- Түлхүүр нь quest-ийн англи нэр. Орчуулга байхгүй бол англи текстийг
-- MongolWoWDB.captured-д хадгална (Tools/quests_tool.py-аар орчуулахад бэлтгэнэ).
MongolWoW_Quests = MongolWoW_Quests or {}
local DATA = MongolWoW_Quests
local FONT = MongolWoW.FONT

-- ---------- Placeholder задлах: $N $C $R $B $g<эр>:<эм>; ----------
local function Expand(text)
    local name = UnitName("player") or ""
    local class = UnitClass("player") or ""
    local race = UnitRace("player") or ""
    local female = (UnitSex("player") == 3)
    text = text:gsub("%$[gG]([^:;]*):([^;]*);", function(m, f) return female and f or m end)
    text = text:gsub("%$[nN]", function() return name end)
    text = text:gsub("%$[cC]", function() return class end)
    text = text:gsub("%$[rR]", function() return race end)
    text = text:gsub("%$[bB]", "\n")
    return text
end

-- Captured текстэд тоглогчийн нэрийг $N болгож буцаана
local function Unexpand(text)
    local name = UnitName("player")
    if name and name ~= "" then
        text = text:gsub(name, "$N")
    end
    return text
end

local function Capture(title, field, english)
    if not title or title == "" or not english or english == "" then return end
    local rec = MongolWoWDB and MongolWoWDB.captured
    if not rec then return end
    rec[title] = rec[title] or {}
    if field == "t" then return end
    if not rec[title][field] then rec[title][field] = Unexpand(english) end
end

-- Давхардсан нэртэй quest: DATA[title].v = { {k=<англи зорилгын түлхүүр>, t,d,o,p,c}, ... }
-- k = англи зорилго (байхгүй бол тайлбар)-ын үсэг/тооноос бүрдэх жижиг үсгийн эхлэл.
local KEYLEN = 40
local function Norm(text)
    return (text or ""):lower():gsub("[^%w]", ""):sub(1, KEYLEN)
end
local LAST = {} -- title -> сүүлд сонгогдсон хувилбар (progress/reward цонхонд ID байхгүй)

local function Pick(title, key)
    local rec = DATA[title]
    if not rec then return nil end
    if not rec.v then return rec end
    if key and key ~= "" then
        local nk = Norm(key)
        for _, v in ipairs(rec.v) do
            if v.k and v.k ~= "" and nk:sub(1, #v.k) == v.k then
                LAST[title] = v
                return v
            end
        end
        return rec.t and rec or nil
    end
    return LAST[title] or (rec.t and rec) or rec.v[1]
end

-- english-ийг DATA-аас хайж fs-д тавина; байхгүй бол capture хийнэ
-- key: хувилбар ялгах англи текст (зорилго эсвэл тайлбар)
local function Do(title, field, fs, english, key)
    if not title or title == "" or not fs then return end
    local rec = Pick(title, key)
    local tr = rec and rec[field]
    if tr then
        fs:SetText(Expand(tr))
        local _, size, flags = fs:GetFont()
        if size then fs:SetFont(FONT, size, flags) end
    elseif field ~= "t" then
        Capture(title, field, english)
    end
end

local function KeyOf(o, d)
    if o and o ~= "" then return o end
    return d
end

local function On() return MongolWoW.IsActive("quests") end

-- ---------- NPC quest цонхууд ----------
local function Detail()
    if not On() then return end
    local title = GetTitleText()
    local d, o = GetQuestText(), GetObjectiveText()
    local key = KeyOf(o, d)
    Do(title, "t", QuestTitleText, nil, key)
    Do(title, "d", QuestDescription, d, key)
    Do(title, "o", QuestObjectiveText, o, key)
end

local function Progress()
    if not On() then return end
    local title = GetTitleText()
    Do(title, "t", QuestProgressTitleText)
    Do(title, "p", QuestProgressText, GetProgressText())
end

local function Reward()
    if not On() then return end
    local title = GetTitleText()
    Do(title, "t", QuestRewardTitleText)
    Do(title, "c", QuestRewardText, GetRewardText())
end

if QuestFrameDetailPanel_OnShow then hooksecurefunc("QuestFrameDetailPanel_OnShow", Detail) end
if QuestFrameProgressPanel_OnShow then hooksecurefunc("QuestFrameProgressPanel_OnShow", Progress) end
if QuestFrameRewardPanel_OnShow then hooksecurefunc("QuestFrameRewardPanel_OnShow", Reward) end

-- ---------- Quest log ----------
local function LogDetails()
    if not On() then return end
    local sel = GetQuestLogSelection()
    if not sel or sel == 0 then return end
    local title, _, _, _, isHeader = GetQuestLogTitle(sel)
    if not title or isHeader then return end
    -- 3.3.5: GetQuestLogQuestText() нь (description, objectives) буцаадаг
    local d, o = GetQuestLogQuestText()
    local key = KeyOf(o, d)
    Do(title, "t", QuestLogQuestTitle, nil, key)
    Do(title, "d", QuestLogQuestDescription, d, key)
    Do(title, "o", QuestLogObjectivesText, o, key)
    if QuestLogDetailScrollFrame and QuestLogDetailScrollFrame.UpdateScrollChildRect then
        QuestLogDetailScrollFrame:UpdateScrollChildRect()
    end
end
if QuestLog_UpdateQuestDetails then hooksecurefunc("QuestLog_UpdateQuestDetails", LogDetails) end

-- Scroll хэмжээ: NPC цонхонд ч мөн шинэчилнэ
local function Rescroll()
    if QuestDetailScrollFrame and QuestDetailScrollFrame.UpdateScrollChildRect then
        QuestDetailScrollFrame:UpdateScrollChildRect()
    end
    if QuestRewardScrollFrame and QuestRewardScrollFrame.UpdateScrollChildRect then
        QuestRewardScrollFrame:UpdateScrollChildRect()
    end
end
if QuestFrameDetailPanel then QuestFrameDetailPanel:HookScript("OnShow", Rescroll) end
if QuestFrameRewardPanel then QuestFrameRewardPanel:HookScript("OnShow", Rescroll) end

-- /mn quests: хэдэн quest цугларсан/орчуулагдсаныг харуулна
function MongolWoW.QuestStats()
    local cap, tr = 0, 0
    for _ in pairs(MongolWoWDB.captured or {}) do cap = cap + 1 end
    for _, rec in pairs(DATA) do tr = tr + (rec.v and #rec.v or 1) end
    MongolWoW.Print(string.format(MongolWoW_L["quest_stats"], tr, cap))
end
