#!/usr/bin/env python3
import json, os, re
H = os.path.dirname(os.path.abspath(__file__))
en = json.load(open(os.path.join(H, "gossip_en.json"), encoding="utf-8"))
try:
    mn = {o["id"]: o["m"] for o in json.load(open(os.path.join(H, "gossip_mn.json"), encoding="utf-8"))}
except Exception as e:
    print("JSON ALDAA:", e); raise SystemExit(1)
PH = re.compile(r"\$[A-Za-z]|\$[gG][^;]*;")
CYR = re.compile(r"[А-Яа-яӨөҮүЁё]")
bad = 0
for it in en:
    m = mn.get(it["id"])
    if not m or not m.strip():
        print("id", it["id"], "хоосон/хасагдсан"); bad += 1; continue
    if sorted(PH.findall(it["e"])) != sorted(PH.findall(m)):
        print("id", it["id"], "placeholder зөрсөн", PH.findall(it["e"]), PH.findall(m)); bad += 1
    if len(it["e"]) > 25 and not CYR.search(m):
        print("id", it["id"], "кирилл алга"); bad += 1
print("ДУУСЛАА:", len(en), "мөр, алдаа", bad)
