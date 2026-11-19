#!/usr/bin/env python3
"""NPC gossip орчуулгын хэрэгсэл.
  python3 -I gossip_tool.py extract <sqldir>  -> gossip_en.json  (Horde, quest-ийн түвшин <=20 NPC-үүдийн gossip текст + сонголт)
  python3 -I gossip_tool.py build             -> ../Data/Gossip_mn.lua   (gossip_mn.json-оос)
sqldir: quest_template, creature_queststarter, creature_template, gossip_menu, gossip_menu_option, npc_text .sql (AzerothCore db_world base)."""
import json, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from sqlload import load

H = 2 | 16 | 32 | 128 | 512
A = 1 | 4 | 8 | 64 | 1024
HZ = {14, 215, 85, 1637, 1638, 1497, 3487, 3430, 3433, 17, 130}
MAXLVL = 20


def extract(D):
    L = lambda n: load(os.path.join(D, n + ".sql"), n)
    quests = {}
    for r in L("quest_template"):
        quests[r["ID"]] = (int(r["AllowableRaces"]), int(r["QuestSortID"]), int(r["MinLevel"]))
    hq = {i for i, (r, z, l) in quests.items()
          if ((r and r & H and not r & A) or (r == 0 and z in HZ)) and l <= MAXLVL}
    npcs = {r["id"] for r in L("creature_queststarter") if r["quest"] in hq}
    ct = {r["entry"]: r for r in L("creature_template")}
    menus = {ct[n]["gossip_menu_id"] for n in npcs if n in ct and ct[n]["gossip_menu_id"] not in (None, "0")}
    tids = {r["TextID"] for r in L("gossip_menu") if r["MenuID"] in menus}
    nt = {r["ID"]: r for r in L("npc_text")}
    texts, opts = [], []
    seen = set()
    for t in sorted(tids, key=int):
        r = nt.get(t)
        if not r:
            continue
        for i in range(8):
            for g in (0, 1):
                s = r.get("text%d_%d" % (i, g))
                if s and s not in seen:
                    seen.add(s)
                    texts.append(s)
    oseen = set()
    for r in L("gossip_menu_option"):
        if r["MenuID"] in menus and r["OptionText"] and r["OptionText"] not in oseen:
            oseen.add(r["OptionText"])
            opts.append(r["OptionText"])
    items = [{"id": i, "k": "t", "e": s} for i, s in enumerate(texts)]
    items += [{"id": len(texts) + i, "k": "o", "e": s} for i, s in enumerate(opts)]
    json.dump(items, open(os.path.join(HERE, "gossip_en.json"), "w", encoding="utf-8"), ensure_ascii=False)
    print("texts", len(texts), "options", len(opts), "chars", sum(len(x["e"]) for x in items))


def clean(s):
    """Placeholder-уудыг хасаж, үсэг/тооноос бүрдэх жижиг үсгийн текст."""
    s = re.sub(r"\$[gG][^;]*;", "", s)
    s = re.sub(r"\$[A-Za-z]", "", s)
    return re.sub(r"[^0-9a-z]", "", s.lower())


def lq(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "") + '"'


def build():
    en = json.load(open(os.path.join(HERE, "gossip_en.json"), encoding="utf-8"))
    mn = json.load(open(os.path.join(HERE, "gossip_mn.json"), encoding="utf-8"))
    by = {o["id"]: o["m"] for o in mn}
    out = ["-- ЭНЭ ФАЙЛ АВТОМАТААР ҮҮСДЭГ: Tools/gossip_tool.py build",
           "MongolWoW_Gossip = { texts = {}, opts = {} }",
           "local G = MongolWoW_Gossip"]
    nt = no = 0
    for it in en:
        m = by.get(it["id"])
        if not m:
            continue
        if it["k"] == "t":
            e = it["e"]
            pre = clean(re.split(r"\$", e, 1)[0])[:40]
            suf = clean(re.split(r"\$[A-Za-z]|\$[gG][^;]*;", e)[-1])[-20:]
            out.append("G.texts[#G.texts+1] = { p=%s, s=%s, t=%s }" % (lq(pre), lq(suf), lq(m)))
            nt += 1
        else:
            out.append("G.opts[%s] = %s" % (lq(it["e"]), lq(m)))
            no += 1
    open(os.path.join(HERE, "..", "Data", "Gossip_mn.lua"), "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("texts", nt, "options", no)


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "extract":
        extract(sys.argv[2])
    elif len(sys.argv) > 1 and sys.argv[1] == "build":
        build()
    else:
        print(__doc__)
