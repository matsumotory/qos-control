#!/bin/sh
echo ${1}

cp qos-control.pl qos-control.pl.bak
sed -i -e "s/eth3/${1}/g" qos-control.pl

diff qos-control.pl.bak qos-control.pl

# config ethtool for cbq
ethtool -K ${1} tso off
ethtool -K ${1} gso off
