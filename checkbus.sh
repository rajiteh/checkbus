#!/bin/bash

# What stop to watch.
AGENCY="mbta"
ROUTE="94"
STOP="5104"

# Times, in minutes, for different colors in the display.
MIN_BLUE_TIME=38
MIN_GREEN_TIME=28
MIN_YELLOW_TIME=21

INCLUDE_CURRENT_DATE=true

UPDATE_INTERVAL_SEC=30

URL="http://webservices.nextbus.com/service/publicXMLFeed?"
URL+="command=predictions&a=${AGENCY}&r=${ROUTE}&s=${STOP}"

COLOR_BLUE="\e[34;1m"
COLOR_GREEN="\e[32;1m"
COLOR_YELLOW="\e[33;1m"
COLOR_NONE="\e[0m"

while true; do
 ($INCLUDE_CURRENT_DATE && date +"%A %F %I:%M %P"
  curl -s "$URL" | \
    grep 'prediction epochTime' | \
    grep -o "minutes="'"[^"]*"' | \
    sed "s/^minutes=//" | \
    sed 's/"//g' | \
    while read n; do
      if [ $n -gt $MIN_BLUE_TIME ]; then
        echo -e "$COLOR_BLUE$n$COLOR_NONE"
      elif [ $n -gt $MIN_GREEN_TIME ]; then
        echo -e "$COLOR_GREEN$n$COLOR_NONE"
      elif [ $n -ge $MIN_YELLOW_TIME ]; then
        echo -e "$COLOR_YELLOW$n$COLOR_NONE"
      fi
    done) | \
    tr '\n' '\t'
  echo
  sleep 30
done
