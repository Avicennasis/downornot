#!/bin/bash
Name="GenericName"

echo "Your uptime percentage is:"
 echo \($(grep -r W ~/logs/${Name} | wc -l) / $(echo $(grep -r W ~/logs/${Name} | wc -l)  +  $(grep -r F ~/logs/${Name} | wc -l) | bc)\) "* 100" | bc -l
