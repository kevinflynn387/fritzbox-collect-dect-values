#!/bin/bash

# environment settings - please update the following lines
outputdir="/var/tmp"
fritzboxip=192.168.178.1
username=fritzboxuser
password=fritzboxpassword

########################################################################################
# define location of last sid
lastsid=$outputdir/last.sid

# create sid file if not exists
touch $lastsid

# read last sid
sid=$(cat $lastsid)

# check last sid
loginA=$(curl http://${fritzboxip}/login_sid.lua?sid=$sid 2>/dev/null)
sid=$(sed -n -e 's/.*<SID>\(.*\)<\/SID>.*/\1/p' <<<$loginA )

# read dynamic password salt
challenge=$(sed -n -e 's/.*<Challenge>\(.*\)<\/Challenge>.*/\1/p' <<<$loginA)

# check if login and new sid is needed
if [ "$sid" = "0000000000000000" ]
	then
		echo "Login started..."
		pwstring="$challenge-$password"
		pwhash=$(echo -n "$pwstring" |sed -e 's,.,&\n,g' | tr '\n' '\0' | md5sum | grep -o "[0-9a-z]\{32\}")
		response="$challenge-$pwhash"
		loginB=$(curl -s "http://${fritzboxip}/login_sid.lua" -d "response=$response" -d 'username='${username} 2>/dev/null)

		sid=$(sed -n -e 's/.*<SID>\(.*\)<\/SID>.*/\1/p' <<<$loginB)
		echo "New SID is $sid"
		echo "$sid" >$lastsid
	else
		echo "Old SID is already active $sid"
fi

# read and query all AINs
ainlist=$(curl "http://${fritzboxip}/webservices/homeautoswitch.lua?switchcmd=getswitchlist&sid=$sid" 2>/dev/null)
for ain in $(echo $ainlist | sed "s/,/ /g")
do
    switch_connection_state=$(curl "http://${fritzboxip}/webservices/homeautoswitch.lua?ain=$ain&switchcmd=getswitchpresent&sid=$sid" 2>/dev/null)
    switch_name=$(curl "http://${fritzboxip}/webservices/homeautoswitch.lua?ain=$ain&switchcmd=getswitchname&sid=$sid" 2>/dev/null)
    echo "###########################################"
    echo "### AIN: $ain"
    echo "# Connection-state: $switch_connection_state"
    echo "# SwitchName: $switch_name"

    if [ "$switch_connection_state" = "1" ]
		then
    		# read temperature and format output
    		datatemp=`   curl "http://${fritzboxip}/webservices/homeautoswitch.lua?ain=$ain&switchcmd=gettemperature&sid=$sid" 2>/dev/null `
    		datatemp=`   echo "scale=1; $datatemp / 10" | bc `
			# read power consumption
    		datapower=`  curl "http://${fritzboxip}/webservices/homeautoswitch.lua?ain=$ain&switchcmd=getswitchpower&sid=$sid" 2>/dev/null `
    		datapowertotal=`  curl "http://${fritzboxip}/webservices/homeautoswitch.lua?ain=$ain&switchcmd=getswitchenergy&sid=$sid" 2>/dev/null `

    		echo "# Temperature = $datatemp Celsius"
    		echo "# Power consumption currently = $datapower mW"
    		echo "# Total power consumption = $datapowertotal Wh"
    fi
done