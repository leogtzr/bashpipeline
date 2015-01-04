#!/bin/bash
echo -e "[$0]"

ls -larth file_not_found || {
#ls -larth || {
	exit $?
}

exit 0
