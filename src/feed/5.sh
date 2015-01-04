#!/bin/bash
echo -e "[$0]"

ls -larth file_not_found || {
	exit $?
}

exit 0