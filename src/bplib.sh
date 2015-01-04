# bash pipeline general functions. 

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
	BP_ERROR_CONTENT
}

dump_error_info() {
	(
		. bp.error
		echo -e "\nFAILED_SCRIPT - ${FAILED_SCRIPT}"
		echo -e "EXIT_CODE - ${EXIT_CODE}"
		echo -e "ERROR_MSG - ${ERROR_MSG}" | tr '@' '\n'
		rm bp.error
	)
}

# Punto inicial del programa ... 
# Inicia la ejecución de los scripts dentro del directorio
# WORKING_DIR.

# Si alguno de los script dentro del directorio WORKING_DIR falla
# todo el proceso se detiene. 
# Cuando el error ha sido corregido, se puede utilizar el script
# bp_continue.sh para continuar la ejecución del proceso:
# bp_continue.sh 5.sh
start_scripts() {
	
	log_debug "Beginning ${PROJ_NAME} project"

	for script in `seq -f "%g.sh" ${START_POINT} 10`; do
		if [ -f "${WORKING_DIR}/${script}" ]; then
			log_debug "Running: $script  SCRIPT"

            # Execute sequentials scripts within the WORKING_DIR
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

	log_debug "Finished ${PROJ_NAME} project"
	
}