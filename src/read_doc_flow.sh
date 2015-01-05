#!/bin/bash

# Including the necessary script files:
. bp_flow.env 2> /dev/null || {
    echo -e "\n[ERROR] bp_flow.env file not found.\n"
    exit 68
}

# Read the *.flow file
read_doc_flow() {
    
    if [ -z "${FLOW_FILE}" ]; then
        echo -e "ERROR, argument empty."
        exit 78
    fi
    
    if [ ! -f "${FLOW_FILE}" ]; then
        echo -e "ERROR, flow file not found."
        exit 78
    fi
 
    local line=`grep -Ev '^#' "${FLOW_FILE}" | grep -vE '^$' | sed -n 1p`
    local SCRIPT=`echo -e "$line" | awk -F "${FLOW_DOC_DELIMITER}" '{print $1}'`
    local SCRIPT_DESC=`echo -e "$line" | awk -F "${FLOW_DOC_DELIMITER}" '{print $2}'`
    local SCRIPT_RET_VAL=`echo -e "$line" | awk -F "${FLOW_DOC_DELIMITER}" '{print $3}'`
    local NEXT_SCRIPT=`echo -e "$line" | awk -F "${FLOW_DOC_DELIMITER}" '{print $4}'`

    local HEAD_LINK=`grep -Ev '^#' "${FLOW_FILE}" | grep -vE '^$' | sed -n 1p`

    echo -e "${HEAD_LINK}"
    local NEXT_SCRIPT_STR=`echo -e "${HEAD_LINK}" | awk -F ":" '{print $4}'`
    execute_chain "${NEXT_SCRIPT_STR}"

}

execute_chain() {
    for NEXT_SCRIPT in `echo -e "$1" | tr ',' '\n'`; do
        LINE=`grep -E "^${NEXT_SCRIPT}" "${FLOW_FILE}"`
        if [ ! -z "${LINE}" ]; then
            echo -e "[$NEXT_SCRIPT]->${LINE}"
            execute_chain `echo -e "$LINE" | awk -F ":" '{print $4}'`
        fi
    done
}

read_doc_flow