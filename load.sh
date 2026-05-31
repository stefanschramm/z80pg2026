#!/bin/bash

set -e

filename="$1"
destination="$2"
call="$3"
pause=0.1
long_pause=3

if [ -z "$destination" ] ; then
	echo "Usage: $0 filename destination"
	exit 1
fi

if [ ! -f "$filename" ] ; then
	echo "File does not exist."
	exit 1
fi

device="/dev/ttyUSB0"
size=$(stat -c '%s' "$1")
size_hex=$(printf '%04x\n' "$size")

echo -n "l" > "$device"
sleep $pause
echo -n "$size_hex" > "$device"
sleep $pause
echo -n "$destination" > "$device"
sleep $pause
cat "$1" > "$device"

if [ ! -z "$call" ] ; then
	sleep $long_pause
	echo -n "c" > "$device"
	sleep $pause
	echo -n "$call" > "$device"
fi

