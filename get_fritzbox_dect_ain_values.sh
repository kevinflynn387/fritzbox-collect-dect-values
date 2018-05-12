#!/bin/bash

# environment settings - please update the following lines
outputdir="/var/tmp"
fritzboxip=192.168.178.1
username=fritzboxuser
password=fritzboxpassword
ainlist="123456789012" # Actor IDs - space separated values  <ain1> <ain2> <ain3> <ain1> <ain2> <ain3> <ain4> <aix5>

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

echo "------------------------------"

# for-loop over all actors in AIN-list (ainlist)
for ain in $ainlist
do
 # read temperature and format output
 datatemp=`   curl "http://${fritzboxip}/webservices/homeautoswitch.lua?ain=$ain&switchcmd=gettemperature&sid=$sid" 2>/dev/null `
 datatemp=`   echo "scale=1; $datatemp / 10" | bc `

 # read power consumption
 datapower=`  curl "http://${fritzboxip}/webservices/homeautoswitch.lua?ain=$ain&switchcmd=getswitchpower&sid=$sid" 2>/dev/null `
 datapowertotal=`  curl "http://${fritzboxip}/webservices/homeautoswitch.lua?ain=$ain&switchcmd=getswitchenergy&sid=$sid" 2>/dev/null `

 echo "ain = $ain"
 echo -e "\tTemp = $datatemp Celsius"
 echo -e "\tStrom = $datapower mW"
 echo -e "\tStromtotal = $datapowertotal Wh"
 echo ""s
done