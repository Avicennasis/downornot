FailCount=0

while [ 1 ]
do
	wget -O /dev/null --tries=1 ${URL}
	if [ $? -eq 0 ]; then
		echo "$(date '+%Y %b %d %H:%M:%S') - Up and running"
		mkdir -p "${HOME}/logs/${Name}/$(date '+%Y/%m')"
		echo "W - $(date '+%Y %b %d %H:%M:%S') - Up and running" >>~/logs/${Name}/"$(date '+%Y')"/"$(date '+%m')"/"$(date '+%Y-%m-%d')".log
		if [ "${FailCount}" -gt 3 ]; then
			echo "$(date '+%Y %b %d %H:%M:%S') FailCount:${FailCount}" | mail -s "${URL} is back up and running." ${Email}
			FailCount=0
		fi
	else
		mkdir -p "${HOME}/logs/${Name}/$(date '+%Y/%m')"
		echo "$(date '+%Y %b %d %H:%M:%S') - ${URL} IS DOWN!"
		echo "F - $(date '+%Y %b %d %H:%M:%S') - ${URL} IS DOWN!" >>~/logs/${Name}/"$(date '+%Y')"/"$(date '+%m')"/"$(date '+%Y-%m-%d')".log
		FailCount=${FailCount}+1
		if [ "${FailCount}" == 4 ]; then
			echo "$(date '+%Y %b %d %H:%M:%S')" | mail -s "${URL} IS DOWN!" ${Email}
		fi
	fi
	sleep 0.3
done
