#!/usr/bin/env python3
"""python3 -I validate_chunk.py <chunk_in.json> <chunk_out.json> : орчуулгын шалгалт"""
import json, re, sys
src = json.load(open(sys.argv[1], encoding="utf-8"))
try:
    out = json.load(open(sys.argv[2], encoding="utf-8"))
except Exception as e:
    print("JSON ALDAA:", e); sys.exit(1)
by = {o["id"]: o for o in out}
PH = re.compile(r"\$[A-Za-z]|\$[gG][^;]*;")
LAT = re.compile(r"[A-Za-z]"); CYR = re.compile(r"[А-Яа-яӨөҮүЁё]")
bad = 0
import os
GL = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "glossary.json"), encoding="utf-8"))["tr"]
LEFT = [w for w in GL if " " not in w and w not in ("keep","hold","quest","kill","gold","silver","copper","mage")]
def report(qid, msg):
    global bad; bad += 1; print("id %s: %s" % (qid, msg))
for q in src:
    o = by.get(q["id"])
    if o is None:
        report(q["id"], "ХАСАГДСАН"); continue
    for k in ("t", "o", "d", "p", "c"):
        en = q[k]; mn = o.get(k, "") or ""
        if sorted(PH.findall(en)) != sorted(PH.findall(mn)):
            report(q["id"], "%s: placeholder зөрсөн %s -> %s" % (k, PH.findall(en), PH.findall(mn)))
        if en.strip() and not mn.strip():
            report(q["id"], "%s: хоосон" % k)
        if not en.strip() and mn.strip():
            report(q["id"], "%s: эх хоосон байхад орчуулга бий" % k)
        if en and mn and not (0.35 < len(mn) / max(len(en), 1) < 2.8):
            report(q["id"], "%s: урт эргэлзээтэй (%d -> %d)" % (k, len(en), len(mn)))
        if en.strip() and not CYR.search(mn) and len(en) > 25:
            report(q["id"], "%s: кирилл алга (орчуулаагүй?)" % k)
        for w in re.findall(r"[A-Za-zА-Яа-яӨөҮүЁё]+", PH.sub(" ", mn)):
            if LAT.search(w) and CYR.search(w):
                report(q["id"], "%s: латин/кирилл холилдсон үг '%s'" % (k, w))
        for w in re.findall(r"[a-z]+", PH.sub(" ", mn)):
            if w in LEFT and not re.search(r"[A-Z][a-z]*\W+" + w, mn, re.I):
                report(q["id"], "%s: нийтлэг үг орчуулаагүй '%s' -> %s" % (k, w, GL[w]))
print("ДУУСЛАА: %d quest, алдаа %d" % (len(src), bad))
sys.exit(1 if bad else 0)
