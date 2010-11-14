#!/bin/sh

SRC="../contrib/wrapper/src/bin/sh.script.in"
DST="freenet/run.sh"

cp "$SRC" "$DST" || exit 1
patch -p0 < run.sh.diff
sed -i \
  -e 's/@app.name@/Freenet/g' \
  -e 's/@app.long.name@/Freenet 0.7 (experimental release)/g' \
  -e 's/@app.description@/Freenet reference daemon/g' \
  "$DST"
chmod +x "$DST"

