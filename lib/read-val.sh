#!/usr/bin/env bash

function readVal() {
    MSG=$1
    DEFAULT=$2

    if [[ "" != "${DEFAULT}" ]]; then MSG="${MSG} (default: ${DEFAULT})"; fi

    while true; do
        read -p "${MSG}: " VAL
        if [[ "" != "${VAL}" ]]; then
            break
        elif [[ "" != "${DEFAULT}" ]]; then
            VAL=${DEFAULT}
            break
        fi
    done
    echo ${VAL}
}