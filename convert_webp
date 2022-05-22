#!/bin/bash


# Read in WEBP2GIF_DIR variable
source "$(realpath "$(dirname "${0}")")/dir_names.sh" # brings in WEBP2GIF_DIR
# https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel

if [[ $# -ne 1 ]]; then
	echo "Expected one argument: img path." >&2
	exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi

STARTING_DIR="${PWD}"
FILE_PATH="$(realpath "${1}")"
# https://code-maven.com/bash-absolute-path

# Validate input path
if [[ -e "${FILE_PATH}" ]]; then
  if [[ -d "${FILE_PATH}" ]]; then
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
# FILENAME_NO_EXT=$(basename $(basename ${FILE_PATH} .webp) .WEBP) # handles either ext
FILENAME_NO_EXT=$(basename "${FILE_PATH}" "."${EXT})
# https://unix.stackexchange.com/questions/313017/bash-function-splitting-name-and-extension-of-a-file
# https://linuxhandbook.com/basename/
FILE_DIR_OG="$(realpath "$(dirname "${FILE_PATH}")")"
# https://linuxhandbook.com/dirname/
FILENAME_GIF="${FILENAME_NO_EXT}.gif"

# Check for existence of output file before attempting conversion.
# Check for both resolvable path and broken symlink # https://unix.stackexchange.com/a/550837
FILEPATH_GIF_TARGET="${FILE_DIR_OG}/${FILENAME_GIF}"
if [[ -e "${FILEPATH_GIF_TARGET}" ]] || [[ -h "${FILEPATH_GIF_TARGET}" ]]; then
  printf "\nTarget file $(basename ${FILEPATH_GIF_TARGET}) exists. Overwrite? [Y/N]\n"
  read -p ">" answer
  if [ "${answer}" == "y" -o "${answer}" == "Y" ];   then
    rm "${FILEPATH_GIF_TARGET}"
  else
    printf "Exiting\n"
    exit 1
  fi
fi


# Try using webp2gif first. Will fail if static img
cp "${FILE_PATH}" "${WEBP2GIF_DIR}"
cd "${WEBP2GIF_DIR}"
printf "\nAttempting to convert to animated gif..."
./webp2gif "${FILENAME}" "${FILENAME_GIF}" &> /dev/null
# https://stackoverflow.com/questions/617182/how-can-i-suppress-all-output-from-a-command-using-bash
WEBP2GIF_RETURN=$? # gets return value of last command executed.

# If webp2gif conversion failed, assume it's a static image.
if [ ${WEBP2GIF_RETURN} == 0 ]; then
  printf "SUCCESS\n"
  mv "${FILENAME_GIF}" "${FILE_DIR_OG}" # overwrites any existing file w/ same name and ext.
else
  NEW_EXT="jpg"
  printf "FAIL\nAttempting to convert as static img..."
  FILEPATH_JPG="${FILEPATH_NO_EXT}.${NEW_EXT}"
  convert "${FILE_PATH}" "${FILEPATH_JPG}" &> /dev/null
  CONVERT_RETURN=$? # gets return value of last command executed.
  if [ ${CONVERT_RETURN} == 0 ]; then
    printf "SUCCESS\n"
  else
    printf "Static conversion failed too!\n"
    exit 1
  fi
fi

# Both cases fall through to clean up wep2gif dir.
rm "${FILENAME}"
cd "${STARTING_DIR}" # Back to original working dir.


# Alternate method for differentiating animation from static:
# # Look for "Animation Loop Count" in the EXIF data.
# exiftool ${FILE_PATH} | grep "Animation Loop Count"
# ANIM_PRESET=$? # gets return value of last command executed.
# # If string not present, assume it's a static image.
# if [ ${WEBP2GIF_RETURN} -ne 0 ]
