#!/bin/bash

# Example of argument file:
#167.88.44.177 test.ozzy-boshi.com. curl -o /tmp/test1 -m 10 -s 168.235.146.117
#104.233.78.98 test.ozzy-boshi.com. curl -o /tmp/test2 -m 10 -s 104.233.93.151

BINDPATH="/data/bind/lib"

function updatecounter {
	RES=$(sed '4q;d' ${BINDPATH}/${DNS}hosts)
	RES="$(echo -e "${RES}" | tr -d '[:space:]')"
	OLDDATE=$(echo $RES | cut -c1-8)
	if [ $(date +%Y%m%d) -gt $OLDDATE ]
	then
		DNS_COUNTER=0
	else
		DNS_COUNTER="${RES: -2}"
		DNS_COUNTER=$(printf '%0d' $(echo $DNS_COUNTER | sed 's/^0*//'))
		let DNS_COUNTER=DNS_COUNTER+1
	fi
	printf -v DNS_COUNTER "%02d" $DNS_COUNTER
	sed -i "4d" ${BINDPATH}/${DNS}hosts
	sed  -i "4i `date +'\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ '%Y%m%d$DNS_COUNTER`" ${BINDPATH}/${DNS}hosts
	rndc reconfig
	rndc reload
}

while :
do
	while IFS='' read -r line || [[ -n "$line" ]]; do
		IP=""
		DNS=""
		CMD=""
		COUNTER=0

		for word in $line; do
			case $COUNTER in 
				0)	IP=$word
				;;
				1)	DNS=$word
				;;
				*)	if [ $COUNTER > 1 ] 
					then
						CMD="$CMD $word"
					fi
				;;
			esac
			let COUNTER=COUNTER+1 
		done
		echo "IP:"$IP
		echo "DNS:"$DNS
		echo "CMD:"$CMD
		$CMD
		if [ $? == 0 ]
		then
			grep ${DNS}\ 1\ IN\ A\ ${IP} ${BINDPATH}/${DNS}hosts
			RESULT=$?
			if [[ $RESULT == 0 ]];
			then
				echo "No update needed"
			else
				echo "UPDATE NEEDED"
				echo "${DNS} 1 IN A ${IP}" >> "${BINDPATH}/${DNS}hosts"
				updatecounter
			fi
		else
			grep ${DNS}\ 1\ IN\ A\ ${IP} ${BINDPATH}/${DNS}hosts
			RESULT=$?
			if [[ $RESULT == 0 ]];
			then
				echo "Cmd Ko, removing"
				sed -i'' /${DNS}\ 1\ IN\ A\ ${IP}/d ${BINDPATH}/${DNS}hosts
				updatecounter
			else
				echo "Not present, already removed"
			fi
		fi
		echo "-----------------------------------"
	done < "$1"
sleep 60
done

