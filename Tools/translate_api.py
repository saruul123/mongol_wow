#!/usr/bin/env python3
"""Бүх quest-ийг Claude API-аар Монгол хэл рүү орчуулах (addon-д ачаалагддаггүй tool).

Бэлтгэл:
  1) AzerothCore SQL-ээс задалсан JSON: Tools/acore_quests_en.json
     ({id: {title, obj, desc, progress, reward}})
  2) export ANTHROPIC_API_KEY=...      (dry-run-д хэрэггүй)

Ажиллуулах:
  python3 -I translate_api.py --dry-run             # хэмжээ, тооцоо харах (API дууддаггүй)
  python3 -I translate_api.py --limit 20            # эхний 20 quest-ээр туршиж үзэх
  python3 -I translate_api.py --model claude-haiku-5-5 --workers 4
  Тасарвал дахин ажиллуулахад үргэлжилнэ (Tools/api_done.json).

Үр дүн: Tools/api_done.json -> `quests_tool.py build-all` (дараа нь) Lua болгоно.
"""
import argparse
import json
import os
import re
import sys
import threading
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "acore_quests_en.json")
DONE = os.path.join(HERE, "api_done.json")
TRANSLATED = os.path.join(HERE, "quests_mn.json")

PLACEHOLDER = re.compile(r"\$[A-Za-z]|\$[gG][^;]*;")

SYSTEM = """Чи World of Warcraft (3.3.5a) quest текстийг Англиас Монгол хэл рүү орчуулагч.
Дүрэм:
- Монгол хэлээр (кирилл) природ, ойлгомжтой, тоглоомын өнгө аястай орчуулна.
- `$N $n $C $c $R $r $B $b` болон `$g<эр>:<эм>;` placeholder-уудыг ЯГ хэвээр нь үлдээ, өөрчилж, орчуулж болохгүй.
- NPC, газар, эд зүйл, ур чадвар, фракцын нэрсийг англиар нь үлдээнэ.
- Тоо, хаалт, `<...>` үйлдлийн тэмдэглэгээг (жишээ нь <Kaltunk инээв.>) хадгална, дотор нь орчуул.
- Нэр томьёо: Scourge, Horde, Alliance, Forsaken, Burning Legion = англиар;
  quest = даалгавар; hero = баатар; reward = шагнал; kill = ал.
- Хоосон талбарыг хоосон үлдээ.
Гаралт: ЗӨВХӨН JSON массив. Элемент бүр: {"id": <тоо>, "t": "...", "o": "...", "d": "...", "p": "...", "c": "..."}
 t=нэр, o=зорилго, d=тайлбар, p=progress текст, c=reward текст."""


def load(path, default):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return default


def pending_quests(src, done, translated_titles):
    items = []
    title_count = {}
    for q in src.values():
        title_count[q["title"]] = title_count.get(q["title"], 0) + 1
    for qid, q in src.items():
        if qid in done or not q["title"]:
            continue
        # Өмнө гараар орчуулсан давхардаагүй нэр -> алгасна
        if q["title"] in translated_titles and title_count[q["title"]] == 1:
            continue
        if not (q["obj"] or q["desc"] or q["progress"] or q["reward"]):
            continue
        items.append((qid, q))
    return items


def batches(items, max_chars):
    cur, size = [], 0
    for qid, q in items:
        n = sum(len(q[k]) for k in ("title", "obj", "desc", "progress", "reward")) + 80
        if cur and size + n > max_chars:
            yield cur
            cur, size = [], 0
        cur.append((qid, q))
        size += n
    if cur:
        yield cur


def call_api(key, model, batch):
    payload_in = [{"id": int(qid), "t": q["title"], "o": q["obj"], "d": q["desc"],
                   "p": q["progress"], "c": q["reward"]} for qid, q in batch]
    body = json.dumps({
        "model": model,
        "max_tokens": 16000,
        "system": SYSTEM,
        "messages": [{"role": "user", "content": json.dumps(payload_in, ensure_ascii=False)}],
    }).encode()
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages", data=body, method="POST",
        headers={"x-api-key": key, "anthropic-version": "2023-06-01",
                 "content-type": "application/json"})
    with urllib.request.urlopen(req, timeout=300) as r:
        data = json.load(r)
    text = "".join(b.get("text", "") for b in data["content"])
    text = text[text.index("["): text.rindex("]") + 1]
    return json.loads(text), payload_in


def check(src_item, out):
    """Placeholder тоо хадгалагдсан эсэх."""
    for k_en, k_mn in (("title", "t"), ("obj", "o"), ("desc", "d"), ("progress", "p"), ("reward", "c")):
        a = sorted(PLACEHOLDER.findall(src_item[k_en]))
        b = sorted(PLACEHOLDER.findall(out.get(k_mn, "") or ""))
        if a != b:
            return False
        if src_item[k_en] and not (out.get(k_mn) or "").strip():
            return False
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--model", default="claude-haiku-5-5")
    ap.add_argument("--workers", type=int, default=3)
    ap.add_argument("--batch-chars", type=int, default=12000)
    a = ap.parse_args()

    src = load(SRC, None)
    if not src:
        sys.exit("acore_quests_en.json олдсонгүй: %s" % SRC)
    done = load(DONE, {})
    translated_titles = set(load(TRANSLATED, {}).keys())
    items = pending_quests(src, done, translated_titles)
    if a.limit:
        items = items[:a.limit]
    chars = sum(sum(len(q[k]) for k in ("title", "obj", "desc", "progress", "reward")) for _, q in items)
    bl = list(batches(items, a.batch_chars))
    print("Орчуулах quest: %d | англи тэмдэгт: %d | багц: %d | аль хэдийн хийсэн: %d"
          % (len(items), chars, len(bl), len(done)))
    print("Ойролцоо token: оролт ~%dk, гаралт (Монгол, кирилл) ~%dk-%dk"
          % (chars // 3.5 // 1000, chars // 2 // 1000, chars // 1000))
    if a.dry_run:
        print("(dry-run: API дуудсангүй)")
        return

    key = os.environ.get("ANTHROPIC_API_KEY")
    if not key:
        sys.exit("ANTHROPIC_API_KEY тохируулаагүй байна.")

    lock = threading.Lock()
    failed = []

    def work(b):
        for attempt in range(3):
            try:
                out, _ = call_api(key, a.model, b)
                by_id = {str(o["id"]): o for o in out}
                good = {}
                for qid, q in b:
                    o = by_id.get(qid)
                    if o and check(q, o):
                        good[qid] = {k: o.get(k, "") for k in ("t", "o", "d", "p", "c")}
                with lock:
                    done.update(good)
                    with open(DONE, "w", encoding="utf-8") as f:
                        json.dump(done, f, ensure_ascii=False)
                miss = [qid for qid, _ in b if qid not in good]
                return len(good), miss
            except Exception as e:  # noqa: BLE001
                err = str(e)
                time.sleep(2 + attempt * 3)
        return 0, [qid for qid, _ in b] + ["ERR:" + err[:80]]

    ok = 0
    with ThreadPoolExecutor(max_workers=a.workers) as ex:
        futs = [ex.submit(work, b) for b in bl]
        for i, f in enumerate(as_completed(futs), 1):
            n, miss = f.result()
            ok += n
            failed += miss
            print("багц %d/%d  амжилттай %d  нийт %d  алдаатай %d" % (i, len(bl), n, ok, len(failed)))
    print("Дууслаа. Орчуулагдсан:", ok, "| дахин оролдох:", len(failed))


if __name__ == "__main__":
    main()
