#!/bin/bash
set -e
set -x

if [[ $(id -u) -eq $(id -u prosody) ]]; then
    if [[ -z $(ls -A /etc/prosody | head -1) ]] ; then
        cp -Rv /etc/prosody.default/* /etc/prosody/
    fi
    if [[ -n $DOMAIN ]]; then
       # tweak config
        sed -i "s/example.com/$DOMAIN/g" /etc/prosody/prosody.cfg.lua
        sed -i 's/enabled = false -- Remove this line to enable/enabled = true -- false to disable/' /etc/prosody/prosody.cfg.lua
        # copy default key pair if not exists
        if [[ ! -f /etc/prosody/certs/$DOMAIN.key && -f /etc/prosody/certs/localhost.key ]]; then
            cp /etc/prosody/certs/localhost.key /etc/prosody/certs/$DOMAIN.key
        fi
         if [[ ! -f /etc/prosody/certs/$DOMAIN.crt && -f /etc/prosody/certs/localhost.crt ]]; then
            cp /etc/prosody/certs/localhost.crt /etc/prosody/certs/$DOMAIN.crt
        fi
    fi
    if [ -z $(ls -A ${PROSODY_MODULES} | head -1) ]; then
        /usr/bin/update-modules
    fi
    if [[ $1 == "prosody" && -n $LOCAL &&  -n $PASSWORD && -n $DOMAIN ]]; then
        prosodyctl register $LOCAL $DOMAIN $PASSWORD
    fi
fi
exec "$@"
