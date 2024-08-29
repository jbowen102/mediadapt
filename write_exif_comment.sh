#!/bin/bash


if [ $# -ne 2 ]; then
  echo "Expected two arguments - filename and comment to add" >&2
  exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi


FILE_PATH="$(realpath "${1}")"
COMMENT="${2}"
# Validate input path
if [ -e "${FILE_PATH}" ]; then
  if [ -d "${FILE_PATH}" ]; then
	  echo "Input path ${1} not valid. Must be file, not directory." >&2
	  exit 2
	fi
else
  echo "Input file ${1} cannot be found." >&2
  exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi

# Does not check for existence of a comment first
printf "\nAttempting to write EXIF comment..."
exiftool -Comment="${COMMENT}" "${FILE_PATH}" &> /dev/null
EXIF_RETURN=$?
OG_BU_PATH="${FILE_PATH}_original"

if [ ${EXIF_RETURN} == 0 ]; then
	if [ -f "${OG_BU_PATH}" ]; then
		rm "${OG_BU_PATH}"
		printf "SUCCESS\n"
	else
		printf "FAIL\nCan't find '_original' file.\n"
		exit 1
	fi
else
	printf "FAIL\nCall to exiftool unsuccessful.\n"
	exit 1
fi
