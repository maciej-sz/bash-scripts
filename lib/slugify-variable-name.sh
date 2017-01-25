#!/usr/bin/env bash

function slugifyVariableName() {
    echo $(sed "s/[^a-z|0-9|\_]/\_/g;" <<< $1)
}
