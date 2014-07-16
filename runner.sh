#!/bin/bash 


PREFIX="$HOME/.fluxbox/MenuGenie"
MENU="$HOME/.fluxbox/menu.apps"
BLACKLIST="2DGraphics|RasterGraphics|VectorGraphics|Application|Player|Record|GNOME|Qt|KDE|GTK|X-|AudioVideoEditing|Core|ConsoleOnly"

function cleanUp {
	rm -rf "$PREFIX" &> /dev/null
	mkdir -pv "$PREFIX" &> /dev/null
	echo > "$MENU" 
}

function isNotApp {
	grep -q ^Type=Application "$@"
	return $?
}

function hasNoExec {
	grep -q ^Exec= "$@"
	return $?
}

function renamePath {
	echo "$@" | sed  -e 's/AudioVideo/Multimedia/' \
			 -e 's/WebBrowser/Web Browser/' \
			 -e 's/FileTools/File Tools/' \
			 -e 's/FileBrowser/File Browser/' \
			 -e 's/FileManager/File Manager/' \
			 -e 's/InstantMessaging/Instant Messaging/'
}

function addMenuExec {
	NAME="`grep ^Name= "$@" | cut -d '=' -f 2 | head -n 1`"
	EXEC="`grep ^Exec= "$@" | cut -d '=' -f 2 | head -n 1 | sed 's/ %.//'`"
	echo "[exec] ($NAME) {~/.fluxbox/launcher.sh $@}" >> "$MENU"

}

function traverseTree {
	echo "Adding to menu : $@" | sed "s^$PREFIX^^g"
	command ls --group-directories-first "$@" | while true; do
		read LINE || break
		if [ -d "$@/$LINE" ]; then
			echo "[submenu] (${LINE})" >> "$MENU"
			traverseTree "$@/$LINE"
			echo "[end]" >> "$MENU"
		else
			addMenuExec "$@"/"$LINE"
		fi
	done
}


function searchApps {
	COL=$(( `tput cols`-10 ))

	find /usr -type f -iname \*.desktop 2>/dev/null | while true; do
		read LINE || break
	
		NAME="`cat $LINE | grep ^Name= | cut -d '=' -f 2 | head -n 1`"
		if [ -z "$NAME" ]; then
			NAME="${LINE##*/}"
		fi
		printf "%-${COL}s" "Processing  $NAME ... "
	
		CATEGORIES=`grep ^Categories $LINE | cut -d '=' -f 2`
	
		if [ ! `isNotApp $LINE` -a ! `hasNoExec $LINE` -a -n "$CATEGORIES" ]; then
			CATLIST=`echo $CATEGORIES | sed 's/;/\n/g' | grep -Ev ^"$BLACKLIST"`
			DIR=`echo $CATLIST | sed 's/ /\//g' | sed "$REPLACE"`
			DIR="`renamePath $DIR`"
			mkdir -p "$PREFIX/$DIR"
			cp "$LINE" "$PREFIX/$DIR"
			echo '[ added ]'
		else
			echo '[ignored]'
		fi
	done
	echo
}

cleanUp && searchApps

mkdir "$PREFIX/Other" &> /dev/null
mv "$PREFIX"/*.desktop "$PREFIX/Other" &> /dev/null
rmdir "$PREFIX/Other" &> /dev/null

traverseTree "$PREFIX"
