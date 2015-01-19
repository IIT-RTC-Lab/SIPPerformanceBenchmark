#!/bin/bash

#Declation of values
#rate (calls per second) : r
#max : maximum call rate before exiting while loop
#Limit1 : left limit with no failure
#Limit2 : right limit with failure(s)
#fail = number of call failed (retrieved from trace_screen log)

#Executing the script 
#on UAC : sudo ./nodut-nortp-uac.sh GRANULARITY TIMEOUT || example : ./nodut-nortp-uac.sh 3 45
#on UAS : sudo ./sipp -sn uas 10.200.0.250

r='100'
max='10000'
Limit1='0'
Limit2='0'
let "Accuracy= $1+1"

echo "Call-rate = "$r 
echo "Timeout = "$2

while [ $Accuracy -gt  $1 ] && [ $r -lt $max ]
do

./sipp -i 10.200.0.248 -sn uac 10.200.0.250 -r $r -timeout $2 -trace_screen

#sleeping 5sec to let the computer create and read the file log before continuing
sleep 5

#looking for log file
pathlog=$(find . -maxdepth 1 -name '*.log')

#looking for the Failure value inlog file
if [ -f $pathlog ]
then
Fail_temp=$(grep -w Failed $pathlog | cut -d"|" -f3 | tr -s ' ')
Fail=`echo "Number of Fail(s) = "$Fail_temp | awk {'print $5'}`
sudo mv $pathlog Log/Archives/
fi

#if no failure : the left limit with no failure = rate-call 
if [ $Fail -eq 0 ]
then
echo "No Fail Detected"
Limit1=$r

#if no left limit failure determined yet : rate-call is increased by 50%
if [ $Limit2 -eq 0 ]
then
echo "Limit2 = 0"
r=$(echo "$r + ($r-$Limit2)/2" | bc)   #decimal calculus introduces the use of the bc option
Accuracy=$(( r-Limit2 ))

#if a left limit failure is already determined : rate-call is increased
else
echo "Limit2 ≠ 0"
r=$(echo "$r + ($Limit2-$r)/2"| bc)   #decimal calculus introduces the use of the bc option
Accuracy=$(( Limit2-r ))
fi

#if Failure(s) is/are detected, rate-call is decreased
else
Limit2=$r
echo "Fail(s) Detected"
r=$(echo "$r - ($r-$Limit1)/2" | bc)
Accuracy=$(( r-Limit1 ))
fi

done

echo -e "\nTHE BREAKING POINT IS:  $r call per s\n"
