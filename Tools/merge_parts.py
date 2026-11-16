#!/usr/bin/env python3
"""python3 -I merge_parts.py NNN  : out/chunk_NNN_p*.json -> out/chunk_NNN.json, дараа нь validate"""
import glob, json, os, subprocess, sys
S = os.path.dirname(os.path.abspath(__file__))
n = sys.argv[1]
parts = sorted(glob.glob(os.path.join(S, "out", "chunk_%s_p*.json" % n)))
res = []
for p in parts:
    res += json.load(open(p, encoding="utf-8"))
import re
CYR = "А-Яа-яӨөҮүЁё"
def _norm(t):
    t = re.sub(r"(\$[Bb])[ \t]+(?=[%s])" % CYR, r"\1", t)      # $B + зай + кирилл
    t = re.sub(r"(\$[gG])[ \t]+", r"\1", t)                    # $g эрэгтэй:эмэгтэй;
    t = re.sub(r"(\$[gG][^:;]*:)[ \t]+", r"\1", t)
    return t
for _q in res:
    for _k in ("t", "o", "d", "p", "c"):
        if isinstance(_q.get(_k), str):
            _q[_k] = _norm(_q[_k])
json.dump(res, open(os.path.join(S, "out", "chunk_%s.json" % n), "w", encoding="utf-8"), ensure_ascii=False)
print("нэгтгэсэн:", len(res), "quest,", len(parts), "хэсэг")
sys.exit(subprocess.call([sys.executable, "-I", os.path.join(S, "validate_chunk.py"),
                          os.path.join(S, "chunks", "chunk_%s.json" % n),
                          os.path.join(S, "out", "chunk_%s.json" % n)]))
