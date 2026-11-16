-- Chat туслах: LFM, gg, ty зэрэг товчлолын тайлбарыг мессежийн ард хаалтаар нэмнэ.
local GLOSS = {
    lfm = "групп хайж байна", lfg = "групп хайж байна (тоглогч)", lf = "хайж байна",
    gg = "сайхан тоглолоо", ty = "баярлалаа", thx = "баярлалаа", tyvm = "маш их баярлалаа",
    np = "зүгээр", brb = "одоохон ирнэ", afk = "компьютерээс холдсон", wtb = "авна",
    wts = "зарна", inv = "урь", pls = "гуйя", plz = "гуйя", omw = "замдаа явж байна",
    ninja = "хулгайлах", dps = "хохирол үүсгэгч", tank = "хамгаалагч", heal = "эмчлэгч",
    lol = "инээдтэй", gl = "амжилт", hf = "сайхан тоглоорой", wp = "сайн ажиллалаа",
    rdy = "бэлэн", ready = "бэлэн", sry = "уучлаарай", brt = "удахгүй буцна",
}

local CHANNELS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_GUILD", "CHAT_MSG_CHANNEL",
    "CHAT_MSG_WHISPER",
}

local function Filter(self, event, msg, ...)
    if not MongolWoW.IsActive("chat") or type(msg) ~= "string" then return false end
    local seen, notes = {}, {}
    for word in msg:lower():gmatch("%a+") do
        local g = GLOSS[word]
        if g and not seen[word] then
            seen[word] = true
            notes[#notes + 1] = word .. " = " .. g
        end
    end
    if #notes == 0 then return false end
    return false, msg .. " |cff888888(" .. table.concat(notes, "; ") .. ")|r", ...
end

for _, ev in ipairs(CHANNELS) do ChatFrame_AddMessageEventFilter(ev, Filter) end
