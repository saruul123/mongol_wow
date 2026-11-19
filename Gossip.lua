-- NPC gossip/мэндчилгээ (GossipFrame, QuestFrameGreetingPanel) орчуулга.
-- Текстийг англи эхээр нь (prefix/suffix түлхүүрээр) хайна: сервер $N/$C/$R-ийг аль хэдийн
-- тоглогчийн нэр/ангиар солиод илгээдэг тул тэдгээрийг хасаж харьцуулна.
MongolWoW_Gossip = MongolWoW_Gossip or { texts = {}, opts = {} }
local G = MongolWoW_Gossip
local function On() return MongolWoW.IsActive("quests") end

local function Norm(s) return (s:lower():gsub("[^0-9a-z]", "")) end
local function Esc(s) return (s:gsub("(%W)", "%%%1")) end

local buckets
local function Index()
    buckets = {}
    for _, e in ipairs(G.texts) do
        local k = e.p:sub(1, 6)
        local b = buckets[k]
        if not b then b = {}; buckets[k] = b end
        b[#b + 1] = e
    end
end

local function Match(list, n)
    if not list then return nil end
    for _, e in ipairs(list) do
        local pl, sl = #e.p, #e.s
        if #n >= pl + sl and n:sub(1, pl) == e.p and (sl == 0 or n:sub(-sl) == e.s) then
            return e.t
        end
    end
end

local function LookupText(text)
    if not buckets then Index() end
    for _, v in ipairs({ UnitName("player"), UnitClass("player"), UnitRace("player") }) do
        if v and v ~= "" then text = text:gsub(Esc(v), "") end
    end
    local n = Norm(text)
    return Match(buckets[n:sub(1, 6)], n) or Match(buckets[""], n)
end

local function TrText(text)
    if On() and text and text ~= "" then
        local m = LookupText(text)
        if m then return MongolWoW.Expand(m) end
    end
    return text
end

local oGetGossipText = GetGossipText
function GetGossipText() return TrText(oGetGossipText()) end
local oGetGreetingText = GetGreetingText
function GetGreetingText() return TrText(oGetGreetingText()) end

-- name1, type1, name2, type2, ...
local function TrOptions(...)
    local n = select("#", ...)
    local r = { ... }
    if On() then
        for i = 1, n do
            local v = r[i]
            if type(v) == "string" then r[i] = G.opts[v] or v end
        end
    end
    return unpack(r, 1, n)
end
local oGetGossipOptions = GetGossipOptions
function GetGossipOptions() return TrOptions(oGetGossipOptions()) end

-- Gossip доторх quest жагсаалт: аргумент бүрээс quest-ийн нэрийг хайж орчуулна
local function TrTitles(...)
    local n = select("#", ...)
    local r = { ... }
    if On() then
        for i = 1, n do
            if type(r[i]) == "string" then r[i] = MongolWoW.QuestTitle(r[i]) or r[i] end
        end
    end
    return unpack(r, 1, n)
end
local oAvail, oActive = GetGossipAvailableQuests, GetGossipActiveQuests
function GetGossipAvailableQuests() return TrTitles(oAvail()) end
function GetGossipActiveQuests() return TrTitles(oActive()) end

-- Олон quest-тэй NPC-ийн мэндчилгээний цонх
local oAvailTitle, oActiveTitle = GetAvailableTitle, GetActiveTitle
function GetAvailableTitle(i) return TrTitles(oAvailTitle(i)) end
function GetActiveTitle(i) return TrTitles(oActiveTitle(i)) end
