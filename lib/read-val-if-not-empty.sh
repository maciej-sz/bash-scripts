#!/usr/bin/env bash

. "$(dirname ${BASH_SOURCE[0]})/read-val.sh"

function readValIfNotEmpty() {
    MSG=$1
    VAL=$2
    DEFAULT=$3

    if [[ "" == "${VAL}" ]]; then
        VAL=$(readVal "${MSG}" "${DEFAULT}")
    fi

    echo ${VAL}
}