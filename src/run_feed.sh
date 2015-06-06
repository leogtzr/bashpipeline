#!/bin/bash
# Leo Gutiérrez R. leogutierrezramirez@gmail.com

if [ -f ./bplib.sh ]; then
    . ./bplib.sh
else
    echo "[`date '+%F %T'`] [ERROR] bplib.sh NOT found."
    exit 76
fi

# Start scripts execution
start_scripts && {
    echo "$? ... finished ... "
}

exit 0