#!/bin/sh

cp sh.script.in run.sh
patch -p0 < run.sh.diff
sed -i \
  -e 's/@app.name@/Freenet/g' \
  -e 's/@app.long.name@/Freenet 0.7 (experimental release)/g' \
  -e 's/@app.description@/Freenet reference daemon/g' \
  run.sh
