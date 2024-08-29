#!/bin/bash

SCRIPT_DIR="$(realpath "$(dirname "${0}")")"


if [ $# -lt 2 ]; then
  echo "Expected at least two arguments (vid filenames)" >&2
  exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi


# Validate all input paths passed
# https://stackoverflow.com/a/255913
for VAR in "$@"
do
  FILE_PATH="$(realpath "${VAR}")"
  if [ -e "${FILE_PATH}" ]; then
    if [ -d "${FILE_PATH}" ]; then
      echo "Input path ${VAR} not valid. Must be file, not directory." >&2
      exit 2
    fi
  else
    echo "Input file ${VAR} cannot be found." >&2
    exit 2
  fi
done

# Create file to store input-vid list
# Created in directory of first input file
FILE_1_DIR="$(realpath "$(dirname "${1}")")"
LIST_FILE="${FILE_1_DIR}/input_vid_list.txt"
# Make sure it doesn't exist already
if [ -e "${LIST_FILE}" ] || [ -h "${LIST_FILE}" ]; then
  printf "\nTarget file $(basename "${LIST_FILE}") exists in ${FILE_1_DIR}. Overwrite? [Y/N]\n"
  read -p ">" answer
  if [ "${answer}" == "y" -o "${answer}" == "Y" ]; then
    rm "${LIST_FILE}"
  else
    printf "Exiting\n"
    exit 1
  fi
fi

printf "\nEnter new filename (no extension) for combined video (or nothing for default)\n"
read -p ">" OUTPUT_NAME
if [ "${OUTPUT_NAME}" == "" ]; then
  # default to modification of first input file's name
  FILENAME_1="$(basename "${1}")"
  FILENAME_1_NO_EXT="${FILENAME_1%.*}"
  OUTPUT_NAME="${FILENAME_1_NO_EXT}_concat"
fi

OUTPUT_FILEPATH="${FILE_1_DIR}/${OUTPUT_NAME}.mp4"

# Check for existence of output file before attempting conversion.
# Check for both resolvable path and broken symlink # https://unix.stackexchange.com/a/550837
if [ -e "${OUTPUT_FILEPATH}" ] || [ -h "${OUTPUT_FILEPATH}" ]; then
  printf "\nTarget file $(basename "${OUTPUT_FILEPATH}") exists. Overwrite? [Y/N]\n"
  read -p ">" answer
  if [ "${answer}" == "y" -o "${answer}" == "Y" ]; then
    rm "${OUTPUT_FILEPATH}"
  else
    printf "Exiting\n"
    exit 1
  fi
fi

# Loop through again and create list file now that all paths are validated.
for VAR in "$@"
do
  FILENAME="$(basename "${VAR}")"
  echo "file '""${FILENAME}""'" >> "${LIST_FILE}"
done

printf "\nAttempting to concatenate videos..."
ffmpeg -f concat -safe 0 -i "${LIST_FILE}" -c copy "${OUTPUT_FILEPATH}" &> /dev/null
# https://stackoverflow.com/a/11175851

CONCAT_RETURN=$?
if [ ${CONCAT_RETURN} == 0 ]; then
	if [ -f "${LIST_FILE}" ]; then
    # Remove temporary file containing list of input videos.
		rm "${LIST_FILE}"
		printf "SUCCESS\n"
	else
		printf "FAIL\nCan't find list file to delete.\n"
		exit 1
	fi
else
	printf "FAIL\nConcatenation unsuccessful.\n"
	exit 1
fi
