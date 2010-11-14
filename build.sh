#!/bin/sh

SRCSH="../contrib/wrapper/src/bin/sh.script.in"
SRC="../java_installer"
INST="freenet"
BLD="build"
DST="$BLD/$INST"
PKG="freenet07.tar.gz"

rm -rf "$BLD" && mkdir -p "$BLD"
cp -a "$INST" "$DST"

cp "$SRCSH" "$DST/run.sh" || exit 1
patch "$DST/run.sh" run.sh.diff
sed -i \
  -e 's/@app.name@/Freenet/g' \
  -e 's/@app.long.name@/Freenet 0.7 (experimental release)/g' \
  -e 's/@app.description@/Freenet reference daemon/g' \
  "$DST/run.sh"
chmod +x "$DST/run.sh"

( cd "$SRC" && ant compile )
cp "$SRC"/res/bin/*.jar "$DST"/bin/
cp "$SRC"/res/unix/bin/remove_cronjob.sh "$DST"/bin/

( cd "$BLD"
tar czf "$PKG" "$INST"
sha1sum "$PKG" > "$PKG.sha1"
)
