#!/bin/bash

. bp_flow.env 2> /dev/null || {
	echo -e "\n[ERROR] bp_flow.env file not found.\n"
	exit 68
}

if [ $# -ne 1 ]; then
	echo -e "ERROR, please enter an initial script argument."
	exit 81
fi

if [ ! -f "bp.error" ]; then
	echo -e "Nothing to do ... "
	exit 0
else

	# Load lib:
	if [ -f ./bplib.sh ]; then
		. ./bplib.sh
	else
		echo -e "[`date '+%F %T'`] [ERROR] bplib.sh NOT found."
		exit 76
	fi

	SCRIPT_TO_START=$1
	awk -F '=' '/^FAILED_SCRIPT/ {print $2}' bp.error | grep -Eq "^${SCRIPT_TO_START}$" && {
		
		START_POINT=`awk -F '=' '/^FAILED_SCRIPT/ {print $2}' bp.error | cut -f1 -d'.'`

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

		rm -vf "./bp.error"
		exit 0

	} || {
		echo -e "\n\tThe script to continue does not match the: "
		awk -F "=" '/^FAILED_SCRIPT/ {print $0}' bp.error
		echo -e "\tline in the bp.error file.\n"
	}
	exit 73
fi

exit 0