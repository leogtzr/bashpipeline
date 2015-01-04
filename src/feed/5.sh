#!/bin/bash
# Test script that finishes incorrectly ... 
ls -larth file_not_found || {
	exit $?
}

exit 0
