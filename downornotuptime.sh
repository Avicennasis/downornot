#!/bin/bash

echo "Your uptime percentage is:"
 echo \($(grep -r We ~/logs/downornot | wc -l) / $(echo $(grep -r We ~/logs/downornot | wc -l)  +  $(grep -r OMG ~/logs/downornot | wc -l) | bc)\) "* 100" | bc -l
