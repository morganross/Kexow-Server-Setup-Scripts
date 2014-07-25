#!/bin/bash

##Configuration parameters
AMINAME=ami-aa39599a
CHECKPERIOD=60 #in seconds
File=/etc/bind/list.txt
##Command Aliases
EC2DESC=ec2-describe-instances

##Do not edit
RAWFILE=/tmp/rawlist.txt

while true
do
#$EC2DESC | grep $AMINAME > $RAWFILE
ec2-describe-instances |grep ami-aa39599a | grep running | grep ssdkingstong > $RAWFILE

let i=0
declare -a ServerIPS
while read line; do
    #echo $line # or whaterver you want to do with the $line variablea
    IP=`echo $line | cut -d ' ' -f 14`
    ServerIPS[$i]=$IP
  i=$(( i + 1 ))
    #echo $i
done < $RAWFILE

#echo ${ServerIPS[@]}

### SSH to each server and see if there is any user logged in
let t=0
declare -a AddIPS
for i in "${ServerIPS[@]}"
do
  #echo "connceting to $i"
  output=`ssh -i /home/ubuntu/installer/clients.pem  ubuntu@$i 'sudo x2golistsessions_root'`
  #echo "output is $output"
  #if output contains GNOME then someone is logged in, else noone is in.
  if [[ $output == *GNOME* ]]
        then
                #echo "$i server has someone logged in!";
                let m=5
        else
                echo "$i has noone logged in. Adding it to list!";
                AddIPS[$t]=$i
                # Now simply check if these IPs are already in list.txt if not add them
                if grep -q ${AddIPS[$t]} "$File"; then
                        #echo "IP already exists!"
                        let m=6
                else
                        echo ${AddIPS[$t]} >> $File
						echo '
          __    _____    ______                 _      _            _ 
     _   /  |  |_   _|   | ___ \               | |    | |          | |
   _| |_ `| |    | |     | |_/ /      __ _   __| |  __| |  ___   __| |
  |_   _| | |    | |     |  __/      / _` | / _` | / _` | / _ \ / _` |
    |_|  _| |_  _| |_  _ | |      _ | (_| || (_| || (_| ||  __/| (_| |
         \___/  \___/ (_)\_|     (_) \__,_| \__,_| \__,_| \___| \__,_|
                                                                      
                                                                      '
 fi
                t=$(( t + 1 ))
        fi
done
#echo ${AddIPS[@]}

sleep  $CHECKPERIOD
done
