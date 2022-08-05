#!/bin/bash

if [[ $# -ne 2 ]]; then
	echo "Expected two arguments: img/vid paths." >&2
	exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi

# Validate input path
FILE_PATH_1="$(realpath "${1}")"
FILE_PATH_2="$(realpath "${2}")"
if [[ -e "${FILE_PATH_1}" ]]; then
	if [[ -d "${FILE_PATH_1}" ]]; then
	  echo "Input path ${1} not valid. Must be file, not directory." >&2
	  exit 2
else
  echo "Input file ${1} cannot be found." >&2
  exit 2
fi
if [[ -e "${FILE_PATH_2}" ]]; then
	elif [[ -d "${FILE_PATH_2}" ]]; then
		echo "Input path ${2} not valid. Must be file, not directory." >&2
		exit 2
	fi
else
  echo "Input file ${2} cannot be found." >&2
  exit 2
fi


SCRIPT_DIR="$(realpath "$(dirname "${0}")")"
python3 <<< "import mediadapt.format_convert as fc ; fc.transfer_exif_comment('${FILE_PATH_1}', '${FILE_PATH_2}')"
# https://unix.stackexchange.com/questions/533156/using-python-in-a-bash-script
PYTHON_RETURN=$? # gets return value of last command executed.

# Make sure the program ran correctly
if [ ${PYTHON_RETURN} -ne 0 ]; then
	printf "\nSomething went wrong when transferring EXIF comment.\n"
	exit 1
fi
