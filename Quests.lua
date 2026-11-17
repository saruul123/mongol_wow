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

local function On() return MongolWoW.IsActive("quests") end

local function KeyOf(o, d)
    if o and o ~= "" then return o end
    return d
end

-- Орчуулгыг буцаана (Expand хийсэн); байхгүй бол nil + англи текстийг capture хийнэ
local function Tr(title, field, english, key)
    if not On() or not title or title == "" then return nil end
    local rec = Pick(title, key)
    local tr = rec and rec[field]
    if tr and tr ~= "" then return Expand(tr) end
    if field ~= "t" then Capture(title, field, english) end
    return nil
end

-- 3.3.5-ийн quest цонх (QuestInfo_*) текстээ эдгээр API-аас авдаг тул
-- API-г wrap хийснээр NPC detail/progress/reward болон quest log бүгд орчуулагдана.
local oGetTitleText = GetTitleText
local oGetQuestText = GetQuestText
local oGetObjectiveText = GetObjectiveText
local oGetProgressText = GetProgressText
local oGetRewardText = GetRewardText
local oGetQuestLogQuestText = GetQuestLogQuestText
local oGetQuestLogTitle = GetQuestLogTitle

function GetTitleText()
    local t = oGetTitleText()
    local d, o = oGetQuestText(), oGetObjectiveText()
    return Tr(t, "t", nil, KeyOf(o, d)) or t
end

function GetQuestText()
    local d = oGetQuestText()
    local title = oGetTitleText()
    return Tr(title, "d", d, KeyOf(oGetObjectiveText(), d)) or d
end

function GetObjectiveText()
    local o = oGetObjectiveText()
    local title = oGetTitleText()
    return Tr(title, "o", o, KeyOf(o, oGetQuestText())) or o
end

function GetProgressText()
    local p = oGetProgressText()
    return Tr(oGetTitleText(), "p", p) or p
end

function GetRewardText()
    local c = oGetRewardText()
    return Tr(oGetTitleText(), "c", c) or c
end

local function LogTitle()
    local sel = GetQuestLogSelection()
    if not sel or sel == 0 then return nil end
    local title, _, _, _, isHeader = oGetQuestLogTitle(sel)
    if not title or isHeader then return nil end
    return title
end

function GetQuestLogQuestText()
    local d, o = oGetQuestLogQuestText()
    local title = LogTitle()
    if not title then return d, o end
    local key = KeyOf(o, d)
    return Tr(title, "d", d, key) or d, Tr(title, "o", o, key) or o
end

-- Quest log-ийн гарчиг (QuestInfo-н гарчиг GetQuestLogTitle-аас авдаг)
local function SetLogTitle()
    if not On() then return end
    local title = LogTitle()
    if not title then return end
    local d, o = oGetQuestLogQuestText()
    local tr = Tr(title, "t", nil, KeyOf(o, d))
    if not tr then return end
    if QuestInfoTitleHeader then QuestInfoTitleHeader:SetText(tr) end
    if QuestLogQuestTitle then QuestLogQuestTitle:SetText(tr) end
end
if QuestLog_UpdateQuestDetails then hooksecurefunc("QuestLog_UpdateQuestDetails", SetLogTitle) end

-- Quest log жагсаалт + quest tracker (WatchFrame): quest-ийн нэрийг орчуулна.
-- Өмнө нь oGetQuestLogTitle-ийг дотоод хайлтдаа ашигласан тул англи нэрээр хайна.
local function WrapTitle(title, level, tag, group, isHeader, ...)
    if title and not isHeader and On() then
        local rec = Pick(title)
        local tr = rec and rec.t
        if tr and tr ~= "" then title = Expand(tr) end
    end
    return title, level, tag, group, isHeader, ...
end
function GetQuestLogTitle(i)
    return WrapTitle(oGetQuestLogTitle(i))
end

-- Зорилгын мөр ("Kobold Vermin slain: 0/8"): нэр хэвээр, "slain"-ийг орчуулна
local oGetQuestLogLeaderBoard = GetQuestLogLeaderBoard
function GetQuestLogLeaderBoard(i, q)
    local text, kind, done = oGetQuestLogLeaderBoard(i, q)
    if text and On() then
        text = text:gsub("^(.-) slain:", "%1 алагдсан:")
    end
    return text, kind, done
end

-- /mn quests: хэдэн quest цугларсан/орчуулагдсаныг харуулна
function MongolWoW.QuestStats()
    local cap, tr = 0, 0
    for _ in pairs(MongolWoWDB.captured or {}) do cap = cap + 1 end
    for _, rec in pairs(DATA) do tr = tr + (rec.v and #rec.v or 1) end
    MongolWoW.Print(string.format(MongolWoW_L["quest_stats"], tr, cap))
end
