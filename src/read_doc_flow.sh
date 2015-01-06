#!/bin/bash

# Including the necessary script files:
. bp_flow.env 2> /dev/null || {
    echo -e "\n[ERROR] bp_flow.env file not found.\n"
    exit 68
}

dump_processor_info() {
    
    if [ -z "$1" ]; then
        echo -e "ERROR, argument empty"
        return 1
    fi
    # a:a script:2:b

    local SCRIPT_NAME=`echo -e "$1" | awk -F "${FLOW_DOC_DELIMITER}" '{print $1}'`
    local SCRIPT_DESC=`echo -e "$1" | awk -F "${FLOW_DOC_DELIMITER}" '{print $2}'`
    local SCRIPT_RET_VAL=`echo -e "$1" | awk -F "${FLOW_DOC_DELIMITER}" '{print $3}'`
    local NEXT_SCRIPTS=`echo -e "$1" | awk -F "${FLOW_DOC_DELIMITER}" '{print $4}'`

    echo -e "{\n\tScript: ${SCRIPT_NAME}"
    echo -e "\tDescription: ${SCRIPT_DESC}"
    echo -e "\tExpected status: ${SCRIPT_RET_VAL}"
    echo -e "\tNext scripts: ${NEXT_SCRIPTS}\n}"

}

execute_chain() {
    for NEXT_SCRIPT in `echo -e "$1" | tr ',' '\n'`; do
        LINE=`grep -E "^${NEXT_SCRIPT}" "${FLOW_FILE}"`
        if [ ! -z "${LINE}" ]; then
            
            dump_processor_info "${LINE}"
            local SCRIPT_RET_VAL=`echo -e "${LINE}" | awk -F "${FLOW_DOC_DELIMITER}" '{print $3}'`
            local HEAD_LINK_SCRIPT=`echo -e "${LINE}" | awk -F "${FLOW_DOC_DELIMITER}" '{print $1}'`
            
            "${WORKING_DIR}/${HEAD_LINK_SCRIPT}.sh"
            EXIT_STATUS=$?

            if [ $EXIT_STATUS -eq ${SCRIPT_RET_VAL} ]; then
                #dump_processor_info "$LINE"
                execute_chain `echo -e "$LINE" | awk -F ":" '{print $4}'`
            else
                echo -e "[FATAL] Different exit status ... $EXIT_STATUS"
                #dump_processor_info "${LINE}"
                exit 78
            fi
        fi
    done
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
 
    local HEAD_LINK=`grep -Ev '^#' "${FLOW_FILE}" | grep -vE '^$' | sed -n 1p`
    local SCRIPT_RET_VAL=`echo -e "${HEAD_LINK}" | awk -F "${FLOW_DOC_DELIMITER}" '{print $3}'`
    dump_processor_info "${HEAD_LINK}"

    # Execute script and if it is OK continue with the chain
    local HEAD_LINK_SCRIPT=`echo -e "${HEAD_LINK}" | awk -F "${FLOW_DOC_DELIMITER}" '{print $1}'`
    "${WORKING_DIR}"/"${HEAD_LINK_SCRIPT}".sh
    if [ $? -eq ${SCRIPT_RET_VAL} ]; then
        local NEXT_SCRIPT_STR=`echo -e "${HEAD_LINK}" | awk -F "${FLOW_DOC_DELIMITER}" '{print $4}'`
        execute_chain "${NEXT_SCRIPT_STR}"
    fi

}

read_doc_flow