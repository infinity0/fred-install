#!/bin/sh

EXEC_SELF="./bin/1run.sh"

if test -z "$FREENET_CFG"; then echo "This script is meant to be run from the main run.sh"; exit 1; fi
if test "X`id -u`" = "X0"; then echo "The installer isn\'t meant to be run as root"; exit 1; fi

if ! test -f "$FREENET_INST"; then
	if test -s jvmerror; then cat jvmerror; fi
	echo "IllegalState: Delete the directory and re-unpack a fresh tarball"
	exit 1
fi

if test -s "$FREENET_CFG"; then
	echo "This script isn\'t meant to be used more than once."
	echo "If you really need to do this, first delete $FREENET_CFG"
	rm -f "$EXEC_SELF"
	exit 1
fi

if test ! -s "$EXEC_SELF"; then
	echo "This script should be started using $EXEC_SELF!"
	exit 1
fi

CAFILE="startssl.pem"
JOPTS="-Djava.net.preferIPv4Stack=true"
OS="`uname -s`"

DIR_LOG="./log/"
DIR_CFG="./etc/"
DIR_JAR="./jar/"
DIR_PLUGIN="./jar/plugins/"
DIR_TMP="./tmp/"

# Set better directories
echo "Setting up program directories"
for i in "$DIR_LOG" "$DIR_CFG" "$DIR_JAR" "$DIR_PLUGIN" "$DIR_TMP"; do mkdir -p "$i"; done
cat > "$FREENET_CFG" << EOF
node.pluginDir=$DIR_PLUGIN
node.tempDir=$DIR_TMP
node.cfgDir=$DIR_CFG
logger.dirname=$DIR_LOG
EOF

# Tweak $FREENET_CFG before the first startup
echo "Enabling the auto-update feature"
echo "node.updater.enabled=true" >> "$FREENET_CFG"
echo "node.updater.autoupdate=true" >> "$FREENET_CFG"

echo "Detecting tcp-ports availability..."

# Try to auto-detect the first available port for fproxy
FPROXY_PORT=""
for port in 8888 8889 8899 8999 9999; do
	if java -jar bin/bindtest.jar $port; then
		FPROXY_PORT=$port
		break
	else
		echo "Could not bind fproxy to TCP port $port..."
	fi
done
if test -z "$FPROXY_PORT"; then
	echo "Could not find a suitable port to bind on 127.0.0.1."
	echo "Make sure your loopback interface is properly configured."
	exit 1
fi
echo "fproxy.enabled=true" >> "$FREENET_CFG"
echo "fproxy.port=$FPROXY_PORT" >> "$FREENET_CFG"

# Try to auto-detect the first available port for fcp
FCP_PORT=""
for port in 9481 9482 9483; do
	if java -jar bin/bindtest.jar $port; then
		FCP_PORT=$port
		break
	else
		echo "Could not bind fcp to TCP port $port..."
	fi
done
if test -n "$FCP_PORT"; then
	echo "fcp.enabled=true" >> "$FREENET_CFG"
	echo "fcp.port=$FCP_PORT" >> "$FREENET_CFG"
fi

echo "Downloading update.sh"
java $JOPTS -jar bin/sha1test.jar update.sh "." "$CAFILE" >/dev/null 2>jvmerror
if test -s jvmerror; then
	echo "#################################################################"
	echo "The JVM failed."
	echo "Some old versions of OpenJDK and other open source Java implementations have bugs. "
	echo "If you keep running into problems, try installing Sun Java 1.5 or 1.6.  On ubuntu:"
	echo
	echo "apt-get install sun-java6-jre"
	echo "update-java-alternatives -s java-6-sun"
	echo "#################################################################"
	echo "You are currently using:"
	java -version
	echo "#################################################################"
	echo "The full error message is :"
	echo "#################################################################"
	cat jvmerror
	exit 1
fi
rm -f jvmerror
chmod a+rx "./update.sh"

echo "Downloading wrapper_$OS.zip"
java $JOPTS -jar bin/sha1test.jar wrapper_$OS.zip . "$CAFILE" > /dev/null
java $JOPTS -jar bin/uncompress.jar wrapper_$OS.zip . 2>&1 >/dev/null

# We need the exec flag on /bin
chmod u+x bin/* lib/*

echo "Downloading freenet-stable-latest.jar"
java $JOPTS -jar bin/sha1test.jar freenet-stable-latest.jar "$DIR_JAR" "$CAFILE" >/dev/null
ln -s freenet-stable-latest.jar "$DIR_JAR/freenet.jar"
echo "Downloading freenet-ext.jar"
java $JOPTS -jar bin/sha1test.jar freenet-ext.jar "$DIR_JAR" "$CAFILE" >/dev/null

# Register plugins
echo "Downloading the JSTUN plugin"
java $JOPTS -jar bin/sha1test.jar JSTUN.jar "$DIR_PLUGIN" "$CAFILE" >/dev/null 2>&1
echo "Downloading the UPnP plugin"
java $JOPTS -jar bin/sha1test.jar UPnP.jar "$DIR_PLUGIN" "$CAFILE" >/dev/null 2>&1
echo "pluginmanager.loadplugin=JSTUN;UPnP" >> "$FREENET_CFG"

echo "Downloading seednodes.fref"
java $JOPTS -jar bin/sha1test.jar seednodes.fref "." "$CAFILE" >/dev/null

if test -x `which crontab`; then
	echo "Installing cron job to start Freenet on reboot..."
	crontab -l 2>/dev/null > autostart.install
	echo "@reboot   \"$PWD/run.sh\" start 2>&1 >/dev/null #FREENET AUTOSTART - $FPROXY_PORT" >> autostart.install
	if crontab autostart.install; then
		sed -i -e "s/8888/$FPROXY_PORT/g" bin/remove_cronjob.sh
		echo "Installed cron job; you can remove it by running bin/remove_cronjob.sh"
	fi
	if test -s autostart.install; then rm -f autostart.install; fi
else
	echo "Cron appears not to be installed."
	echo "You'll need to run ./run.sh to start Freenet manually after a reboot."
fi

rm -f "$FREENET_INST"

# Starting the node up
./run.sh start

echo "Please visit http://127.0.0.1:$FPROXY_PORT/ to configure your node"
echo "Finished"

rm -f "$EXEC_SELF"
exit 0
