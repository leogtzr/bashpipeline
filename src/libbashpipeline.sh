#!/bin/bash
# Leo Gutiérrez R. leogutierrezramirez@gmail.com

. bp_flow.env 2> /dev/null || {
    echo -e "\n[ERROR] bp_flow.env file not found.\n"
    exit 68
}

if [ -f ./bp_functions.sh ]; then
    . ./bp_functions.sh
else
    echo -e "[`date '+%F %T'`] [ERROR] bp_functions.sh NOT found."
    exit 76
fi

# Start execution
start_scripts

exit 0