# bash pipeline general functions. 
# Leo Gutiérrez R. leogutierrezramirez@gmail.com

# Including the necessary script files:
. bp_flow.env 2> /dev/null || {
    echo -e "\n[ERROR] bp_flow.env file not found.\n"
    exit 68
}

log_debug () {
	if [ -z "$1" ]; then
		echo "ERROR, empty argument"
		exit 78
	fi

	if [ ${DEBUG} -eq 1 ]; then
		if [ ${INCLUDE_DATE_LOG} -eq 1 ]; then
			echo -e "[`date '+%F %T'`] [DEBUG] $1" | tee -a "${DEBUG_FILE}"
		else
			echo -e "[DEBUG] $1" | tee -a "${DEBUG_FILE}"
		fi
	fi

}

build_bp_error_file() {
	cat <<-BP_ERROR_CONTENT > bp.error
	FAILED_SCRIPT=$1
	EXIT_CODE=$2
	ERROR_MSG="$3"
	BP_ERROR_CONTENT
}

dump_error_info() {
	(
		. bp.error
		echo -e "\nFAILED_SCRIPT ===> ${FAILED_SCRIPT}"
		echo -e "EXIT_CODE =======> ${EXIT_CODE}"
		echo -e "ERROR_MSG ======> '${ERROR_MSG}'" | tr '@' '\n'

		echo -e "Use bp_continue.sh once the problem has been fixed.\n"
		rm bp.error
	)
	rm bp_error_desc
}

dump_processor_info() {
    
    if [ -z "$1" ]; then
        echo -e "ERROR, argument empty"
        return 1
    fi

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
            
            "${WORKING_DIR}/${HEAD_LINK_SCRIPT}.sh" 2> bp_error_desc
            EXIT_STATUS=$?
            log_debug "exit status: ${EXIT_STATUS}"

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
    "${WORKING_DIR}"/"${HEAD_LINK_SCRIPT}".sh 2> bp_error_desc
    EXIT_STATUS=$?
    log_debug "exit status: ${EXIT_STATUS}"

    if [ $EXIT_STATUS -eq ${SCRIPT_RET_VAL} ]; then
        local NEXT_SCRIPT_STR=`echo -e "${HEAD_LINK}" | awk -F "${FLOW_DOC_DELIMITER}" '{print $4}'`
        execute_chain "${NEXT_SCRIPT_STR}"
    fi

}

# Punto inicial del programa ... 
# Inicia la ejecución de los scripts dentro del directorio
# WORKING_DIR.

# Si alguno de los scripts dentro del directorio WORKING_DIR falla
# todo el proceso se detiene. 
# Cuando el error ha sido corregido, se puede utilizar el script
# bp_continue.sh para continuar la ejecución del proceso:
# bp_continue.sh 5.sh
start_scripts() {
	
	log_debug "Beginning ${PROJ_NAME} project"

	if [ "${FLOW_TYPE}" = "SEQ" ]; then
		
		for script in `seq -f "%g.sh" ${START_POINT} 10`; do
			if [ -f "${WORKING_DIR}/${script}" ]; then
				log_debug "Running: $script  SCRIPT"

	            # Execute sequential scripts within the WORKING_DIR
	            # and send the output to the "bp_error_desc" file.

				"${WORKING_DIR}/${script}" 2> bp_error_desc
				EXIT_STATUS=$?
				log_debug "exit status: ${EXIT_STATUS}"

				if [ ${EXIT_STATUS} -ne 0 ]; then
					SCRIPT_NAME=`basename "${script}"`
					build_bp_error_file "${SCRIPT_NAME}" "${EXIT_STATUS}" "`cat ./bp_error_desc | tr '\n' '@'`"
					dump_error_info
					exit ${EXIT_STATUS}
				fi
	            
			fi
		done

	elif [ "${FLOW_TYPE}" = "DOC" ]; then
		echo -e "Doc flow"
	else
		echo -e "Other, error, not supported ... "
	fi

	log_debug "Finished ${PROJ_NAME} project"
	
}