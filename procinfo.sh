#!/bin/bash

# procinfo [-t secs] pattern
#
# prints PID, CMD, USER, Memory Usage, CPU time, and number of threads 
# of processes with a command # that matches "pattern"
#
# If the [-t secs] option is passed, then it will loop and print the information
# every "secs" secods.
#
# If no pattern is given, it prints an error that a pattern is missing.
#

multiple_prints() {
ps -e -f | grep "$pattern" | while read line
do

  User=$(echo "$line" | awk '{print $1}')
  Pid=$(echo "$line" | awk '{print $2}')

  Cmd=$(cat /proc/$Pid/comm 2>/dev/null)
  #echo "$Cmd"
  if ! echo "$Cmd" | grep -q "$pattern"
  then
    continue
  fi

  #Throwing away stderr messages
  Cpu=$(awk '{printf "%d", ($14 + $15) / 100}' /proc/$Pid/stat 2>/dev/null)
  #echo "$Cpu"

  ##VmRSS is the line in status file that cotains mem stats
  Memory=$(grep VmRSS /proc/$Pid/status 2>/dev/null | awk '{printf "%d", $2/1024}')
  #echo "$Memory"
  #
  #if [ $Memory -eq 0 ]
  #then 
  #  continue
  #fi

  Threads=$(grep "^Threads:" /proc/$Pid/status 2>/dev/null | awk '{print $2}')

  printf "%20s %20s %20s %20s %20s %20s\n" "$Pid" "($Cmd)" "$User" "${Memory} Mb" "${Cpu} secs" "${Threads} Thr"
done
}







arguments=$#

#checking if either one argument is given or 3
if [[ $arguments -eq 1 || $arguments -eq 3 ]]
then
 echo "" 
else
  echo "procinfo.sh [-t secs] pattern"
  exit
fi

#checking if the first argument is -t and if it is then 3 arfuments must be provided
if [ $1 == '-t' ]
then 
  if [ $arguments -ne 3 ]
  then
    echo "procinfo.sh [-t secs] pattern"
    exit
  fi
  pattern=$3

else
  pattern=$1
fi

printf "%20s %20s %20s %20s %20s %20s\n" "PID" "CMD" "USER" "MEM" "CPU" "THREADS"

#if the first argument is -t then using an infinite loop to call a function
if [ $1 == '-t' ]
then
  while true
  do
    multiple_prints
    #sleep time taken from the 2nd argument
    sleep $2
    printf "\n\n"
    printf "%20s %20s %20s %20s %20s %20s\n" "PID" "CMD" "USER" "MEM" "CPU" "THREADS"
  done
    
fi
  



# a type of while loop that will read line by line and store it in teh vvariable line
ps -e -f | grep "$pattern" | while read line
do

  User=$(echo "$line" | awk '{print $1}')
  Pid=$(echo "$line" | awk '{print $2}')

  Cmd=$(cat /proc/$Pid/comm 2>/dev/null)
  #echo "$Cmd"
  if ! echo "$Cmd" | grep -q "$pattern"
  then
    continue
  fi
  
  #Throwing away stderr messages
  Cpu=$(awk '{printf "%d", ($14 + $15) / 100}' /proc/$Pid/stat 2>/dev/null)
  #echo "$Cpu"

  ##VmRSS is the line in status file that cotains mem stats
  Memory=$(grep "VmRSS" /proc/$Pid/status 2>/dev/null | awk '{printf "%d", $2/1024}')
  #echo "$Memory"
  #

  Threads=$(grep "^Threads:" /proc/$Pid/status 2>/dev/null | awk '{print $2}')
  #echo "$Threads"

  printf "%20s %20s %20s %20s %20s %20s\n" "$Pid" "($Cmd)" "$User" "${Memory} Mb" "${Cpu} secs" "${Threads} Thr"




done
