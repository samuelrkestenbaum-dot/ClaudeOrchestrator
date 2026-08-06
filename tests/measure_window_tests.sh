#!/usr/bin/env bash
# LANE 7 tests — measured-window recorder.
set -u
P=0; F=0
ok(){ P=$((P+1)); }
no(){ F=$((F+1)); printf 'FAIL: %s\n' "$1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
W=build-os/measure/window.sh
# 1 open requires a reading
bash $W open "$T/w1" --model m1 2>/dev/null && no "open without reading accepted" || ok
# 2 open with reading
bash $W open "$T/w1" --model m1 --reading "Weekly · Fable — 3%" >/dev/null && ok || no "open failed"
# 3 double open refused
bash $W open "$T/w1" --model m1 --reading "x" 2>/dev/null && no "double open" || ok
# 4 note lands
bash $W note "$T/w1" --task T1 --event "routed direct" && ok || no "note failed"
# 5 close requires reading
bash $W close "$T/w1" 2>/dev/null && no "close without reading" || ok
# 6 close with git derivation
R=$(mktemp -d); git -C "$R" init -q; git -C "$R" -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
S=$(git -C "$R" rev-parse HEAD); echo x > "$R/f"; git -C "$R" add f; git -C "$R" -c user.email=t@t -c user.name=t commit -q -m c1
bash $W close "$T/w1" --reading "Weekly · Fable — 5%" --repo "$R" --since "$S" | grep -q "1 commit(s)" && ok || no "close derivation"
# 7 verbatim readings preserved
grep -q "Weekly · Fable — 3%" "$T/w1/WINDOW.tsv" && grep -q "Weekly · Fable — 5%" "$T/w1/WINDOW.tsv" && ok || no "verbatim readings"
# 8 note after close refused
bash $W note "$T/w1" --task T2 --event e 2>/dev/null && no "note after close" || ok
rm -rf "$R"
printf '==== RESULT: %d passed, %d failed ====\n' "$P" "$F"
[ "$F" -eq 0 ]
