#!/bin/bash
apt-get update -qq
apt-get -u -V -s upgrade | grep "Inst prosody${PROSODY_VERSION}"

