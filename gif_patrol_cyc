#!/bin/bash

# Convert a given gif or video w/ optional start and end time to a "patrol cycle"
# gif that loops back and forth.
# Works w/ GIF, WEBM, MP4, MOV input formats (at least)
# Start and end time can either be integers or in "00:00.00" format

if [[ $# -ne 1 ]]; then
	echo "Expected one argument: gif/vid path." >&2
	exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi


STARTING_DIR="${PWD}"
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


NEW_EXT="gif"
# put timestamps in output filename
if [[ $# == 1 ]]; then
  FILEPATH_OUT="${FILEPATH_NO_EXT}_pcyc.${NEW_EXT}"
elif [[ $# == 2 ]]; then
  FILEPATH_OUT="${FILEPATH_NO_EXT}_${2}s-_pcyc.${NEW_EXT}"
elif [[ $# == 3 ]]; then
  FILEPATH_OUT="${FILEPATH_NO_EXT}_${2}-${3}s_pcyc.${NEW_EXT}"
else
  echo "Expected between 1 and 3 arguments (input file and optional timestamps)" >&2
  exit 2
fi

# Check for existence of output file before attempting conversion.
# ffmpeg has this check, but it requires the rest of the verbose output
# (which is suppressed below)
# Check for both resolvable path and broken symlink # https://unix.stackexchange.com/a/550837
if [[ -e "${FILEPATH_OUT}" ]] || [[ -h "${FILEPATH_OUT}" ]]; then
  printf "\nTarget file $(basename "${FILEPATH_OUT}") exists. Overwrite? [Y/N]\n"
  read -p ">" answer
  if [ "${answer}" == "y" -o "${answer}" == "Y" ]; then
    rm "${FILEPATH_OUT}"
  else
    printf "Exiting\n"
    exit 1
  fi
fi

# Create temp directory to store output
TEMP_FOLDER="${FILE_DIR_OG}/gif_temp/"
if [ -d "${TEMP_FOLDER}" ]; then
	: # do nothing
else
	mkdir "${TEMP_FOLDER}"
fi

# Copy original file into temp folder
cp "${FILE_PATH}" "${TEMP_FOLDER}"
TEMP_PATH="${TEMP_FOLDER}/${FILENAME}"
TEMP_PATH_NOEXT="${TEMP_FOLDER}/${FILENAME_NO_EXT}"

# Collisions in temp files not handled

if [[ $# == 1 ]]; then # one arg
  # If not already a gif, convert to gif first. Case-insensitive comparison:
  if [[ "${EXT,,}" == "${NEW_EXT,,}" ]]; then # https://stackoverflow.com/a/27679748
    printf "\nAttempting to create patrol-cycle gif..."

    convert "${FILE_PATH}" -coalesce -duplicate 1,-2-1 -quiet \
    -layers OptimizePlus -loop 0 "${FILEPATH_OUT}" &> /dev/null
  else
    INTER_GIF_PATH="${TEMP_PATH%.*}.${NEW_EXT}"
    if [[ -e "${INTER_GIF_PATH}" ]]; then
      rm "${INTER_GIF_PATH}"
    fi

    printf "\nAttempting to convert/trim to gif format..."
    "${SCRIPT_DIR}"/convert_vid_to_gif "${TEMP_PATH}" &> /dev/null
    GIF_CONVERT_RETURN=$? # gets return value of last command executed.
    if [ ${GIF_CONVERT_RETURN} == 0 ]; then
      printf "SUCCESS\nAttempting to create patrol-cycle gif..."

      convert "${INTER_GIF_PATH}" -coalesce -duplicate 1,-2-1 -quiet \
      -layers OptimizePlus -loop 0 "${FILEPATH_OUT}" &> /dev/null
      # https://askubuntu.com/a/1107473
      # Delete intermediary gif.
      # rm "${INTER_GIF_PATH}"
    else
      printf "FAIL\nConversion to GIF format failed.\n"
      exit 1
    fi
  fi

elif [[ $# == 2 ]]; then # two args
  # If not already a gif, convert to gif first. Case-insensitive comparison:
  if [[ "${EXT,,}" == "${NEW_EXT,,}" ]]; then # https://stackoverflow.com/a/27679748
    INTER_GIF_PATH="${TEMP_PATH_NOEXT}_${2}s-.gif"
    if [[ -e "${INTER_GIF_PATH}" ]]; then
      rm "${INTER_GIF_PATH}"
    fi

    printf "\nAttempting to trim..."
    "${SCRIPT_DIR}"/trim_only "${TEMP_PATH}" ${2} &> /dev/null
    TRIM_RETURN=$? # gets return value of last command executed.
    if [ ${TRIM_RETURN} == 0 ]; then
      printf "SUCCESS\nAttempting to create patrol-cycle gif..."

      convert "${INTER_GIF_PATH}" -coalesce -duplicate 1,-2-1 -quiet \
      -layers OptimizePlus -loop 0 "${FILEPATH_OUT}" &> /dev/null
      # rm "${INTER_GIF_PATH}"
    else
      printf "FAIL\nTrim operation unsuccessful.\n"
      exit 1
    fi
  else
    INTER_GIF_PATH="${TEMP_PATH_NOEXT}_${2}s-.gif"
    if [[ -e "${INTER_GIF_PATH}" ]]; then
      rm "${INTER_GIF_PATH}"
    fi

    printf "\nAttempting to convert/trim to gif format..."
    "${SCRIPT_DIR}"/convert_vid_to_gif "${TEMP_PATH}" ${2} &> /dev/null
    GIF_CONVERT_RETURN=$? # gets return value of last command executed.
    if [ ${GIF_CONVERT_RETURN} == 0 ]; then
      printf "SUCCESS\nAttempting to create patrol-cycle gif..."

      convert "${INTER_GIF_PATH}" -coalesce -duplicate 1,-2-1 -quiet \
      -layers OptimizePlus -loop 0 "${FILEPATH_OUT}" &> /dev/null
      # rm "${INTER_GIF_PATH}"
    else
      printf "FAIL\nConversion to GIF format unsuccessful.\n"
      exit 1
    fi
  fi
elif [[ $# == 3 ]]; then # three args
  # If not already a gif, convert to gif first. Case-insensitive comparison:
  if [[ "${EXT,,}" == "${NEW_EXT,,}" ]]; then # https://stackoverflow.com/a/27679748
    INTER_GIF_PATH="${TEMP_PATH_NOEXT}_${2}-${3}s.gif"
    if [[ -e "${INTER_GIF_PATH}" ]]; then
      rm "${INTER_GIF_PATH}"
    fi

    printf "\nAttempting to trim..."
    "${SCRIPT_DIR}"/trim_only "${TEMP_PATH}" ${2} ${3} &> /dev/null
    TRIM_RETURN=$? # gets return value of last command executed.
    if [ ${TRIM_RETURN} == 0 ]; then
      printf "SUCCESS\nAttempting to create patrol-cycle gif..."

      convert "${INTER_GIF_PATH}" -coalesce -duplicate 1,-2-1 -quiet \
      -layers OptimizePlus -loop 0 "${FILEPATH_OUT}" &> /dev/null
      # rm "${INTER_GIF_PATH}"
    else
      printf "FAIL\nTrim operation unsuccessful.\n"
      exit 1
    fi
  else
    INTER_GIF_PATH="${TEMP_PATH_NOEXT}_${2}-${3}s.gif"
    if [[ -e "${INTER_GIF_PATH}" ]]; then
      rm "${INTER_GIF_PATH}"
    fi

    # trim and convert to gif at once
    printf "\nAttempting to convert/trim to gif format..."
    "${SCRIPT_DIR}"/convert_vid_to_gif "${TEMP_PATH}" ${2} ${3} &> /dev/null
    GIF_CONVERT_RETURN=$? # gets return value of last command executed.
    if [ ${GIF_CONVERT_RETURN} == 0 ]; then
      printf "SUCCESS\nAttempting to create patrol-cycle gif..."

      convert "${INTER_GIF_PATH}" -coalesce -duplicate 1,-2-1 -quiet \
      -layers OptimizePlus -loop 0 "${FILEPATH_OUT}" &> /dev/null
      # rm "${INTER_GIF_PATH}"
    else
      printf "FAIL\nConversion to GIF format unsuccessful.\n"
      exit 1
    fi
  fi
fi

# Test if conversion was successful since ffmpeg output suppressed.
PATROL_CYC_RETURN=$? # gets return value of last command executed.
if [ ${PATROL_CYC_RETURN} == 0 ]; then
  # transcribe EXIF comment, if present
  "${SCRIPT_DIR}"/transfer_exif_comment "${FILE_PATH}" "${FILEPATH_OUT}" &> /dev/null
  COMMENT_RETURN=$? # gets return value of last command executed.
  if [ ${COMMENT_RETURN} == 0 ]; then
    printf "SUCCESS\n"
  else
    printf "FAIL\nEXIF-comment transfer unsuccessful.\n"
    exit 1
  fi
  # Open gif so user can confirm valid output file.
  # nemo "${TEMP_FOLDER}" # this is throwing error messages now for some reason.
  # https://askubuntu.com/questions/1157832/cannot-start-nemo-if-udisks2-is-disabled
  # Seems to fail only when folder is on a different drive than ~
  # sleep 1
	xdg-open 2>/dev/null "${FILEPATH_OUT}"
  # Prompt user to check/clear temp folder if desired
  read -p "Notice: temp folder ${TEMP_FOLDER} populated. Press Enter to continue."
  # read -p ">" answer # input not used
else
  printf "FAIL\n"
  exit 1
fi
