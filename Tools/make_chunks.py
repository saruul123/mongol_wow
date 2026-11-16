import json, os, sys
S = sys.argv[1]
T = "/home/saruul/Pictures/World of Warcraft 3.3.5a/Interface/AddOns/MongolWoW/Tools"
src = json.load(open(T + "/acore_quests_en.json", encoding="utf-8"))
translated = set(json.load(open(T + "/quests_mn.json", encoding="utf-8")).keys())
cnt = {}
for q in src.values():
    cnt[q["title"]] = cnt.get(q["title"], 0) + 1
items = []
for qid in sorted(src, key=int):
    q = src[qid]
    if not q["title"]:
        continue
    if q["title"] in translated and cnt[q["title"]] == 1:
        continue
    if not (q["obj"] or q["desc"] or q["progress"] or q["reward"]):
        continue
    items.append({"id": int(qid), "t": q["title"], "o": q["obj"], "d": q["desc"], "p": q["progress"], "c": q["reward"]})
N = 120
n = 0
for i in range(0, len(items), N):
    n += 1
    json.dump(items[i:i + N], open(os.path.join(S, "chunks", "chunk_%03d.json" % n), "w", encoding="utf-8"), ensure_ascii=False)
print("quests", len(items), "chunks", n)
