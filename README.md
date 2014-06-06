# qos-control.pl
Traffic control tool using cbq, tc and iproute for CentOS and Ubuntu. cbq don't support inbound traffic control, but qos-control.pl supported inbound traffic control using htb and ifb. You can control traffic easily and safely.

## TODO
Support other distri like Fedora, Debian and so on. Wellcome Pull-Request.

## Quick Install
#### Download
```
$ git clone https://github.com/matsumoto-r/qos-control.git
```
#### Install
```
$ cd qos-control
$ ./setup.sh
```

## How to Use
### Usage
```
$ ./qos-control.pl -h

    usage: ./qos-control.pl --method|-m METHOD --ip|-i SERVER_IP --direction|-d DIRECTION --traffic|-t BANDWIDTH [--eth|-e INTREFACE] [--protocol|-p PROTOCOL] [--src|-s SRC_IP]

        -m, --method        set method                  (view clear set)
        -i, --ip            set server ip
        -d, --direction     set direction               (out in)
        -t, --traffic       set traffic bandwidth Mbps  (1 2 4 8 16)
        -e, --eth           set interface               (eth0 eth1 eth2 eth3)
        -p, --protocol      set protocol                (https smtp ssh imaps imap all ftp http pop3 pop3s)
        -s, --src           set src ip
        -c, --clsid         set clsid only clear method
        -h, --help          display this help and exit
        -v, --version       display version and exit

```
### View
```
$ ./qos-control.pl --method view --ip 172.16.71.46
nothing
```
### Set
##### IP Address: 172.16.71.46
##### Direction: Out
##### Traffic: 16Mbps
##### Protocol: http
```
$ sudo ./qos-control.pl -i 172.16.71.46 -m set -p http -d out -t 16
*** old [172.16.71.46] settings ***
--------------------------
nothing
--------------------------

Setting ... OK

*** current [172.16.71.46] settings ***
------------------------------
CLSID->6067     interface->eth0       direction->out        bandwidth->16Mbps     server_ip_port>172.16.71.46:80      src_ip->nothing
------------------------------
```
### Clear
##### First, view and get CLSID
```
$ sudo ./qos-control.pl -i 172.16.71.46 -m view
CLSID->6067     interface->eth0       direction->out        bandwidth->16Mbps     server_ip_port>172.16.71.46:80      src_ip->nothing
```
##### Clear config
```
$ sudo ./qos-control.pl -i 172.16.71.46 -m clear -c 6067
*** old [172.16.71.46] settings ***
--------------------------
CLSID->6067     interface->eth0       direction->out        bandwidth->16Mbps     server_ip_port>172.16.71.46:80      src_ip->nothing   
--------------------------

Setting Clear ... OK

*** current [172.16.71.46] settings ***
--------------------------
nothing
--------------------------
```
