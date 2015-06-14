# bash pipeline general functions. 
# Leo Gutiérrez R. leogutierrezramirez@gmail.com

readonly ERROR_EMPTY_DEBUG_ARGUMENT=69
readonly ERROR_EMPTY_ARGUMENT=70

. bp_flow.env 2> /dev/null || {
    echo "[ERROR] bp_flow.env file not found."
    exit ${ERROR_BP_FLOW_FILE_NOT_FOUND}
}

#######################################################################
# name: log_debug
#######################################################################
log_debug () {
	if [ -z "$1" ]; then
		echo "ERROR, empty argument"
		exit ${ERROR_EMPTY_DEBUG_ARGUMENT}
	fi

	if [ ${DEBUG} -eq 1 ]; then
		if [ ${INCLUDE_DATE_LOG} -eq 1 ]; then
			echo "[`date '+%F %T'`] [DEBUG] $1" | tee -a "${DEBUG_FILE}"
		else
			echo "[DEBUG] $1" | tee -a "${DEBUG_FILE}"
		fi
	fi

}

#######################################################################
# name: build_bp_error_file
# Generates .bp.error file. This file is used by the bp_continue.sh
# script to continue the scripts execution.
#######################################################################
build_bp_error_file() {
	cat <<-BP_ERROR_CONTENT > .bp.error
	FAILED_SCRIPT=$1
	EXIT_CODE=$2
	ERROR_MSG="$3"
	BP_ERROR_CONTENT
}

#######################################################################
# name: dump_error_info
# Convenience function to show current status of the failed script.
#######################################################################
dump_error_info() {
	(
		. .bp.error
		echo -e "\nFAILED_SCRIPT ===> ${FAILED_SCRIPT}"
		echo "EXIT_CODE =======> ${EXIT_CODE}"
		echo "ERROR_MSG ======> '${ERROR_MSG}'" | tr '@' '\n'

		echo "Use bp_continue.sh once the problem has been fixed."
	)
	rm .bp_error_desc 2> /dev/null
}

#######################################################################
# name: dump_processor_info
#######################################################################
dump_processor_info() {
    
    if [ -z "$1" ]; then
        echo "ERROR, argument empty"
        return ${ERROR_EMPTY_ARGUMENT}
    fi

    if [ ${DEBUG} -eq 1 ]; then
        local SCRIPT_NAME=`echo "$1" | awk -F ":" '{print $1}'`
        local SCRIPT_DESC=`echo "$1" | awk -F ":" '{print $2}'`
        local SCRIPT_RET_VAL=`echo "$1" | awk -F ":" '{print $3}'`
        local NEXT_SCRIPTS=`echo "$1" | awk -F ":" '{print $4}'`

        echo -e "{\n\tScript: ${SCRIPT_NAME}"
        echo -e "\tDescription: ${SCRIPT_DESC}"
        echo -e "\tExpected status: ${SCRIPT_RET_VAL}"
        echo -e "\tNext scripts: ${NEXT_SCRIPTS}\n}"
    fi

}

#######################################################################
# name: execute_chain
# Function that executes recursively scripts defined in the FLOW_FILE file.
#######################################################################
execute_chain() {
    for NEXT_SCRIPT in `echo "$1" | tr ',' '\n'`; do
        LINE=`grep -E "^${NEXT_SCRIPT}" "${FLOW_FILE}"`
        if [ ! -z "${LINE}" ]; then
            
            dump_processor_info "${LINE}"
            local SCRIPT_RET_VAL=`echo "${LINE}" | awk -F ":" '{print $3}'`
            local HEAD_LINK_SCRIPT=`echo "${LINE}" | awk -F ":" '{print $1}'`
            
            "${WORKING_DIR}/${HEAD_LINK_SCRIPT}.sh" 2> .bp_error_desc
            EXIT_STATUS=$?
            log_debug "exit status: ${EXIT_STATUS}"

            if [ $EXIT_STATUS -eq ${SCRIPT_RET_VAL} ]; then
                local next_to_do=`echo "$LINE" | awk -F ":" '{print $4}'`
                execute_chain $next_to_do
            else
                echo "[FATAL] Different exit status ... ${EXIT_STATUS}"

                dump_processor_info "${LINE}"
                build_bp_error_file "${HEAD_LINK_SCRIPT}" "${EXIT_STATUS}" "`cat ./.bp_error_desc | tr '\n' '@'`"
                exit 78
            fi
        fi
    done
}

#######################################################################
# name: print_execute_chain
# Convenience function to print recursively scripts that will be
# executed.
#######################################################################
print_execute_chain() {
    if [ ! -z "$1" ]; then
        echo -e "\t${1}"
    fi
    for NEXT_SCRIPT in `echo "$1" | tr ',' '\n'`; do
        LINE=`grep -E "^${NEXT_SCRIPT}" "${FLOW_FILE}"`
        if [ ! -z "${LINE}" ]; then
            dump_processor_info "${LINE}"
            local SCRIPT_RET_VAL=`echo "${LINE}" | awk -F ":" '{print $3}'`
            local HEAD_LINK_SCRIPT=`echo "${LINE}" | awk -F ":" '{print $1}'`
            local NEXT_SCRIPT_TO_DO=`echo "${LINE}" | awk -F ":" '{print $4}'`
            print_execute_chain ${NEXT_SCRIPT_TO_DO}
        fi
    done
}

# Read the *.flow file
read_doc_flow() {
    
    if [ -z "${FLOW_FILE}" ]; then
        echo "ERROR, empty argument."
        exit ${ERROR_EMPTY_ARGUMENT}
    fi
    
    if [ ! -f "${FLOW_FILE}" ]; then
        echo "ERROR, flow file not found."
        exit 78
    fi
 
    local HEAD_LINK=`grep -Ev '^#' "${FLOW_FILE}" | grep -vE '^$' | sed -n 1p`
    local SCRIPT_RET_VAL=`echo "${HEAD_LINK}" | awk -F ":" '{print $3}'`
    dump_processor_info "${HEAD_LINK}"

    # Execute script and if it is OK continue with the chain
    local HEAD_LINK_SCRIPT=`echo "${HEAD_LINK}" | awk -F ":" '{print $1}'`
    "${WORKING_DIR}"/"${HEAD_LINK_SCRIPT}".sh 2> .bp_error_desc
    EXIT_STATUS=$?
    log_debug "exit status: ${EXIT_STATUS}"

    # If the exit status matches the defined
    # script return value:
    if [ $EXIT_STATUS -eq ${SCRIPT_RET_VAL} ]; then
        local NEXT_SCRIPT_STR=`echo "${HEAD_LINK}" | awk -F ":" '{print $4}'`
        execute_chain "${NEXT_SCRIPT_STR}"
    fi

}

start_scripts() {
	
	log_debug "Beginning ${PROJ_NAME} project"

	if [ "${FLOW_TYPE}" = "SEQ" ]; then
		
		for script in `seq -f "%g.sh" ${START_POINT} 10`; do
			if [ -f "${WORKING_DIR}/${script}" ]; then
				log_debug "Running: $script  SCRIPT"

	            # Execute sequential scripts within the WORKING_DIR
	            # and send the output to the ".bp_error_desc" file.
				"${WORKING_DIR}/${script}" 2> .bp_error_desc
				EXIT_STATUS=$?
				log_debug "exit status: ${EXIT_STATUS}"

				if [ ${EXIT_STATUS} -ne 0 ]; then
					SCRIPT_NAME=`basename "${script}"`
					build_bp_error_file "${SCRIPT_NAME}" "${EXIT_STATUS}" "`cat ./.bp_error_desc | tr '\n' '@'`"
					dump_error_info
					exit ${EXIT_STATUS}
				fi
	            
			fi
		done

	elif [ "${FLOW_TYPE}" = "DOC" ]; then
        read_doc_flow
	else
		echo "Flow type not supported."
	fi

	log_debug "Finished ${PROJ_NAME} project"
}