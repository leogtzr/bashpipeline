#!/bin/bash
# Leo Gutiérrez R. leogutierrezramirez@gmail.com

readonly WORK_DIR=$(dirname "${0}" 2> /dev/null)
readonly BP_LIB_NOT_FOUND_ERROR=76

. "${WORK_DIR}/bplib.sh" || {
    echo "[$(date '+%F %T')] [ERROR] bplib.sh NOT found."
    exit ${BP_LIB_NOT_FOUND_ERROR}
}

# Start scripts execution
start_scripts && {
    echo "$? ... finished ... "
}

exit 0