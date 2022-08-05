#!/bin/bash

# Trim a given video (or GIF) according to specified start and (optional) end timestamp.
# Output is in mp4 format.
# If neither timestamp specified, can be used to just convert input vid to mp4 format.
# works w/ WEBM, MP4, MOV, and GIF input formats (at least)

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

NEW_EXT="mp4"
# put timestamps in output filename
if [[ $# == 1 ]]; then
  FILEPATH_OUT="${FILEPATH_NO_EXT}.${NEW_EXT}"
elif [[ $# == 2 ]]; then
  FILEPATH_OUT="${FILEPATH_NO_EXT}_${2}s-.${NEW_EXT}"
elif [[ $# == 3 ]]; then
  FILEPATH_OUT="${FILEPATH_NO_EXT}_${2}-${3}s.${NEW_EXT}"
else
  echo "Expected between 1 and 3 arguments (input file and optional timestamps)" >&2
  exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi

# Validate input path
if [[ -e "${FILE_PATH}" ]]; then
  if [[ -d "${FILE_PATH}" ]]; then
	  echo "Input path ${1} not valid. Must be file, not directory." >&2
	  exit 2
	fi
else
  echo "Input file ${1} cannot be found." >&2
  exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi


# Check for existence of output file before attempting conversion.
# ffmpeg has this check, but it requires the rest of the verbose output
# (which is suppressed below)
# Check for both resolvable path and broken symlink # https://unix.stackexchange.com/a/550837
if [[ ${FILE_PATH} == ${FILEPATH_OUT} ]]; then # trivial case of mp4 input file w/ no timestamps passed.
  echo "\nOutput file cannot have same name as input file." >&2
  exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
elif [[ -e "${FILEPATH_OUT}" ]] || [[ -h "${FILEPATH_OUT}" ]]; then
  printf "\nTarget file $(basename ${FILEPATH_OUT})  exists. Overwrite? [Y/N]\n"
  read -p ">" answer
  if [ "${answer}" == "y" -o "${answer}" == "Y" ]; then
    rm "${FILEPATH_OUT}"
  else
    printf "Exiting\n"
    exit 1
  fi
fi


printf "\nAttempting to trim/convert..."
if [[ $# == 1 ]]; then # one arg
  # The utility of this case is a simple format conversion to mp4
  ffmpeg -i "${FILE_PATH}" -movflags +faststart \
            "${FILEPATH_OUT}" &> /dev/null
  # https://stackoverflow.com/questions/617182/how-can-i-suppress-all-output-from-a-command-using-bash
elif [[ $# == 2 ]]; then # two args
  ffmpeg -ss ${2} -i "${FILE_PATH}" -movflags +faststart \
                     "${FILEPATH_OUT}" &> /dev/null
elif [[ $# == 3 ]]; then # three args
  ffmpeg -ss ${2} -to ${3} -i "${FILE_PATH}" -movflags +faststart \
                              "${FILEPATH_OUT}" &> /dev/null
fi
# https://stackoverflow.com/questions/25569180/ffmpeg-convert-without-loss-quality

# Test if conversion was successful since ffmpeg output suppressed.
FFMPEG_RETURN=$? # gets return value of last command executed.
if [ ${FFMPEG_RETURN} == 0 ]; then
  # transcribe EXIF comment, if present
  "${SCRIPT_DIR}"/transfer_exif_comment "${FILE_PATH}" "${FILEPATH_OUT}" &> /dev/null
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
