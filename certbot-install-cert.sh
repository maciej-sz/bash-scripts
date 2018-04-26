#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 domain.com"
    exit 1
fi

sudo certbot --authenticator standalone --installer nginx -d "$1" --pre-hook "service nginx stop" --post-hook "service nginx start"
