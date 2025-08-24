#!/bin/bash

# Convert a given CR2 raw photo (from Canon DSLR) to a jpg

if [ $# -lt 1 ]; then
  echo "Expected one argument (CR2 image to convert)" >&2
  exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi


SCRIPT_DIR="$(realpath "$(dirname "${0}")")"
FILE_PATH="$(realpath "${1}")"
# https://code-maven.com/bash-absolute-path

# Validate input path
if [ -e "${FILE_PATH}" ]; then
  if [ -d "${FILE_PATH}" ]; then
    echo "Input path ${1} not valid. Must be file, not directory." >&2
    exit 2
  fi
else
  echo "Input file ${1} cannot be found." >&2
  exit 2
fi

FILEPATH_NO_EXT="${FILE_PATH%.*}"
EXT="${FILE_PATH##*.}"
FILENAME=$(basename "${FILE_PATH}") # includes extension
NEW_EXT="jpg"
FILEPATH_OUT="${FILEPATH_NO_EXT}.${NEW_EXT}"

if [ "${EXT}" != "CR2" ]; then
  printf "${FILENAME} not a CR2 file. Left alone.\n"
  exit 0
fi

# Check for existence of output file before attempting conversion.
# Check for both resolvable path and broken symlink # https://unix.stackexchange.com/a/550837
if [ -e "${FILEPATH_OUT}" ] || [ -h "${FILEPATH_OUT}" ]; then
  printf "\nTarget file $(basename ${FILEPATH_OUT}) exists. Overwrite? [Y/N]\n"
  read -p ">" answer
  if [ "${answer}" == "y" -o "${answer}" == "Y" ];   then
    rm "${FILEPATH_OUT}"
  else
    printf "Exiting\n"
    exit 1
  fi
fi

printf "Attempting to convert ${FILENAME} to ${NEW_EXT}..."
dcraw -c "${FILE_PATH}" | ppmtojpeg > "${FILEPATH_OUT}"
RC=$?
if [ ${RC} == 0 ]; then
  printf "SUCCESS\n"
else
  printf "FAIL\n"
  exit 1
fi
