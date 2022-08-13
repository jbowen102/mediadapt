#!/bin/bash

DIR_PATH="$(realpath "${1}")"
SCRIPT_DIR="$(realpath "$(dirname "${0}")")"


if [[ -d "${DIR_PATH}" ]]; then
    if [[ -e "${DIR_PATH}" ]]; then
        :
    else
        echo "Input path ${1} not valid." >&2
        exit 2
    fi
elif [[ -e "${DIR_PATH}" ]]; then
    echo "Input path ${1} not valid. Must be directory, not file." >&2
    exit 2
fi



for file in "${DIR_PATH}"/*; do
    if [[ -d "$file" ]]; then
        :
    else
        printf "\n$file\n"
        ${SCRIPT_DIR}/add_img_src.sh "$file" "${2}"
    fi
done
# https://askubuntu.com/questions/315335/bash-command-for-each-file-in-a-folder
# https://www.cyberciti.biz/faq/bash-loop-over-file/
