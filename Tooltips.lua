-- Tooltip орчуулга: item/spell tooltip доторх тогтмол мөрүүд (толь бичиг + pattern).
-- Item/spell-ийн нэр, тайлбарыг орчуулахгүй (англиар үлдэнэ).
local FONT = MongolWoW.FONT

local EXACT = {
    ["Binds when picked up"] = "Авахад өөрт холбогдоно",
    ["Binds when equipped"] = "Өмсөхөд өөрт холбогдоно",
    ["Binds when used"] = "Хэрэглэхэд өөрт холбогдоно",
    ["Soulbound"] = "Өөрт холбогдсон",
    ["Account Bound"] = "Бүртгэлд холбогдсон",
    ["Unique"] = "Өвөрмөц",
    ["Unique-Equipped"] = "Өвөрмөц-өмсдөг",
    ["Quest Item"] = "Quest-ийн эд",
    ["Head"] = "Малгай", ["Neck"] = "Хүзүү", ["Shoulder"] = "Мөр", ["Back"] = "Нуруу",
    ["Chest"] = "Цээж", ["Shirt"] = "Цамц", ["Wrist"] = "Бугуй", ["Hands"] = "Гар",
    ["Waist"] = "Бүс", ["Legs"] = "Хөл", ["Feet"] = "Гутал", ["Finger"] = "Бөгж",
    ["Trinket"] = "Trinket", ["Main Hand"] = "Гол гар", ["Off Hand"] = "Туслах гар",
    ["One-Hand"] = "Нэг гар", ["Two-Hand"] = "Хоёр гар", ["Held In Off-hand"] = "Туслах гарт барих",
    ["Ranged"] = "Холын", ["Thrown"] = "Шидэх", ["Relic"] = "Relic",
    ["Cloth"] = "Даавуу", ["Leather"] = "Арьс", ["Mail"] = "Мөнгөн дуулга", ["Plate"] = "Хуягт",
    ["Shield"] = "Бамбай", ["Sword"] = "Сэлэм", ["Axe"] = "Сүх", ["Mace"] = "Алх",
    ["Dagger"] = "Дага", ["Staff"] = "Таяг", ["Polearm"] = "Жад", ["Bow"] = "Нум",
    ["Gun"] = "Буу", ["Crossbow"] = "Хөндлөн нум", ["Wand"] = "Саваа", ["Fist Weapon"] = "Нударганы зэвсэг",
    ["Instant"] = "Агшин", ["Instant cast"] = "Агшин ашиглалт", ["Passive"] = "Идэвхгүй (passive)",
    ["Melee Range"] = "Ойрын зай", ["Unlimited range"] = "Хязгааргүй зай",
    ["Requires combat"] = "Тулалдаанд байх ёстой",
    ["Sell Price:"] = "Зарах үнэ:", ["Vendor Price:"] = "Худалдагчийн үнэ:",
    ["Use:"] = "Хэрэглэх:", ["Equip:"] = "Өмсөх:", ["Chance on hit:"] = "Цохихдоо магадлалтай:",
    ["Cooldown remaining:"] = "Үлдсэн cooldown:",
}

local PATTERNS = {
    { "^Requires Level (%d+)$", "Шаардлага: %1-р түвшин" },
    { "^Item Level (%d+)$", "Эдийн түвшин %1" },
    { "^(%d+) Armor$", "%1 Хуяг" },
    { "^Durability (%d+) / (%d+)$", "Бат бэх %1 / %2" },
    { "^(%d+) Slot (.+)$", "%1 нүхтэй %2" },
    { "^Requires (.+)$", "Шаардлага: %1" },
    { "^Classes: (.+)$", "Анги: %1" },
    { "^Races: (.+)$", "Омог: %1" },
    { "^(%d+) Mana$", "%1 Mana" },
    { "^(%d+) Rage$", "%1 Rage" },
    { "^(%d+) Energy$", "%1 Energy" },
    { "^(%d+) yd range$", "%1 м зай" },
    { "^([%d%.]+) sec cast$", "%1 сек ашиглалт" },
    { "^([%d%.]+) sec cooldown$", "%1 сек cooldown" },
    { "^([%d%.]+) min cooldown$", "%1 мин cooldown" },
    { "^Rank (%d+)$", "Зэрэг %1" },
    { "^Level (%d+)$", "Түвшин %1" },
    { "^Speed (.+)$", "Хурд %1" },
}

local function Translate(text)
    if not text or text == "" then return nil end
    local ex = EXACT[text]
    if ex then return ex end
    for _, p in ipairs(PATTERNS) do
        if text:find(p[1]) then
            local out = text:gsub(p[1], p[2])
            return out
        end
    end
    return nil
end

local function Process(tip)
    if not MongolWoW.IsActive("tooltips") then return end
    local name = tip:GetName()
    if not name then return end
    for i = 2, tip:NumLines() do -- 1-р мөр нь нэр: орчуулахгүй
        for _, side in ipairs({ "Left", "Right" }) do
            local fs = _G[name .. "Text" .. side .. i]
            if fs then
                local tr = Translate(fs:GetText())
                if tr then
                    fs:SetText(tr)
                    local _, size, flags = fs:GetFont()
                    fs:SetFont(FONT, size or 12, flags)
                end
            end
        end
    end
end

local function HookTip(tip)
    if not tip or not tip.HookScript then return end
    tip:HookScript("OnTooltipSetItem", Process)
    tip:HookScript("OnTooltipSetSpell", Process)
end

HookTip(GameTooltip)
HookTip(ItemRefTooltip)
HookTip(ShoppingTooltip1)
HookTip(ShoppingTooltip2)
