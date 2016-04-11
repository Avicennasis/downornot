#!/bin/bash

WGET='/usr/bin/wget'
URL='http://HOME.WEBSITE/'

${WGET} -O /dev/null --tries=1 ${URL}

if [ $? -eq 0 ]; then
    echo "Success!"
    mkdir -p "${HOME}/logs/downornot/$(date '+%Y/%m')"
    echo "We are up as of $(date '+%Y %b %d %H:%M:%S')" >>~/logs/downornot/$(date '+%Y')/$(date '+%m')/$(date '+%Y-%m-%d').log
else
    echo "Fail! :("
    mkdir -p "${HOME}/logs/downornot/$(date '+%Y/%m')"
    echo "OMG It's Burning! as of $(date '+%Y %b %d %H:%M:%S')" >>~/logs/downornot/$(date '+%Y')/$(date '+%m')/$(date '+%Y-%m-%d').log
    echo "OMG It's Burning! as of $(date '+%Y %b %d %H:%M:%S')" | mail -s "Home Interwebs are down!" USERNAME@gmail.com
fi
