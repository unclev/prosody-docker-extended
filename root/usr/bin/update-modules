#!/bin/bash
set -e
set -x

if [[ -z $(ls -A ${PROSODY_MODULES} | head -1) ]]; then
    hg clone https://hg.prosody.im/prosody-modules/ "$PROSODY_MODULES" || true
else
    cd "$PROSODY_MODULES"
    hg pull --update || true
    cd -
fi

