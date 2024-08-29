#!/bin/bash

# Trim a given video (or GIF) according to specified start and (optional) end timestamp.
# Output is in source format.
# Works w/ WEBM, MP4, MOV, and GIF input formats (at least)
# Start and end time can either be integers or in "00:00.00" format
SCRIPT_DIR="$(realpath "$(dirname "${0}")")"
FILE_PATH="$(realpath "${1}")"
# https://code-maven.com/bash-absolute-path
FILEPATH_NO_EXT="${FILE_PATH%.*}"
EXT="${FILE_PATH##*.}"
FILENAME=$(basename "${FILE_PATH}") # includes extension

FILENAME_NO_EXT=$(basename "${FILE_PATH}" "."${EXT})
# https://unix.stackexchange.com/questions/313017/bash-function-splitting-name-and-extension-of-a-file
# https://linuxhandbook.com/basename/
FILE_DIR_OG="$(realpath "$(dirname "${FILE_PATH}")")"
# https://linuxhandbook.com/dirname/

NEW_EXT="${EXT,,}" # convert to lowercase for caller functions to correctly predict naming # https://stackoverflow.com/a/2264537
# put timestamps in output filename
if [ $# == 2 ]; then
  FILEPATH_OUT="${FILEPATH_NO_EXT}_${2}s-.${NEW_EXT}"
elif [ $# == 3 ]; then
  FILEPATH_OUT="${FILEPATH_NO_EXT}_${2}-${3}s.${NEW_EXT}"
else
  echo "Expected between 2 and 3 arguments (input file, start timestamp, and optional end timestamp)" >&2
  exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi

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


# Check for existence of output file before attempting trim.
# ffmpeg has this check, but it requires the rest of the verbose output
# (which is suppressed below)
# Check for both resolvable path and broken symlink # https://unix.stackexchange.com/a/550837
if [ -e "${FILEPATH_OUT}" ] || [ -h "${FILEPATH_OUT}" ]; then
  printf "\nTarget file $(basename "${FILEPATH_OUT}") exists. Overwrite? [Y/N]\n"
  read -p ">" answer
  if [ "${answer}" == "y" -o "${answer}" == "Y" ]; then
    rm "${FILEPATH_OUT}"
  else
    printf "Exiting\n"
    exit 1
  fi
fi


printf "\nAttempting to trim..."
if [[ $# == 2 ]]; # two args
then
  ffmpeg -ss ${2} -i "${FILE_PATH}" "${FILEPATH_OUT}" &> /dev/null
elif [[ $# == 3 ]]; # three args
then
  ffmpeg -i "${FILE_PATH}" -ss ${2} -to ${3} "${FILEPATH_OUT}" &> /dev/null
fi

# Test if conversion was successful since ffmpeg output suppressed.
FFMPEG_RETURN=$? # gets return value of last command executed.
if [ ${FFMPEG_RETURN} == 0 ]; then
  # transcribe EXIF comment, if present
  "${SCRIPT_DIR}"/transfer_exif_comment.sh "${FILE_PATH}" "${FILEPATH_OUT}" &> /dev/null
  COMMENT_RETURN=$? # gets return value of last command executed.
  if [ ${COMMENT_RETURN} == 0 ]; then
    printf "SUCCESS\n"
  else
    printf "FAIL\nEXIF-comment transfer unsuccessful.\n"
    exit 1
  fi
else
  printf "FAIL\n"
  exit 1
fi
