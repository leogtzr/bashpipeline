#!/bin/bash
# Leo Gutiérrez R. | leogutierrezramirez@gmail.com

readonly ERROR_BP_FLOW_FILE_NOT_FOUND=68
readonly ERROR_INVALID_ARGUMENT_NUMBER=69
readonly ERROR_INIT_SCRIPT_NOT_FOUND=70
readonly ERROR_FLOW_NOT_SUPPORTED=71

export ERROR_BP_FLOW_FILE_NOT_FOUND
export ERROR_INVALID_ARGUMENT_NUMBER

help_seq() {
    cat <<-HELP_SEQ
    
    $0 N.sh

    N:  number of script where the execution failed.

HELP_SEQ
}

help_doc() {
    cat <<-HELP_DOC
    
    $0 INITIAL_SCRIPT

HELP_DOC
}

. bp_flow.env 2> /dev/null || {
    echo -e "\n[ERROR] bp_flow.env file not found.\n"
    exit ${ERROR_BP_FLOW_FILE_NOT_FOUND}
}

if [ $# -ne 1 -a "${FLOW_TYPE}" = "SEQ" ]; then
    help_seq
    exit ${ERROR_INVALID_ARGUMENT_NUMBER}
elif [ $# -ne 1 -a "${FLOW_TYPE}" = "DOC" ]; then
    help_doc
    exit ${ERROR_INVALID_ARGUMENT_NUMBER}
fi

# Load lib:
if [ -f ./bplib.sh ]; then
    . ./bplib.sh
else
    echo "[`date '+%F %T'`] [ERROR] bplib.sh NOT found."
    exit 76
fi

if [ "${FLOW_TYPE}" = "SEQ" ]; then

    if [ ! -f ".bp.error" ]; then
        echo "Nothing to do ... "
        exit 0
    fi

    SCRIPT_TO_START=$1
    awk -F '=' '/^FAILED_SCRIPT/ {print $2}' .bp.error | grep -Eq "^${SCRIPT_TO_START}$" && {
        START_POINT=`awk -F '=' '/^FAILED_SCRIPT/ {print $2}' .bp.error | cut -f1 -d'.'`
        for script in `seq -f "%g.sh" ${START_POINT} 10`; do
            if [ -f "${WORKING_DIR}/${script}" ]; then
                log_debug "Running: $script"
                "${WORKING_DIR}/${script}" 2> bp_error_desc
                EXIT_STATUS=$?
                log_debug "status: ${EXIT_STATUS}"
                if [ ${EXIT_STATUS} -ne 0 ]; then
                    SCRIPT_NAME=`basename "${script}"`
                    build_bp_error_file "${SCRIPT_NAME}" "${EXIT_STATUS}" "`cat ./bp_error_desc | tr '\n' '@'`"
                    dump_error_info
                    exit ${EXIT_STATUS}
                fi
            fi
        done
        rm -f ".bp.error" 2> /dev/null
        log_debug "Finished ... "
        exit 0
    } || {
        echo -e "\n\tThe script to continue does not match the: "
        awk -F "=" '/^FAILED_SCRIPT/ {print $0}' .bp.error
        echo -e "\tline in the .bp.error file.\n"
    }
elif [ "${FLOW_TYPE}" = "DOC" ]; then
    
    SCRIPT_TO_START=$1
    grep -Ev '^#' "${FLOW_FILE}" | grep -vE '^$' | grep -Eq "^${SCRIPT_TO_START}:" && {
        
        SCRIPT_TO_EXECUTE_TMP=`grep -Ev '^#' "${FLOW_FILE}" | grep -vE '^$' | grep -E "^${SCRIPT_TO_START}" | sed -n 1p | awk -F ":" '{print $1}'`
        
        if [ -z "${SCRIPT_TO_EXECUTE_TMP}" ]; then
            echo "Script to execute not found."
            exit 98
        fi

        execute_chain "${SCRIPT_TO_EXECUTE_TMP}"
        log_debug "Done ... "
        exit 0

    } || {
        echo "ERROR, initial script not found in ${FLOW_FILE} flow file."
        exit ${ERROR_INIT_SCRIPT_NOT_FOUND}
    }

    exit 0
else
    echo "Flow type not supported."
    exit ${ERROR_FLOW_NOT_SUPPORTED}
fi

exit 0