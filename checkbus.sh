#!/bin/bash

# What stop to watch.
AGENCY="ttc"
BASE_URL="http://webservices.nextbus.com/service/publicXMLFeed"

# Times, in minutes, for different colors in the display.
MIN_BLUE_TIME=20
MIN_GREEN_TIME=10
MIN_YELLOW_TIME=5

INCLUDE_CURRENT_DATE=true
UPDATE_INTERVAL_SEC=30

COLOR_BLUE="\x1b[34;1m"
COLOR_GREEN="\x1b[32;1m"
COLOR_YELLOW="\x1b[33;1m"
COLOR_NONE="\x1b[0m"

#Check for some env var and set $1 and $2 gitignored due to privacy
if [ -a "presets.sh" ]; then
  source presets.sh
fi

#Helpers
resolve_route_names() {
  local routesURL="${BASE_URL}?command=routeList&a=${AGENCY}"
  local result=`curl -s "$routesURL" | grep '^<route.*tag=.*>$'`
  local route_names
  local route_ids
  IFS="####" read -a route_names <<<  `echo "${result}" | \
					grep -o "title="'"[^"]*"' | \
					sed "s/^title=//" | \
					sed 's/"//g' | \
					tr '\n' '####'`
  IFS="####" read -a route_ids <<<  `echo "${result}" | \
					grep -o "tag="'"[^"]*"' | \
					sed "s/^tag=//" | \
					sed 's/"//g' | \
					tr '\n' '####'`
  echo "Listing routes for ${AGENCY}"
  for i in "${!route_ids[@]}"
  do
    echo "[${route_ids[i]}] ${route_names[i]}"
  done
  echo -n "Type in the value inside [] for your route:"
  return `read retval && echo $retval`
}

resolve_stop_names() {
  local route=$1
  local stopsURL="${BASE_URL}?command=routeConfig&a=${AGENCY}&r=${route}"
  local result=`curl -s "$stopsURL" | grep '^<stop.*tag=.*>$'`
  local title_names
  local stop_ids
  IFS="####" read -a title_names <<<  `echo "${result}" | \
					grep -o "title="'"[^"]*"' | \
					sed "s/^title=//" | \
					sed 's/"//g' | \
					tr '\n' '####'`
  IFS="####" read -a stop_ids <<<  `echo "${result}" | \
					grep -o "tag="'"[^"]*"' | \
					sed "s/^tag=//" | \
					sed 's/"//g' | \
					tr '\n' '####'`
  echo "Listing stops for ${route}"
  for i in "${!stop_ids[@]}"
  do
    echo "[${stop_ids[i]}] ${title_names[i]}"
  done
  echo -p "Type in the value inside [] for your stop:"
  return `read retval && echo $retval`
}

#Figure out route and stop
if [ -z "$1" ]; then
  resolve_route_names
  route=$?
else
  route=$1
fi
if [ -z "$2" ]; then
  resolve_stop_names $route
  stop=$?
else
  stop=$2
fi

#Proceed
clear
url="${BASE_URL}?command=predictions&a=${AGENCY}&r=${route}&s=${stop}"
while true; do
 ($INCLUDE_CURRENT_DATE && date +"%A %F %I:%M %P"
  echo "$route"
  result=`curl -s "$url"`
  echo $result | \
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
  sleep $UPDATE_INTERVAL_SEC
done
