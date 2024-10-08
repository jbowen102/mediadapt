#!/bin/bash

# Convert a given video to a gif w/ optional start and end time
# Works w/ WEBM, MP4, and MOV input formats (at least)
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

NEW_EXT="gif"
# put timestamps in output filename
if [ $# == 1 ]; then
  FILEPATH_OUT="${FILEPATH_NO_EXT}.${NEW_EXT}"
elif [ $# == 2 ]; then
  FILEPATH_OUT="${FILEPATH_NO_EXT}_${2}s-.${NEW_EXT}"
elif [ $# == 3 ]; then
  FILEPATH_OUT="${FILEPATH_NO_EXT}_${2}-${3}s.${NEW_EXT}"
else
  echo "Expected between 1 and 3 arguments (input file and optional timestamps)" >&2
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
fi

# Check for existence of output file before attempting conversion.
# ffmpeg has this check, but it requires the rest of the verbose output
# (which is suppressed below)
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

printf "\nAttempting to convert to gif..."
if [ $# == 1 ]; then # one arg
  ### high quality/size:
  # ffmpeg -i "${FILE_PATH}" \
  # -vf "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  # -loop 0 "${FILEPATH_OUT}" &> /dev/null
  ### medium quality/size:
  ffmpeg -i "${FILE_PATH}" \
  -loop 0 "${FILEPATH_OUT}" &> /dev/null
  ### low quality/size:
  # ffmpeg -i "${FILE_PATH}" \
  # -vf "fps=10,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  # -loop 0 "${FILEPATH_OUT}" &> /dev/null
  # https://superuser.com/questions/556029/how-do-i-convert-a-video-to-gif-using-ffmpeg-with-reasonable-quality
  # https://www.ubuntubuzz.com/2017/08/convert-mp4-webm-video-to-gif-using-ffmpeg.html
elif [ $# == 2 ]; then # two args
  ### high quality/size:
  # ffmpeg -i "${FILE_PATH}" \
  # -vf "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  # -loop 0 -ss ${2} "${FILEPATH_OUT}" &> /dev/null
  ## medium quality/size:
  ffmpeg -i "${FILE_PATH}" \
  -loop 0 -ss ${2} "${FILEPATH_OUT}" &> /dev/null
  ### low quality/size:
  # ffmpeg -i "${FILE_PATH}" \
  # -vf "fps=10,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  # -loop 0 -ss ${2} "${FILEPATH_OUT}" &> /dev/null
elif [ $# == 3 ]; then # three args
  ### high quality/size:
  # ffmpeg -i "${FILE_PATH}" \
  # -vf "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  # -loop 0 -ss ${2} -to ${3} "${FILEPATH_OUT}" &> /dev/null
  ### medium quality/size:
  ffmpeg -i "${FILE_PATH}" \
  -loop 0 -ss ${2} -to ${3} "${FILEPATH_OUT}" &> /dev/null
  ### low quality/size:
  # ffmpeg -i "${FILE_PATH}" \
  # -vf "fps=10,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  # -loop 0 -ss ${2} -to ${3} "${FILEPATH_OUT}" &> /dev/null
fi

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
  # Open gif so user can confirm valid output file.
  sleep 1
  xdg-open 2>/dev/null "${FILEPATH_OUT}"
else
  printf "FAIL\n"
  exit 1
fi
