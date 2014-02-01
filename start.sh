#!/bin/bash
#
# This should contain necessary code to start the service

if ! ps -ef | grep "/etc/frontview/addons/bin/AUTONFS/AUTONFS_service" | grep -v grep &> /dev/null; then
  start-stop-daemon -S -b -m --pidfile /var/run/AUTONFS.pid -q -x /etc/frontview/addons/bin/AUTONFS/AUTONFS_service
fi
