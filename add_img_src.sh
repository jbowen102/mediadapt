#!/bin/bash

source ~/.bash_aliases

# pass img path as first arg
# pass img source URL as second arg

SCRIPT_DIR="$(realpath "$(dirname "${0}")")"
FILE_PATH="$(realpath "${1}")"
# https://code-maven.com/bash-absolute-path

if [[ $# -ne 2 ]]; then
	echo "Need to pass in two arguments: img path and img source URL to embed." >&2
	exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi


# Validate input path
FILE_PATH="$(realpath "${1}")"
if [[ -e "${FILE_PATH}" ]]; then
  if [[ -d "${FILE_PATH}" ]]; then
	  echo "Input path ${1} not valid. Must be file, not directory." >&2
	  exit 2
	fi
else
  echo "Input file ${1} cannot be found." >&2
  exit 2
fi

EXT="${FILE_PATH##*.}"
FILENAME=$(basename "${FILE_PATH}") # includes extension
WEBP_EXT="WEBP"

# If image is in webp format, have to convert first
if [[ "${EXT,,}" == "${WEBP_EXT,,}" ]]; then # https://stackoverflow.com/a/27679748
	# pull in bash aliases
	# source "$(realpath ~/.bash_aliases)"
	# ${BASH_ALIASES[convert_webp]} "${FILE_PATH}" # https://askubuntu.com/a/631108
	${SCRIPT_DIR}/convert_webp "${FILE_PATH}"
	CONVERT_RETURN=$?
	if [[ ${CONVERT_RETURN} -ne 0 ]]; then
		printf "\nCall to convert_webp failed.\n"
		exit 1
	fi
	FILEPATH_NO_EXT="${FILE_PATH%.*}"
	# Don't know if it will be a static or animated image yet.
	FILEPATH_GIF="${FILEPATH_NO_EXT}.gif"
	FILEPATH_JPG="${FILEPATH_NO_EXT}.jpg"
	if [[ -e "${FILEPATH_GIF}" ]] && [[ -e "${FILEPATH_JPG}" ]]; then
		# can't ID which one is the new one
		printf "\nBoth .gif and .jpg versions of ${FILENAME} input file exist in target dir.\n"
		exit 1
	elif [[ -e "${FILEPATH_GIF}" ]]; then
		FILEPATH_OUT="${FILEPATH_GIF}"
	elif [[ -e "${FILEPATH_JPG}" ]]; then
		FILEPATH_OUT="${FILEPATH_JPG}"
	else
		printf "\nCan't find either .gif and .jpg version of ${FILENAME} input file in target dir.\n"
		exit 1
	fi
else
	FILEPATH_OUT="${FILE_PATH}"
fi

# Print current comment in case one already exists
echo "Before update:"
tput setaf 1
${BASH_ALIASES[exiftool]} -Comment "${FILEPATH_OUT}"
tput setaf 7
# https://stackoverflow.com/questions/2437976/get-color-output-in-bash

# Write URL into the EXIF comment
printf "\nAttempting to write EXIF comment..."
${BASH_ALIASES[exiftool]} -Comment="Source: ${2}" "${FILEPATH_OUT}"

EXIF_RETURN=$?
if [[ ${EXIF_RETURN} == 0 ]]; then
	printf "SUCCESS\n"
	# Print new comment to confirm it was stored correctly.
	${BASH_ALIASES[exiftool]} -Comment "${FILEPATH_OUT}"

	OG_BU_PATH="${FILEPATH_OUT}_original"
	if [[ -f "${OG_BU_PATH}" ]]; 	then
		# Prompt user to delete exiftool's _original auto-gen file
		# xdg-open 2>/dev/null "${FILEPATH_OUT}"
		# printf "\nAccept new file and delete original (Y or N)?\n"
		# read -p ">" answer
		# if [ "${answer}" == "y" -o "${answer}" == "Y" ]; then
		# 	rm "${OG_BU_PATH}"
		# fi
		rm "${OG_BU_PATH}"
	else
		printf "FAIL\nCan't find '_original' file.\n"
		exit 1
	fi
else
	printf "FAIL\nCall to exiftool unsuccessful.\n"
	exit 1
fi

# https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
