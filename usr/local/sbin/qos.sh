#!/bin/bash
#############################################################################################
#
#    Sets Up CBQ-based Traffic Control Tool
#       Copyright (C) 2010 MATSUMOTO, Ryosuke
#
#    Original Code cbq.init v0.7.3
#    Copyright (C) 1999  Pavel Golubev <pg@ksi-linux.com>
#    Copyright (C) 2001-2004  Lubomir Bulej <pallas@kadan.cz>
#
#    Fixed, Modified And Added By matsumoto_r
#    Date     2010/09/01
#
#    Usage:
#       /usr/local/sbin/qos.sh {start|compile|stop|restart|timecheck|list|stats}
#
#############################################################################################
#
# Change Log
#
# 2010/09/01 matsumoto_r first release
#
#############################################################################################

export LC_ALL=C

### Command locations
TC=/sbin/tc
IP=/sbin/ip
MP=/sbin/modprobe

### Default filter priorities (must be different)
PRIO_RULE_DEFAULT=${PRIO_RULE:-100}
PRIO_MARK_DEFAULT=${PRIO_MARK:-200}
PRIO_REALM_DEFAULT=${PRIO_REALM:-300}

### Default CBQ_PATH & CBQ_CACHE settings
CBQ_PATH=${CBQ_PATH:-/etc/sysconfig/qos}
CBQ_CACHE=${CBQ_CACHE:-/var/cache/qos.init}

### Uncomment to enable logfile for debugging
#CBQ_DEBUG="/var/run/qos-$1"

### Modules to probe for. Uncomment the last CBQ_PROBE
### line if you have QoS support compiled into kernel
CBQ_PROBE="sch_cbq sch_tbf sch_sfq sch_prio"
CBQ_PROBE="$CBQ_PROBE cls_fw cls_u32 cls_route"
#CBQ_PROBE=""

### Keywords required for qdisc & class configuration
CBQ_WORDS="DEVICE|RATE|WEIGHT|PRIO|PARENT|LEAF|BOUNDED|ISOLATED|DIRECTION"
CBQ_WORDS="$CBQ_WORDS|PRIO_MARK|PRIO_RULE|PRIO_REALM|BUFFER"
CBQ_WORDS="$CBQ_WORDS|LIMIT|PEAK|MTU|QUANTUM|PERTURB"

### Source AVPKT if it exists
[ -r /etc/sysconfig/qos/avpkt ] && . /etc/sysconfig/qos/avpkt
AVPKT=${AVPKT:-3000}


#############################################################################
############################# SUPPORT FUNCTIONS #############################
#############################################################################

### Get list of network devices
cbq_device_list () {
    ip link show| sed -n "/^[0-9]/ \
    { s/^[0-9]\+: \([a-z0-9._]\+\)[:@].*/\1/; p; }"
} # cbq_device_list


### Remove root class from device $1
cbq_device_off () {
    tc qdisc del dev $1 root 2> /dev/null
        tc qdisc del dev $1 ingress handle ffff: 2> /dev/null
} # cbq_device_off


### Remove CBQ from all devices
cbq_off () {
    for dev in `cbq_device_list`; do
        cbq_device_off $dev
            done
            exit 0
} # cbq_off


### Prefixed message
cbq_message () {
    echo -e "**CBQ: $@"
} # cbq_message

### Failure message
cbq_failure () {
    cbq_message "$@"
        exit 1
} # cbq_failure

### Failure w/ cbq-off
cbq_fail_off () {
    cbq_message "$@"
        cbq_off
        exit 1
} # cbq_fail_off


### Convert time to absolute value
cbq_time2abs () {
    local min=${1##*:}; min=${min##0}
    local hrs=${1%%:*}; hrs=${hrs##0}
    echo $[hrs*60 + min]
} # cbq_time2abs


### Display CBQ setup
cbq_show () {
    for dev in `cbq_device_list`; do
        [ `tc qdisc show dev $dev| wc -l` -eq 0 ] && continue
            echo -e "### $dev: queueing disciplines\n"
            tc $1 qdisc show dev $dev; echo

            [ `tc class show dev $dev| wc -l` -eq 0 ] && continue
            echo -e "### $dev: traffic classes\n"
            tc $1 class show dev $dev; echo

            [ `tc filter show dev $dev| wc -l` -eq 0 ] && continue
            echo -e "### $dev: filtering rules\n"
            tc $1 filter show dev $dev; echo
            done
} # cbq_show


### Check configuration and load DEVICES, DEVFIELDS and CLASSLIST from $1
cbq_init () {
### Get a list of configured classes
    CLASSLIST=`find $1 -maxdepth 1 \( -type f -or -type l \) -name 'qos-*' \
              -not -name '*~' -printf "%f\n"| sort`
              [ -z "$CLASSLIST" ] &&
              cbq_failure "no configuration files found in $1!"

### Gather all DEVICE fields from $1/qos-*
              DEVFIELDS=`find $1 -maxdepth 1 \( -type f -or -type l \) -name 'qos-*' \
              -not -name '*~' | xargs sed -n 's/#.*//; \
              s/[[:space:]]//g; /^DEVICE=[^,]*,[^,]*\(,[^,]*\)\?/ \
              { s/.*=//; p; }'| sort -u`
    [ -z "$DEVFIELDS" ] &&
        cbq_failure "no DEVICE field found in $1/qos-*!"

### Check for different DEVICE fields for the same device
        DEVICES=`echo "$DEVFIELDS"| sed 's/,.*//'| sort -u`
        [ `echo "$DEVICES"| wc -l` -ne `echo "$DEVFIELDS"| wc -l` ] &&
        cbq_failure "different DEVICE fields for single device!\n$DEVFIELDS"
} # cbq_init


### Load class configuration from $1/$2
cbq_load_class () {
    CLASS=`echo $2| sed 's/^qos-0*//; s/^\([0-9a-fA-F]\+\).*/\1/'`
        CFILE=`sed -n 's/#.*//; s/[[:space:]]//g; /^[[:alnum:]_]\+=[[:alnum:].,:;/*@-_]\+$/ p' $1/$2`

### Check class number
        IDVAL=`/usr/bin/printf "%d" 0x$CLASS 2> /dev/null`
        [ $? -ne 0 -o $IDVAL -lt 2 -o $IDVAL -gt 65535 ] &&
        cbq_fail_off "class ID of $2 must be in range <0002-FFFF>!"

### Set defaults & load class
        RATE=""; WEIGHT=""; PARENT=""; PRIO=5
        LEAF=tbf; BOUNDED=yes; ISOLATED=no
        BUFFER=10Kb/8; LIMIT=15Kb; MTU=1500
        PEAK=""; PERTURB=10; QUANTUM=""; DIRECTION="out"

	PRIO_RULE=$PRIO_RULE_DEFAULT
	PRIO_MARK=$PRIO_MARK_DEFAULT
	PRIO_REALM=$PRIO_REALM_DEFAULT

	eval `echo "$CFILE"| grep -E "^($CBQ_WORDS)="`

	### Require RATE/WEIGHT
	[ -z "$RATE" -o -z "$WEIGHT" ] &&
		cbq_fail_off "missing RATE or WEIGHT in $2!"

	### Class device
	DEVICE=${DEVICE%%,*}
	[ -z "$DEVICE" ] && cbq_fail_off "missing DEVICE field in $2!"

	BANDWIDTH=`echo "$DEVFIELDS"| sed -n "/^$DEVICE,/ \
		  { s/[^,]*,\([^,]*\).*/\1/; p; q; }"`

# matsumoto_r
    [ "$DIRECTION" = "out" ] || [ "$DIRECTION" = "in" ] || cbq_fail_off "$DIRECTION Direction neither in nor out!"

	### Convert to "tc" options
	PEAK=${PEAK:+peakrate $PEAK}
	PERTURB=${PERTURB:+perturb $PERTURB}
	QUANTUM=${QUANTUM:+quantum $QUANTUM}

	[ "$BOUNDED" = "no" ] && BOUNDED="" || BOUNDED="bounded"
	[ "$ISOLATED" = "yes" ] && ISOLATED="isolated" || ISOLATED=""
} # cbq_load_class


#############################################################################
#################################### INIT ###################################
#############################################################################

### Check for presence of ip-route2 in usual place
[ -x $TC -a -x $IP ] ||
	cbq_failure "ip-route2 utilities not installed or executable!"


### ip/tc wrappers
if [ "$1" = "compile" ]; then
	### no module probing
	CBQ_PROBE=""

	ip () {
		$IP "$@"
	} # ip

	### echo-only version of "tc" command
	tc () {
		echo "$TC $@"
	} # tc

elif [ -n "$CBQ_DEBUG" ]; then
	echo -e "# `date`" > $CBQ_DEBUG

	### Logging version of "ip" command
	ip () {
		echo -e "\n# ip $@" >> $CBQ_DEBUG
		$IP "$@" 2>&1 | tee -a $CBQ_DEBUG
	} # ip

	### Logging version of "tc" command
	tc () {
		echo -e "\n# tc $@" >> $CBQ_DEBUG
		$TC "$@" 2>&1 | tee -a $CBQ_DEBUG
	} # tc
else
	### Default wrappers
	
	ip () {
		$IP "$@"
	} # ip
	
	tc () {
		$TC "$@"
	} # tc
fi # ip/tc wrappers


case "$1" in

#############################################################################
############################### START/COMPILE ###############################
#############################################################################

start|compile)


### Probe QoS modules (start only)
for module in $CBQ_PROBE; do
	$MP $module || cbq_failure "failed to load module $module"
done


### If we are in compile/nocache/logging mode, don't bother with cache
if [ "$1" != "compile" -a "$2" != "nocache" -a -z "$CBQ_DEBUG" ]; then
	VALID=1

	### validate the cache
	[ "$2" = "invalidate" -o ! -f $CBQ_CACHE ] && VALID=0
	if [ $VALID -eq 1 ]; then
		[ `find $CBQ_PATH -maxdepth 1 -newer $CBQ_CACHE| \
		  wc -l` -gt 0 ] && VALID=0
	fi

	### compile the config if the cache is invalid
	if [ $VALID -ne 1 ]; then
		$0 compile > $CBQ_CACHE ||
			cbq_fail_off "failed to compile CBQ configuration!"
	fi

	### run the cached commands
	exec /bin/sh $CBQ_CACHE 2> /dev/null
fi

### Load DEVICES, DEVFIELDS and CLASSLIST
cbq_init $CBQ_PATH

### Setup root qdisc on all configured devices
for dev in $DEVICES; do
	### Retrieve device bandwidth and, optionally, weight
	DEVTEMP=`echo "$DEVFIELDS"| sed -n "/^$dev,/ { s/$dev,//; p; q; }"`
	DEVBWDT=${DEVTEMP%%,*};	DEVWGHT=${DEVTEMP##*,}
	[ "$DEVBWDT" = "$DEVWGHT" ] && DEVWGHT=""

	### Device bandwidth is required
	if [ -z "$DEVBWDT" ]; then
		cbq_message "could not determine bandwidth for device $dev!"
		cbq_failure "please set up the DEVICE fields properly!"
	fi

	### Check if the device is there
	ip link show $dev &> /dev/null ||
		cbq_fail_off "device $dev not found!"

	### Remove old root qdisc from device
	cbq_device_off $dev


	### Setup root qdisc + class for device
	tc qdisc add dev $dev root handle 1 cbq \
	bandwidth $DEVBWDT avpkt $AVPKT cell 8

    ### matsumoto_r
    tc qdisc add dev $dev ingress handle ffff:

	### Set weight of the root class if set
	[ -n "$DEVWGHT" ] &&
		tc class change dev $dev root cbq weight $DEVWGHT allot 1514

	[ "$1" = "compile" ] && echo
done # dev


### Setup traffic classes
for classfile in $CLASSLIST; do
	cbq_load_class $CBQ_PATH $classfile

# matsumoto_r
    if [ "$DIRECTION" = "in" ]; then
	    for rule in `echo "$CFILE"| sed -n '/^RULE/ { s/.*=//; p; }'`; do
	    	### Split rule into source & destination
	    	SRC=${rule%%,*}; DST=${rule##*,}
	    	[ "$SRC" = "$rule" ] && SRC=""


	    	### Split destination into address, port & mask fields
	    	DADDR=${DST%%:*}; DTEMP=${DST##*:}
	    	[ "$DADDR" = "$DST" ] && DTEMP=""

	    	DPORT=${DTEMP%%/*}; DMASK=${DTEMP##*/}
	    	[ "$DPORT" = "$DTEMP" ] && DMASK="0xffff"


	    	### Split up source (if specified)
	    	SADDR=""; SPORT=""
	    	if [ -n "$SRC" ]; then
	    		SADDR=${SRC%%:*}; STEMP=${SRC##*:}
	    		[ "$SADDR" = "$SRC" ] && STEMP=""

	    		SPORT=${STEMP%%/*}; SMASK=${STEMP##*/}
	    		[ "$SPORT" = "$STEMP" ] && SMASK="0xffff"
	    	fi


	    	### Convert asterisks to empty strings
	    	SADDR=${SADDR#\*}; DADDR=${DADDR#\*}

	    	### Compose u32 filter rules
	    	u32_s="${SPORT:+match ip dport $SPORT $SMASK}"
	    	u32_s="${SADDR:+match ip dst $SADDR} $u32_s"
	    	u32_d="${DPORT:+match ip sport $DPORT $DMASK}"
	    	u32_d="${DADDR:+match ip src $DADDR} $u32_d"

	    done ### rule

        tc filter add dev $DEVICE parent ffff: protocol ip prio $PRIO u32 $u32_s $u32_d police rate $RATE burst $WEIGHT drop flowid :1
        continue
    fi

	### Create the class
	tc class add dev $DEVICE parent 1:$PARENT classid 1:$CLASS cbq \
	bandwidth $BANDWIDTH rate $RATE weight $WEIGHT prio $PRIO \
	allot 1514 cell 8 maxburst 20 avpkt $AVPKT $BOUNDED $ISOLATED ||
		cbq_fail_off "failed to add class $CLASS with parent $PARENT on $DEVICE!"

	### Create leaf qdisc if set
	if [ "$LEAF" = "tbf" ]; then
		tc qdisc add dev $DEVICE parent 1:$CLASS handle $CLASS tbf \
		rate $RATE buffer $BUFFER limit $LIMIT mtu $MTU $PEAK
	elif [ "$LEAF" = "sfq" ]; then
		tc qdisc add dev $DEVICE parent 1:$CLASS handle $CLASS sfq \
		$PERTURB $QUANTUM
	fi


	### Create fw filter for MARK fields
	for mark in `echo "$CFILE"| sed -n '/^MARK/ { s/.*=//; p; }'`; do
		### Attach fw filter to root class
		tc filter add dev $DEVICE parent 1:0 protocol ip \
		prio $PRIO_MARK handle $mark fw classid 1:$CLASS
	done ### mark

	### Create route filter for REALM fields
	for realm in `echo "$CFILE"| sed -n '/^REALM/ { s/.*=//; p; }'`; do
		### Split realm into source & destination realms
		SREALM=${realm%%,*}; DREALM=${realm##*,}
		[ "$SREALM" = "$DREALM" ] && SREALM=""

		### Convert asterisks to empty strings
		SREALM=${SREALM#\*}; DREALM=${DREALM#\*}

		### Attach route filter to the root class
		tc filter add dev $DEVICE parent 1:0 protocol ip \
		prio $PRIO_REALM route ${SREALM:+from $SREALM} \
		${DREALM:+to $DREALM} classid 1:$CLASS
	done ### realm

	### Create u32 filter for RULE fields
	for rule in `echo "$CFILE"| sed -n '/^RULE/ { s/.*=//; p; }'`; do
		### Split rule into source & destination
		SRC=${rule%%,*}; DST=${rule##*,}
		[ "$SRC" = "$rule" ] && SRC=""


		### Split destination into address, port & mask fields
		DADDR=${DST%%:*}; DTEMP=${DST##*:}
		[ "$DADDR" = "$DST" ] && DTEMP=""

		DPORT=${DTEMP%%/*}; DMASK=${DTEMP##*/}
		[ "$DPORT" = "$DTEMP" ] && DMASK="0xffff"


		### Split up source (if specified)
		SADDR=""; SPORT=""
		if [ -n "$SRC" ]; then
			SADDR=${SRC%%:*}; STEMP=${SRC##*:}
			[ "$SADDR" = "$SRC" ] && STEMP=""

			SPORT=${STEMP%%/*}; SMASK=${STEMP##*/}
			[ "$SPORT" = "$STEMP" ] && SMASK="0xffff"
		fi


		### Convert asterisks to empty strings
		SADDR=${SADDR#\*}; DADDR=${DADDR#\*}

		### Compose u32 filter rules
		u32_s="${SPORT:+match ip sport $SPORT $SMASK}"
		u32_s="${SADDR:+match ip src $SADDR} $u32_s"
		u32_d="${DPORT:+match ip dport $DPORT $DMASK}"
		u32_d="${DADDR:+match ip dst $DADDR} $u32_d"

		### Uncomment the following if you want to see parsed rules
		#echo "$rule: $u32_s $u32_d"

		### Attach u32 filter to the appropriate class
		tc filter add dev $DEVICE parent 1:0 protocol ip \
		prio $PRIO_RULE u32 $u32_s $u32_d classid 1:$CLASS
	done ### rule

	[ "$1" = "compile" ] && echo
done ### classfile
;;


#############################################################################
################################# TIME CHECK ################################
#############################################################################

timecheck)

### Get time + weekday
TIME_TMP=`date +%w/%k:%M`
TIME_DOW=${TIME_TMP%%/*}
TIME_NOW=${TIME_TMP##*/}

### Load DEVICES, DEVFIELDS and CLASSLIST
cbq_init $CBQ_PATH

### Run through all classes
for classfile in $CLASSLIST; do
	### Gather all TIME rules from class config
	TIMESET=`sed -n 's/#.*//; s/[[:space:]]//g; /^TIME/ { s/.*=//; p; }' \
		$CBQ_PATH/$classfile`
	[ -z "$TIMESET" ] && continue

	MATCH=0; CHANGE=0
	for timerule in $TIMESET; do
		TIME_ABS=`cbq_time2abs $TIME_NOW`
		
		### Split TIME rule to pieces
		TIMESPEC=${timerule%%;*}; PARAMS=${timerule##*;}
		WEEKDAYS=${TIMESPEC%%/*}; INTERVAL=${TIMESPEC##*/}
		BEG_TIME=${INTERVAL%%-*}; END_TIME=${INTERVAL##*-}

		### Check the day-of-week (if present)
		[ "$WEEKDAYS" != "$INTERVAL" -a \
		  -n "${WEEKDAYS##*$TIME_DOW*}" ] && continue

		### Compute interval boundaries
		BEG_ABS=`cbq_time2abs $BEG_TIME`
		END_ABS=`cbq_time2abs $END_TIME`

		### Midnight wrap fixup
		if [ $BEG_ABS -gt $END_ABS ]; then
			[ $TIME_ABS -le $END_ABS ] &&
				TIME_ABS=$[TIME_ABS + 24*60]

			END_ABS=$[END_ABS + 24*60]
		fi

		### If the time matches, remember params and set MATCH flag
		if [ $TIME_ABS -ge $BEG_ABS -a $TIME_ABS -lt $END_ABS ]; then
			TMP_RATE=${PARAMS%%/*}; PARAMS=${PARAMS#*/}
			TMP_WGHT=${PARAMS%%/*}; TMP_PEAK=${PARAMS##*/}

			[ "$TMP_PEAK" = "$TMP_WGHT" ] && TMP_PEAK=""
			TMP_PEAK=${TMP_PEAK:+peakrate $TMP_PEAK}

			MATCH=1
		fi
	done ### timerule


	cbq_load_class $CBQ_PATH $classfile

	### Get current RATE of CBQ class
	RATE_NOW=`tc class show dev $DEVICE| sed -n \
		 "/cbq 1:$CLASS / { s/.*rate //; s/ .*//; p; q; }"`
	[ -z "$RATE_NOW" ] && continue

	### Time interval matched
	if [ $MATCH -ne 0 ]; then

		### Check if there is any change in class RATE
		if [ "$RATE_NOW" != "$TMP_RATE" ]; then
			NEW_RATE="$TMP_RATE"
			NEW_WGHT="$TMP_WGHT"
			NEW_PEAK="$TMP_PEAK"
			CHANGE=1
		fi

	### Match not found, reset to default RATE if necessary
	elif [ "$RATE_NOW" != "$RATE" ]; then
		NEW_WGHT="$WEIGHT"
		NEW_RATE="$RATE"
		NEW_PEAK="$PEAK"
		CHANGE=1
	fi

	### If there are no changes, go for next class
	[ $CHANGE -eq 0 ] && continue

	### Replace CBQ class
	tc class replace dev $DEVICE classid 1:$CLASS cbq \
	bandwidth $BANDWIDTH rate $NEW_RATE weight $NEW_WGHT prio $PRIO \
	allot 1514 cell 8 maxburst 20 avpkt $AVPKT $BOUNDED $ISOLATED

	### Replace leaf qdisc (if any)
	if [ "$LEAF" = "tbf" ]; then
		tc qdisc replace dev $DEVICE handle $CLASS tbf \
		rate $NEW_RATE buffer $BUFFER limit $LIMIT mtu $MTU $NEW_PEAK
	fi

	cbq_message "$TIME_NOW: class $CLASS on $DEVICE changed rate ($RATE_NOW -> $NEW_RATE)"
done ### class file
;;


#############################################################################
################################## THE REST #################################
#############################################################################

stop)
	cbq_off
	;;

list)
	cbq_show
	;;

stats)
	cbq_show -s
	;;

restart)
	shift
	$0 stop
	$0 start "$@"
	;;

*)
	echo "Usage: `basename $0` {start|compile|stop|restart|timecheck|list|stats}"
esac
