#!/bin/bash
# Leo Gutiérrez R. | leogutierrezramirez@gmail.com

readonly ERROR_BP_FLOW_FILE_NOT_FOUND=68
readonly ERROR_INVALID_ARGUMENT_NUMBER=69

export ERROR_BP_FLOW_FILE_NOT_FOUND
export ERROR_INVALID_ARGUMENT_NUMBER

. bp_flow.env 2> /dev/null || {
    echo -e "\n[ERROR] bp_flow.env file not found.\n"
    exit ${ERROR_BP_FLOW_FILE_NOT_FOUND}
}

if [ $# -ne 1 ]; then
    echo "ERROR, please enter an initial script argument."
    exit ${ERROR_INVALID_ARGUMENT_NUMBER}
fi

if [ ! -f ".bp.error" ]; then
    echo "Nothing to do ... "
    exit 0
else

    # Load lib:
    if [ -f ./bplib.sh ]; then
        . ./bplib.sh
    else
        echo "[`date '+%F %T'`] [ERROR] bplib.sh NOT found."
        exit 76
    fi

    if [ "${FLOW_TYPE}" = "SEQ" ]; then
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
            exit 0
        } || {
            echo -e "\n\tThe script to continue does not match the: "
            awk -F "=" '/^FAILED_SCRIPT/ {print $0}' .bp.error
            echo -e "\tline in the .bp.error file.\n"
        }
    else
        SCRIPT_TO_START=$1
        NEXT_SCRIPT_TO_EXECUTE=$2
        echo "Not yet ... "
        cat .bp.error
        exit 0
    fi

    exit 73
fi

exit 0