#!/bin/bash

HISTORY="$HOME/.fluxbox/favlist.menu"

EXEC=`grep ^Exec= $@ | cut -d '=' -f 2 | sed 's/ %.//'`

$EXEC &

echo "$@" >> "$HISTORY"
#sort "$HISTORY" | uniq -c | sort -n | head -n 5
