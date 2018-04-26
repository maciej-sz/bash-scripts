#!/usr/bin/env bash

function promptyn() {
  while true; do
    read -p "$1 (Yes/No): " yn
    case $yn in
        [Yy]* ) echo "1"; break;;
        [Nn]* ) echo ""; break;;
        * ) echo "Please answer yes or no.";;
    esac
  done
}