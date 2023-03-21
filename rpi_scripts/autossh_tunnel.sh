#!/bin/sh
### BEGIN INIT INFO
# Provides:          autossh
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the autossh
# Description:       starts the autossh
### END INIT INFO
 
case "$1" in
    start)
    echo "start autossh"
    killall -0 autossh
    if [ $? -ne 0 ];then
       # Need to modify the user@server.ca in the command
       sudo /usr/bin/autossh -M 888 -fN -o "PubkeyAuthentication=yes" -o "StrictHostKeyChecking=false" -o "PasswordAuthentication=no" -o "ServerAliveInterval 1800" -o "ServerAliveCountMax 3" -R 8022:localhost:22 -i/home/pi/.ssh/id_rsa user@server.ca
    fi
    ;;
    stop)
    sudo killall autossh
    ;;
    restart)
    sudo killall autossh
    # Need to modify the user@server.ca in the command
    sudo /usr/bin/autossh -M 888 -fN -o "PubkeyAuthentication=yes" -o "StrictHostKeyChecking=false" -o "PasswordAuthentication=no" -o "ServerAliveInterval 1800" -o "ServerAliveCountMax 3" -R 8022:localhost:22 -i/home/pi/.ssh/id_rsa user@server.ca
    ;;
    *)
    echo "Usage: $0 (start|stop|restart)"
    ;;
esac
exit 0
