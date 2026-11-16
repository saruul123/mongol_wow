#!/bin/sh
# ашиглалт: sh Tools/validate_all.sh NNN
cd "$(dirname "$0")" && python3 -I validate_chunk.py chunks_en/chunk_$1.json out/chunk_$1.json
