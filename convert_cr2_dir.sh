#!/bin/bash


if [ $# -lt 1 ]; then
  echo "Expected one argument (dir containing CR2 images to convert)" >&2
  exit 2
  # https://stackoverflow.com/questions/18568706/check-number-of-arguments-passed-to-a-bash-script
fi

DIR_PATH="$(realpath "${1}")"
SCRIPT_DIR="$(realpath "$(dirname "${0}")")"


if [ -d "${DIR_PATH}" ]; then
    if [ ! -e "${DIR_PATH}" ]; then
        echo "Input path ${1} not valid." >&2
        exit 2
    fi
elif [ -e "${DIR_PATH}" ]; then
    echo "Input path ${1} not valid. Must be directory, not file." >&2
    exit 2
fi


for file in "$DIR_PATH"/*; do
    if [ ! -d "$file" ]; then
        ${SCRIPT_DIR}/convert_cr2.sh "$file"
    fi
done
# https://askubuntu.com/questions/315335/bash-command-for-each-file-in-a-folder
# https://www.cyberciti.biz/faq/bash-loop-over-file/
