#!/usr/bin/env bash

function configFileUpdate() {
    VAR=$1
    VAL=$2
    FILE=$3

    CONTAINS=$(echo $(grep -o "^ *${VAR}\=" "${FILE}"))
    if [[ "" == "${CONTAINS}" ]]; then
        echo -e "\n${VAR}=\"${VAL}\"" >> "${FILE}"
    else
        sed -i -e "s/^\( *${VAR}=\)\(.*\)/\1\"${VAL}\"/" "${FILE}"
    fi
}
