#!/usr/bin/env bash

function readPassword() {
    MSG1=$1
    MSG2=$2
    if [[ "" == "${MSG1}" ]]; then MSG1="New password"; fi
    if [[ "" == "${MSG2}" ]]; then MSG2="Confirm password"; fi

    MSG1="${MSG1}: "
    MSG2="${MSG2}: "

    while true; do
        read -sp "${MSG1}" PASSWORD
        read -sp "${MSG2}" CONFIRM
        if [[ "${PASSWORD}" != "${CONFIRM}" ]]; then printf "\nPasswords do not match!\n" 1>&2; continue; fi
        if [[ 3 > "${#PASSWORD}" ]]; then printf "\nPassword must have at least 3 characters!\n" 1>&2; continue; fi
        break
    done

    echo "${PASSWORD}"
}