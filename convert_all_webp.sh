#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Expected one argument - directory path." >&2
  exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi


# Validate input path
FILE_PATH="$(realpath "${1}")"
if [ -e "${FILE_PATH}" ]; then
  if [ -d "${FILE_PATH}" ]; then
    :
  else
    echo "Input path ${1} not valid. Must be directory." >&2
    exit 2
  fi
else
  echo "Invalid path specified." >&2
  exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi


SCRIPT_DIR="$(realpath "$(dirname "${0}")")"
python3 <<< "import mediadapt.format_convert as fc ; fc.convert_all_webx('$FILE_PATH', webx_type='webp')"
# https://unix.stackexchange.com/questions/533156/using-python-in-a-bash-script
PYTHON_RETURN=$? # gets return value of last command executed.

# Make sure the program ran correctly
if [ ${PYTHON_RETURN} -ne 0 ]; then
	printf "\nSomething went wrong with the Python call.\n"
	exit 1
fi
