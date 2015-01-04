#!/bin/bash
# Leo Gutiérrez R. leogutierrezramirez@gmail.com

if [ -f ./bplib.sh ]; then
    . ./bplib.sh
else
    echo -e "[`date '+%F %T'`] [ERROR] bp_functions.sh NOT found."
    exit 76
fi

# Start execution
start_scripts && {
	echo -e "$? ... finished ... "
}

exit 0