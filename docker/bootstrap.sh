#!/bin/bash

if [ ! -e /bootstrap.lock ]; then
    echo "alias qc='/app/qos-control.pl'" > ~/.bash_profile
    ./setup.sh

    sudo touch /bootstrap.lock
fi

echo -e '\e[1;32m[CAUTION] !! This container is running in privileged mode. !! \e[m'
sleep 2 && /bin/bash -l
