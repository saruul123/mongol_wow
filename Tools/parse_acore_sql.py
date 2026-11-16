#!/usr/bin/env python3
"""AzerothCore quest SQL dump -> JSON {id: {title, obj, desc, progress, reward}}"""
import json
import os
import re
import sys

D = sys.argv[1]
OUT = sys.argv[2]


def columns(sql):
    m = re.search(r"CREATE TABLE `[^`]+` \((.*?)\) ENGINE", sql, re.S)
    cols = []
    for line in m.group(1).split("\n"):
        mm = re.match(r"\s*`([^`]+)`", line)
        if mm:
            cols.append(mm.group(1))
    return cols


def parse_values(s, pos):
    """Parse one '(v1,v2,...)' tuple starting at s[pos]=='('. Returns (list, newpos)."""
    assert s[pos] == "("
    pos += 1
    vals = []
    n = len(s)
    while True:
        c = s[pos]
        if c == "'":
            pos += 1
            buf = []
            while True:
                ch = s[pos]
                if ch == "\\":
                    nxt = s[pos + 1]
                    buf.append({"n": "\n", "r": "\r", "t": "\t", "0": "\0",
                                "Z": "\x1a"}.get(nxt, nxt))
                    pos += 2
                elif ch == "'":
                    if s[pos + 1] == "'":
                        buf.append("'")
                        pos += 2
                    else:
                        pos += 1
                        break
                else:
                    buf.append(ch)
                    pos += 1
            vals.append("".join(buf))
        else:
            end = pos
            while s[end] not in ",)":
                end += 1
            tok = s[pos:end].strip()
            vals.append(None if tok.upper() == "NULL" else tok)
            pos = end
        if s[pos] == ",":
            pos += 1
            continue
        if s[pos] == ")":
            return vals, pos + 1


def load_table(name):
    sql = open(os.path.join(D, name + ".sql"), encoding="utf-8", errors="replace").read()
    cols = columns(sql)
    rows = []
    for m in re.finditer(r"INSERT INTO `%s` VALUES\s*" % name, sql):
        pos = m.end()
        while True:
            vals, pos = parse_values(sql, pos)
            rows.append(dict(zip(cols, vals)))
            if sql[pos] == ",":
                pos += 1
                while sql[pos] in " \r\n\t":
                    pos += 1
                continue
            break
    return rows


tpl = load_table("quest_template")
offer = {r["ID"]: r["RewardText"] for r in load_table("quest_offer_reward")}
req = {r["ID"]: r["CompletionText"] for r in load_table("quest_request_items")}

out = {}
for r in tpl:
    qid = r["ID"]
    out[qid] = {
        "title": r.get("LogTitle") or "",
        "obj": r.get("LogDescription") or "",
        "desc": r.get("QuestDescription") or "",
        "progress": req.get(qid) or "",
        "reward": offer.get(qid) or "",
    }
json.dump(out, open(OUT, "w", encoding="utf-8"), ensure_ascii=False)
print("template columns sample:", [c for c in tpl[0].keys() if "Log" in c or "Desc" in c or "Text" in c])
print("quests:", len(out))
print("with title:", sum(1 for v in out.values() if v["title"]))
print("with desc/obj:", sum(1 for v in out.values() if v["desc"] or v["obj"]))
print("with progress:", sum(1 for v in out.values() if v["progress"]))
print("with reward:", sum(1 for v in out.values() if v["reward"]))
tot = sum(len(v["title"]) + len(v["obj"]) + len(v["desc"]) + len(v["progress"]) + len(v["reward"]) for v in out.values())
print("total chars:", tot)
