#!/bin/bash

# Extract all frames from a given video or GIF w/ optional start and end time
# Works w/ WEBM, MP4, MOV, and GIF input formats (at least)
# Start and end time can either be integers or in "00:00.00" format

if [ $# -ne 1 ]; then
	echo "Expected one argument: vid path." >&2
	exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi


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

# Create "frames" directory to store output
OUTPUT_FOLDER="${FILE_DIR_OG}/frames/"
if [ ! -d "${OUTPUT_FOLDER}" ]; then
	mkdir "${OUTPUT_FOLDER}"
fi

FILEPATH_OUT="${OUTPUT_FOLDER}/${FILENAME_NO_EXT::20}_%05d.jpg"
# https://ngelinux.com/brief-explanation-string-and-array-slicing-in-bash-shell-linux/
# Prepend first 20 characters of input (vid) filename to frame filenames.
# If input file name is shorter than 20 characters, output string will truncate appropriately.
# Append 5-digit serial num.

# Output-file collisions not handled

printf "\nAttempting to extract video frames..."
if [ $# == 1 ]; then # one arg
  # Extract frames from entire vid
  ffmpeg -i "${FILE_PATH}" -qscale:v 2 "${FILEPATH_OUT}" &> /dev/null
  # https://stackoverflow.com/questions/10957412/fastest-way-to-extract-frames-using-ffmpeg
  # https://stackoverflow.com/questions/10225403/how-can-i-extract-a-good-quality-jpeg-image-from-a-video-file-with-ffmpeg/10234065#10234065
  # https://stackoverflow.com/questions/617182/how-can-i-suppress-all-output-from-a-command-using-bash
elif [ $# == 2 ]; then # two args
  # Extract all frames from given timestamp to end.
  ffmpeg -ss ${2} -i "${FILE_PATH}" -qscale:v 2 "${FILEPATH_OUT}" &> /dev/null
elif [ $# == 3 ]; then # three args
  ffmpeg -i "${FILE_PATH}" -qscale:v 2  -ss ${2} -to ${3} "${FILEPATH_OUT}" &> /dev/null
else
  echo "Expected between 1 and 3 arguments (input file and optional timestamps)" >&2
  exit 2
fi

# Test if conversion was successful since ffmpeg output suppressed.
FFMPEG_RETURN=$? # gets return value of last command executed.
if [ ${FFMPEG_RETURN} == 0 ]; then
  FRAME_COUNT=$(find "${OUTPUT_FOLDER}" -maxdepth 1 -type f|wc -l)
  # https://stackoverflow.com/a/11132110
  printf "SUCCESS - ${FRAME_COUNT} frames\n"
else
  printf "FAIL\n"
  exit 1
fi
