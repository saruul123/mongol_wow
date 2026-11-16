# MongolWoW — WoW 3.3.5a Монгол орчуулгын addon

Энэ фолдер нь WoW 3.3.5a (enUS клиент, Warmane realm `logon.warmane.com`) суулгац. Энд **MongolWoW** addon-ыг хөгжүүлж байна: quest, UI цэс, tooltip-ийг Монгол хэл рүү орчуулна.
Хэрэглэгч Монголоор ярьдаг (латин үсгээр бичдэг, жишээ нь "urgeljluul"). Хариултаа Монголоор, товч, шууд бич.

## Хамгийн чухал: 4 хуулбар бий, зөвхөн нэг нь тоглогддог
| Зам | Статус |
|---|---|
| `~/Pictures/World of Warcraft 3.3.5a` (энэ фолдер) | **Эх сурвалж (source of truth)**, энд засна. `Interface/AddOns/MongolWoW/` нь `.git`-тэй |
| `~/.PlayOnLinux/wineprefix/WoW-backup/drive_c/Program Files/World of Warcraft 3.3.5a` | **Хэрэглэгчийн жинхэнэ тоглодог суулгац.** Терминалд `tenx` гэж бичиж эхлүүлдэг (`~/.zshrc` дахь функц: `WINEPREFIX=~/.PlayOnLinux/wineprefix/WoW wine ".../WoW-backup/.../Wow.exe"`) |
| `/media/saruul/DATA/World of Warcraft 3.3.5a` | Өөр хуулбар (NTFS), addon хуулсан ч хэрэглэгч тоглодоггүй бололтой |
| PlayOnLinux "Wow" shortcut | Эвдэрсэн (заасан зам байхгүй), ашиглагдахгүй |

**Засвар хийсний дараа ЗААВАЛ жинхэнэ суулгац руу синхрончил** (тоглоом тэндээс addon-ыг уншдаг). `.git`-ийг оруулахгүй:
```
SRC="$HOME/Pictures/World of Warcraft 3.3.5a/Interface/AddOns/MongolWoW"
DST="$HOME/.PlayOnLinux/wineprefix/WoW-backup/drive_c/Program Files/World of Warcraft 3.3.5a/Interface/AddOns/MongolWoW"
mkdir -p "$DST" && (cd "$SRC" && tar --exclude=.git --exclude=Tools/pending.json --exclude=Tools/acore_quests_en.json --exclude=Tools/agent_out -cf - .) | (cd "$DST" && tar -xf -)
```
(`Tools/` дахь том JSON-уудыг тоглоомын фолдерт хуулах шаардлагагүй.) Санал болгосон боловч хийгээгүй: `WoW-backup` дахь `MongolWoW`-ыг эх сурвалж руу symlink болгох.
Тоглоомыг ажиллаж байх үед addon-ыг солихгүй: хаагаад дахин `tenx`-ээр эхлүүлнэ. Addon-ы жагсаалт character select-ийн зүүн доод **AddOns** товчоор харагдана.

## Addon-ы бүтэц (`Interface/AddOns/MongolWoW/`)
- `MongolWoW.toc`: `Interface: 30300`, `SavedVariables: MongolWoWDB`. Файлын дараалал: `Locale\mnMN.lua`, `Locale\ui_mn.lua`, `Locale\ui_mn2.lua`, `Core.lua`, `Fonts.lua`, `UI.lua`, `Data\Quests_mn.lua`, `Quests.lua`, `Options.lua`.
- `Core.lua`: init, `MongolWoW.DEFAULTS`, `MongolWoW.IsActive(module)`, `/mn` (on|off|fonttest|config|quests).
- `Fonts.lua` + `Fonts/MnSans*.ttf`: Noto Sans (OFL). **enUS клиентийн стандарт фонт Ө/Ү-г харуулдаггүй** тул кирилл бүхий фонт заавал хэрэгтэй.
- `UI.lua`: Blizzard UI орчуулга. Font объектуудыг фонтоор солино, одоо байгаа FontString/Button-ыг нэг удаа sweep хийнэ, `SetText`-ийг hook хийнэ. Tooltip доторх мөрийг орчуулахгүй (зориуд). Толь бичиг: `Locale/ui_mn.lua` (~150) + `ui_mn2.lua` (~290) + pattern-ууд (`MongolWoW_UIPatterns`).
- `Quests.lua`: NPC quest цонх (detail/progress/reward) болон quest log-ыг орчуулна. Түлхүүр нь **англи нэр (title)**; орчуулга олдохгүй бол англи текстийг `MongolWoWDB.captured`-д цуглуулна. Fields: `t` нэр, `d` тайлбар, `o` зорилго, `p` progress, `c` reward. `$N $C $R $B $g..;` placeholder-ыг `Expand()` задалдаг.
- `Options.lua`: Esc → Interface → AddOns → MongolWoW самбар (идэвхжүүлэх, UI, quest, tooltip, chat checkbox).
- `Data/Quests_mn.lua`: **автоматаар үүсдэг**, гараар бүү засна.
- `Tools/` (тоглоомд ачаалагддаггүй): `quests_tool.py` (import/build/merge/next), `quests_mn.json` (орчуулгын эх), `acore_quests_en.json` (AzerothCore-ийн 9464 quest-ийн англи эх), `parse_acore_sql.py`, `translate_api.py` (Claude API-аар, түлхүүр хэрэгтэй), `make_chunks.py`, `validate_chunk.py`, `merge_parts.py`, `agent_out/`.

## Quest орчуулгын ажлын урсгал
- `python3 -I Tools/quests_tool.py import`: клиентийн `Cache/WDB/enUS/questcache.wdb` (24 байт header, record `[entry,size,data]`, string-үүд `data[260:]` дээр: title, objectives, details) болон SavedVariables-ийн captured-аас `Tools/pending.json` гаргана.
- `quests_tool.py next 30`: хамгийн богино 30 pending-ийг хэвлэнэ → орчуулж JSON болгоод `quests_tool.py merge <файл>` (quests_mn.json-д нэмж `Data/Quests_mn.lua` build хийнэ).
- Дүрэм: `$N $n $C $c $R $r $B $b` болон `$g<эр>:<эм>;` placeholder-ыг ЯГ хэвээр; NPC/газар/эд зүйл/ур чадвар/фракцын нэр (Horde, Alliance, Scourge, Forsaken...) англиар; Монгол нөхцөл нэмэхдээ зураасаар (`Orgrimmar-т`, `Horde-ийн`), латин-кирилл холихгүй; `<NPC үйлдэл>`-ийн хаалт хадгална; `даалгавар`=quest, `ал`=kill, `шагнал`=reward.
- Орчуулгын validator: `Tools/validate_chunk.py` (placeholder тоо, хоосон, урт, холилдсон үг). `merge_parts.py NNN` нь agent-ын хэсгүүдийг нэгтгэж зай цэвэрлээд validate хийнэ (scratchpad-н замтай).

## Одоогийн төлөв (2026-11-16)
- **Addon-д орсон:** 371 quest (клиентийн cache-ээс, гараар орчуулсан). `Data/Quests_mn.lua` ≈ 330 KB.
- **chunk 001-003 орчуулга УСТСАН** (`make_chunks.py` agent_out дээр дахин ажиллаж англи эхээр дарсан; одоо бүх chunk англи). Дахин орчуулах хэрэгтэй. Орчуулсан chunk-ийг `python3 -I Tools/quests_tool.py merge_id <chunk.json>`-оор оруулна (формат `[{id,t,o,d,p,c}]`, давхардсан нэрийг автоматаар `v=[{k,...}]` хувилбар болгоно). `make_chunks.py`-ийг agent_out-д БҮҮ ажиллуул.
- **Quests.lua** давхардсан нэртэй quest-ийг англи зорилго/тайлбарын эхний 40 тэмдэгтийн түлхүүрээр (`Pick`) ялгана (2026-11-16 хийгдсэн, тоглоомд туршаагүй).
- **Үлдсэн:** ~8400 quest (нийт 9464). Англи эх `Tools/acore_quests_en.json`. 74 chunk x 120 quest (`chunk_001..074`); `Tools/agent_out/chunk_NNN.json` нь эх англи chunk-ууд, орчуулсан 001-003-ыг нэг нэрээр бичсэн болохыг анхаар (001-003 нь орчуулсан хувилбар). `make_chunks.py` дахин үүсгэнэ.
- chunk 004-015-д ажиллаж байсан agent-ууд хэрэглэгчийн хүсэлтээр зогссон, үр дүн хадгалагдаагүй (дахин хийх хэрэгтэй).
- Эх сурвалж: `https://raw.githubusercontent.com/azerothcore/azerothcore-wotlk/master/data/sql/base/db_world/{quest_template,quest_offer_reward,quest_request_items}.sql`; `parse_acore_sql.py` задалдаг.

## Хийгдээгүй / дараагийн ажил (ач холбогдлоор)
1. **(хагас хийгдсэн: давхардал шийдэгдсэн, lazy-load үлдсэн)** Шинэ орчуулгыг addon-д оруулах: нэр давхардал (7054 өвөрмөц нэр / 9464 quest, 1041 нэр давхардсан) тул `Quests.lua`-г нэр + англи зорилгын текстээр ялгадаг болгох. Progress/Reward (`p`, `c`) аль хэдийн дэмжигддэг ч NPC цонхонд ID байхгүй. Quest log-ийн `GetQuestLogTitle`-ийн 9 дэх утга questID. Хэмжээ ~10-15 MB болох тул бүсээр хувааж lazy-load хийх.
2. **Үлдсэн ~8400 quest-ийг орчуулах**: (a) `ANTHROPIC_API_KEY`-тай бол `translate_api.py` (`--dry-run`-аар зардал; ~1.8M оролт + 3-6M гаралт token), (b) эсвэл тусгай agent-ууд (agent бүр 120 quest ≈ 157k token, ≈ 11 мин; нийт ~11M token, хэрэглэгчийн хязгаарыг их зарцуулна). Эхлэхээс өмнө хэрэглэгчээс зөвшөөрөл ав. Гараар (энэ чатад) ~34 quest/давтамж.
3. **`Tooltips.lua`** (2026-11-16 бичсэн, туршаагүй): зөвхөн тогтмол мөр (Binds when picked up, Requires Level, slot/armor төрөл...) орчуулна; item/spell нэр, тайлбар англиар. Нэмэхдээ `EXACT`/`PATTERNS`.
4. **`Chat.lua`** (2026-11-16 бичсэн, туршаагүй): LFM/gg/ty... товчлолын тайлбарыг мессежийн ард нэмнэ (`GLOSS`).
5. Quest-ийн progress/reward/gossip/greeting цонх, quest log-ийн жагсаалт, quest tracker (WatchFrame) орчуулга.
6. UI толь бичиг: англи текстийн заримыг санан бичсэн тул жинхэнэ клиентийн текстэд таарахгүй байж болно. Хэрэглэгч "харагдахгүй байна" гэвэл яг текстийг нь авч толь бичигт нэм.

## Мэдэх ёстой технологийн хязгаарлалт
- Энэ машинд Lua compiler (luac/luajit) **байхгүй**: syntax-ийг гараар шалгана (хаалт, `end`). Бүх Lua тоглоомд туршигдаагүй, `/console scriptErrors 1`-ээр алдааг хэрэглэгчээс авна.
- Скрипт ажиллуулахдаа `python3 -I` (isolated), татсан файлыг тусдаа хоосон фолдерт.
- Scratchpad (`/tmp/claude-1000/...`) түр зуурын: чухал зүйлийг `Tools/`-д хадгал.
- Энэ фолдер (`~/Pictures/World of Warcraft 3.3.5a`) анхнаасаа read-only (`dr-xr-xr-x`) байсан; CLAUDE.md үүсгэхийн тулд `chmod u+w` хийгээд дараа нь `chmod u-w`-ээр буцаасан. `Interface/AddOns/` дотор бичиж болно.
- `MongolWoW/`-д `.git` болон `README.md` бий (хэрэглэгч эсвэл өөр хэрэгсэл үүсгэсэн, би биш). Remote: `github.com/saruul123/mongol_wow`. Хэрэглэгч хүсэхгүй бол commit/push хийхгүй.
- API түлхүүр, нууц зүйлийг чатад бүү асуу/бүү хадгал; хэрэглэгч өөрийн терминалд `export` хийнэ.
- Хоёр дахь, гурав дахь хуулбарыг (DATA, Pictures) устгахыг хэрэглэгч өөрөө шийднэ.

## Шалгах (тоглоомд)
1. `tenx` → character select → **AddOns** → "MongolWoW (Монгол)" тэмдэглэгдсэн эсэх.
2. Нэвтэрмэгц чатад "MongolWoW ачаалагдлаа"; `/mn fonttest` (Ө/Ү `?`-гүй), `/mn config`, `/mn quests`.
3. Esc цэс, `C`/`P`/`N` цонх Монгол хэлээр; орчуулсан quest ("Cutting Teeth", "Slay them all!") нээж текст тасарсан эсэхийг хар (scroll хэмжээ).
