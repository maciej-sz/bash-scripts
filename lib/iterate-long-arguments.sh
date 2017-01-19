#!/usr/bin/env bash

# eg. ./script.sh --foo=1 --bar="This is Sparta" --baz

while test ${#} -gt 0
do
    IFS="=" read -r -a parts <<< "$1"
    shift
    arg_name=${parts[0]}
    arg_val=${parts[1]}
    case ${arg_name} in
        --foo)
            echo "Foo = \"$arg_val\""
            continue
            ;;
        --bar)
            echo "Bar = \"$arg_val\""
            continue
            ;;
        --baz)
            echo "Baz is present"
            continue
            ;;
        *)
            echo "ERROR: Unrecognized parameter: $arg_name" 1>&2
            exit 1
    esac
done
