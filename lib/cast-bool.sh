#!/usr/bin/env bash

#
# Usage castBool $VAR
#
# Eg.
# castBool true
# castBool "y"
#
function castBool() {
    case $1 in
        [YyTt1]*) echo "1";;
        [NnFf0]*) echo "0";;
        *) echo "Unrecognized boolean value: ${1}" 1>&2; exit 1;;
    esac
}