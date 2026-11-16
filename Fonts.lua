local ADDON_PATH = "Interface\\AddOns\\MongolWoW\\Fonts\\"
MongolWoW.FONT = ADDON_PATH .. "MnSans.ttf"
MongolWoW.FONT_BOLD = ADDON_PATH .. "MnSans-Bold.ttf"

-- Ө/Ү-тэй кирилл фонттой Font объектууд (бусад модуль ашиглана)
local fontNormal = CreateFont("MongolWoWFont")
fontNormal:SetFont(MongolWoW.FONT, 13)
local fontBold = CreateFont("MongolWoWFontBold")
fontBold:SetFont(MongolWoW.FONT_BOLD, 14)

-- /mn fonttest: тусдаа жижиг цонхонд Ө/Ү харуулна
local testFrame
function MongolWoW.FontTest()
    if not testFrame then
        testFrame = CreateFrame("Frame", "MongolWoWFontTest", UIParent)
        testFrame:SetSize(420, 70)
        testFrame:SetPoint("CENTER")
        testFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        testFrame:EnableMouse(true)
        testFrame:SetScript("OnMouseDown", function(self) self:Hide() end)
        local fs = testFrame:CreateFontString(nil, "OVERLAY")
        fs:SetFont(MongolWoW.FONT, 15)
        fs:SetPoint("CENTER")
        fs:SetText(MongolWoW.L["fonttest"])
        testFrame.text = fs
    end
    testFrame:Show()
end
