#!/usr/bin/env python3
"""MongolWoW quest өгөгдлийн tool (тоглоомд ачаалагддаггүй).

  import  - questcache.wdb болон SavedVariables-ээс англи текст цуглуулж
            pending.json (орчуулах), хараахан орчуулагдаагүйг гаргана
  build   - quests_mn.json -> ../Data/Quests_mn.lua
  merge_id <chunk.json> - ID-тай орчуулсан chunk-ийг нэгтгэнэ (давхардсан нэрийг v=[...]-ээр ялгана)

quests_mn.json:  { "English title": {"t": "...", "d": "...", "o": "...", "p": "...", "c": "..."} }
pending.json  :  { "English title": {"d": "...", "o": "..."} }  (orchuulgagui)
"""
import glob
import json
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
WDB = os.path.join(GAME, "Cache", "WDB", "enUS", "questcache.wdb")
TRANSLATED = os.path.join(HERE, "quests_mn.json")
PENDING = os.path.join(HERE, "pending.json")
LUA_OUT = os.path.join(HERE, "..", "Data", "Quests_mn.lua")


# ---------------- questcache.wdb ----------------
def _cstr(buf, pos):
    end = buf.index(b"\0", pos)
    return buf[pos:end].decode("utf-8", "replace"), end + 1


def parse_wdb(path):
    """3.3.5a (12340) questcache.wdb: 24 байт header, дараа нь [entry, size, data]...
    data[260:] дээр title, objectives, details, endText мөрүүд эхэлнэ."""
    data = open(path, "rb").read()
    pos = 24
    out = {}
    while pos + 8 <= len(data):
        entry, size = struct.unpack_from("<II", data, pos)
        pos += 8
        if (entry == 0 and size == 0) or pos + size > len(data):
            break
        rec = data[pos:pos + size]
        pos += size
        if len(rec) <= STRINGS_OFFSET:
            continue
        try:
            t, p = _cstr(rec, STRINGS_OFFSET)
            o, p = _cstr(rec, p)
            d, p = _cstr(rec, p)
        except ValueError:
            continue
        if t:
            out[entry] = {"t": t, "o": o, "d": d}
    return out


STRINGS_OFFSET = 260


# ---------------- SavedVariables (Lua) ----------------
def parse_lua_table(text):
    """MongolWoWDB = {...} хэлбэрийн WoW SavedVariables хялбар задлагч."""
    pos = text.index("{")
    tok = re.compile(r'\s*(?:--[^\n]*\n\s*)*')

    def skip(p):
        return tok.match(text, p).end()

    def value(p):
        p = skip(p)
        c = text[p]
        if c == "{":
            return table(p)
        if c == '"':
            return string(p)
        m = re.compile(r"-?\d+(?:\.\d+)?|true|false|nil").match(text, p)
        v = m.group(0)
        if v == "true":
            return True, m.end()
        if v == "false":
            return False, m.end()
        if v == "nil":
            return None, m.end()
        return (float(v) if "." in v else int(v)), m.end()

    def string(p):
        p += 1
        buf = []
        while text[p] != '"':
            if text[p] == "\\":
                p += 1
                esc = text[p]
                buf.append({"n": "\n", "t": "\t", "r": "\r"}.get(esc, esc))
            else:
                buf.append(text[p])
            p += 1
        return "".join(buf), p + 1

    def table(p):
        p += 1
        result = {}
        arr = []
        while True:
            p = skip(p)
            if text[p] == "}":
                return (result if result or not arr else arr), p + 1
            if text[p] == "[":
                p += 1
                k, p = value(p)
                p = skip(p)
                assert text[p] == "]"
                p = skip(p + 1)
                assert text[p] == "="
                v, p = value(p + 1)
                result[k] = v
            else:
                v, p = value(p)
                arr.append(v)
            p = skip(p)
            if text[p] in ",;":
                p += 1

    v, _ = table(pos)
    return v


def read_saved_captured():
    found = {}
    pattern = os.path.join(GAME, "WTF", "Account", "*", "SavedVariables", "MongolWoW.lua")
    for path in glob.glob(pattern):
        try:
            db = parse_lua_table(open(path, encoding="utf-8").read())
        except Exception as e:  # noqa: BLE001
            print("SavedVariables задлах алдаа:", path, e)
            continue
        for title, rec in (db.get("captured") or {}).items():
            if isinstance(rec, dict):
                found.setdefault(title, {}).update(rec)
    return found


# ---------------- JSON/Lua ----------------
def load_json(path):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_json(path, obj):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1, sort_keys=True)


def lua_str(s):
    return '"' + (s.replace("\\", "\\\\").replace('"', '\\"')
                  .replace("\r", "").replace("\n", "\\n")) + '"'


def cmd_import():
    translated = load_json(TRANSLATED)
    pending = {}
    if os.path.exists(WDB):
        for entry, q in parse_wdb(WDB).items():
            title = q["t"]
            if title in translated:
                continue
            rec = pending.setdefault(title, {})
            if q["d"]:
                rec["d"] = q["d"]
            if q["o"]:
                rec["o"] = q["o"]
            rec["id"] = entry
        print(f"questcache.wdb: {len(pending)} quest")
    for title, rec in read_saved_captured().items():
        if title in translated:
            continue
        p = pending.setdefault(title, {})
        for k, v in rec.items():
            p.setdefault(k, v)
    save_json(PENDING, pending)
    print(f"pending.json: {len(pending)} quest орчуулахыг хүлээж байна")


def cmd_build():
    translated = load_json(TRANSLATED)
    lines = [
        "-- ЭНЭ ФАЙЛ АВТОМАТААР ҮҮСДЭГ: Tools/quests_tool.py build",
        "-- Засахдаа Tools/quests_mn.json-г засаад дахин build хий.",
        "MongolWoW_Quests = MongolWoW_Quests or {}",
        "local Q = MongolWoW_Quests",
    ]
    def fmt(rec, extra=()):
        keys = tuple(extra) + ("t", "d", "o", "p", "c")
        return ", ".join(f"{k}={lua_str(rec[k])}" for k in keys if rec.get(k))

    for title in sorted(translated):
        rec = translated[title]
        if rec.get("v"):  # давхардсан нэр: хувилбарууд (k = англи зорилгын түлхүүр)
            parts = [f"{{ {fmt(v, ('k',))} }}" for v in rec["v"]]
            head = fmt(rec)
            head = head + ", " if head else ""
            lines.append(f"Q[{lua_str(title)}] = {{ {head}v = {{ {', '.join(parts)} }} }}")
        else:
            lines.append(f"Q[{lua_str(title)}] = {{ {fmt(rec)} }}")
    with open(LUA_OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"{len(translated)} quest -> {os.path.normpath(LUA_OUT)}")


def cmd_merge(path):
    """batch JSON-г quests_mn.json-д нэгтгээд build + import хийнэ."""
    translated = load_json(TRANSLATED)
    batch = load_json(path)
    translated.update(batch)
    save_json(TRANSLATED, translated)
    print(f"{len(batch)} quest нэмэгдэв, нийт {len(translated)}")
    cmd_build()
    cmd_import()


KEYLEN = 40  # Quests.lua-н KEYLEN-тэй ижил байх ёстой


def make_key(q):
    """Англи зорилго (байхгүй бол тайлбар)-оос түлхүүр: '$' хүртэлх хэсэг, үсэг/тоо, жижиг, 40 тэмдэгт."""
    text = q.get("obj") or q.get("desc") or ""
    text = text.split("$")[0]
    return re.sub(r"[^0-9a-z]", "", text.lower())[:KEYLEN]


def cmd_merge_id(path):
    """ID-тай орчуулсан chunk ([{id,t,o,d,p,c}]) -> quests_mn.json.
    Нэр өвөрмөц бол энгийн бичлэг, давхардсан бол v=[{k,...}] хувилбар болгоно."""
    src = load_json(os.path.join(HERE, "acore_quests_en.json"))
    cnt = {}
    for q in src.values():
        cnt[q["title"]] = cnt.get(q["title"], 0) + 1
    translated = load_json(TRANSLATED)
    batch = load_json(path)
    added = warn = 0
    for item in batch:
        en = src.get(str(item["id"]))
        if not en:
            print("ID олдсонгүй:", item["id"])
            continue
        title = en["title"]
        rec = {k: item[k] for k in ("t", "d", "o", "p", "c") if item.get(k)}
        if cnt[title] == 1:
            translated[title] = rec
        else:
            cur = translated.get(title)
            if not isinstance(cur, dict) or "v" not in cur:
                cur = {"v": [], **({k: cur[k] for k in cur} if cur else {})}
                cur["v"] = []
            rec["k"] = make_key(en)
            if not rec["k"]:
                warn += 1
            cur["v"] = [v for v in cur["v"] if v.get("k") != rec["k"]] + [rec]
            translated[title] = cur
        added += 1
    save_json(TRANSLATED, translated)
    print(f"{added} quest нэмэгдэв ({warn} хоосон түлхүүр), нийт {len(translated)} нэр")
    cmd_build()


def cmd_next(count):
    """pending.json-оос хамгийн богино `count` quest-ийг хэвлэнэ."""
    pending = load_json(PENDING)
    useful = {k: v for k, v in pending.items()
              if (v.get("d") or v.get("o")) and "temp text" not in (v.get("d", "") + v.get("o", ""))}
    items = sorted(useful.items(), key=lambda kv: len(kv[1].get("d", "")) + len(kv[1].get("o", "")))
    for title, rec in items[:count]:
        print("##", title)
        if rec.get("o"):
            print("o:", rec["o"])
        if rec.get("d"):
            print("d:", rec["d"])
        print()
    print(f"-- pending: {len(useful)}")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "merge" and len(sys.argv) > 2:
        cmd_merge(sys.argv[2])
    elif cmd == "merge_id" and len(sys.argv) > 2:
        cmd_merge_id(sys.argv[2])
    elif cmd == "next":
        cmd_next(int(sys.argv[2]) if len(sys.argv) > 2 else 20)
    elif cmd == "import":
        cmd_import()
    elif cmd == "build":
        cmd_build()
    else:
        print(__doc__)
