local L = MongolWoW_L

-- Interface Options -> AddOns -> MongolWoW самбар
local panel = CreateFrame("Frame", "MongolWoWOptionsPanel", UIParent)
panel.name = "MongolWoW"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetFont(MongolWoW.FONT_BOLD, 18)
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("MongolWoW")

local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
sub:SetFont(MongolWoW.FONT, 12)
sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
sub:SetText(L["opt_desc"])

local boxes = {}

local function MakeCheck(key, label, tip, anchor, yOff, indent)
    local cb = CreateFrame("CheckButton", "MongolWoWCheck_" .. key, panel, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", indent or 0, yOff or -8)
    local text = _G[cb:GetName() .. "Text"]
    text:SetFont(MongolWoW.FONT, 13)
    text:SetText(label)
    cb.tooltipText = tip
    cb.key = key
    cb:SetScript("OnClick", function(self)
        local on = self:GetChecked() and true or false
        MongolWoWDB[key] = on
        if key == "enabled" then
            MongolWoW.enabled = on
            MongolWoW.Print(on and L["enabled"] or L["disabled"])
            panel.refresh()
        end
    end)
    cb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label, 1, 1, 1)
        GameTooltip:AddLine(tip, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    boxes[#boxes + 1] = cb
    return cb
end

local cbMain    = MakeCheck("enabled",  L["opt_enabled"],  L["opt_enabled_tip"],  sub,    -16)
local cbUI      = MakeCheck("ui",       L["opt_ui"],       L["opt_ui_tip"],       cbMain, -8, 20)
local cbQuests  = MakeCheck("quests",   L["opt_quests"],   L["opt_quests_tip"],   cbUI, -4)
local cbTips    = MakeCheck("tooltips", L["opt_tooltips"], L["opt_tooltips_tip"], cbQuests, -4)
local cbChat    = MakeCheck("chat",     L["opt_chat"],     L["opt_chat_tip"],     cbTips,  -4)

-- Үндсэн сонголт унтарвал дэд сонголтууд саарал болно
function panel.refresh()
    local main = MongolWoWDB and MongolWoWDB.enabled
    for _, cb in ipairs(boxes) do
        cb:SetChecked(MongolWoWDB and MongolWoWDB[cb.key])
        if cb.key ~= "enabled" then
            if main then cb:Enable() else cb:Disable() end
        end
    end
end

panel.okay = function() end
panel.cancel = function() end
panel.default = function()
    for k, v in pairs(MongolWoW.DEFAULTS) do MongolWoWDB[k] = v end
    MongolWoW.enabled = MongolWoWDB.enabled
    panel.refresh()
end

InterfaceOptions_AddCategory(panel)
MongolWoW.optionsPanel = panel

-- Slash: /mn config
function MongolWoW.OpenOptions()
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel) -- 3.3.5 bug: эхний дуудалт зөв таб руу очдоггүй
end
