#!/bin/sh

LOG_FILE="/var/log/auth.log"  # For Debian-based systems
OUTPUT_LOG="/var/log/sshloginhistory.log"
# Notification function
notify() {
    local MESSAGE=$1
    echo "$MESSAGE" >> $OUTPUT_LOG
    sendToDiscord "$MESSAGE"
}

# Function to send message to discord using webhook
sendToDiscord()
{
        DISCORD_URL=$SSH_DISCORD_WEBHOOK_URL
        local MESSAGE=$1
        TITLE=""
		if  [ -z `echo $HOST_NAME` ]; then
			hostname=`hostname`
		else
			hostname=$HOST_NAME
		fi

        USERNAME="$hostname-logintracker"
        TITLE="SSH Login on $hostname"
        JSON=''
        JSON='{"username": "'$USERNAME'","embeds":[{"description":"'$MESSAGE'","title": "'$TITLE'"}]}'
        echo $JSON
        curl -s -X POST -H "Content-Type: application/json" -d "$JSON" $DISCORD_URL
}

if  [ -z `echo $HOST_NAME` ]; then
	hostname=`hostname`
else
	hostname=$HOST_NAME
fi

inotifywait -m -e modify "$LOG_FILE" | while read path _ file; do
    if tail -n 3 "$LOG_FILE" | grep "Accepted password for" > /dev/null; then
        USER=$(tail -n 3 "$LOG_FILE" | grep "Accepted password for" | tail -1 | awk '{print $9}')
        IP=$(tail -n 3 "$LOG_FILE" | grep "Accepted password for" | tail -1 | awk '{print $11}')
	DATETIME=$(tail -n 3 $LOG_FILE | grep "Accepted password for" | tail -1 | tail -1 | cut -d " " -f 1-3)
	MESSAGE="SSH Login: $DATETIME HOSTNAME:$hostname User:$USER from IP:$IP"
        notify "$MESSAGE"
    elif tail -n 3 "$LOG_FILE" | grep "Accepted publickey for" > /dev/null; then
        USER=$(tail -n 3 "$LOG_FILE" | grep "Accepted publickey for" | tail -1 | awk '{print $9}')
        IP=$(tail -n 3 "$LOG_FILE" | grep "Accepted publickey for" | tail -1 | awk '{print $11}')
	DATETIME=$(tail -n 3 "$LOG_FILE" | grep "Accepted publickey for" | tail -1 | cut -d " " -f 1-3)
        MESSAGE="SSH Login: $DATETIME HOSTNAME:$hostname User:$USER from IP:$IP"
        notify "$MESSAGE"
    fi
done

