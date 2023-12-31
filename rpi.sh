#!/bin/bash

directories=("raspios_arm64" "raspios_armhf" "raspios_full_arm64" "raspios_full_armhf" "raspios_lite_arm64" "raspios_lite_armhf" "raspios_oldstable_arm64" "raspios_oldstable_armhf" "raspios_oldstable_full_arm64" "raspios_oldstable_full_armhf" "raspios_oldstable_lite_arm64" "raspios_oldstable_lite_armhf")

logpath="/home/edo/rpi"

for dir in "${directories[@]}"; do

  baseurl="https://downloads.raspberrypi.com/$dir/images/"

  recentdir=$(curl -s $baseurl | grep raspios | tail -1 | awk -F  '>' '{print $7}' | sed 's/.\{3\}$//')

  fullurl=$baseurl$recentdir

  filename=$(curl -s $fullurl | grep torrent | awk -F '>' '{print $6}' | cut -d "\"" -f 2)

  uri=$fullurl$filename

  echo "[$(date)] Adding torrent at ${uri} to Transmission." >> $logpath/rpi.log

  response=$(transmission-remote --auth 'transmission:transmission' -a "$uri")

  echo "[$(date)] $response." >> /home/edo/rpi/rpi.log

done
