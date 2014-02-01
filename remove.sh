#!/bin/bash

SERVICE=AUTONFS
CONF_FILES=""
PROG_FILES="/etc/frontview/apache/addons/AUTONFS.conf* \
            /etc/frontview/addons/*/AUTONFS"

# Stop service from running
eval `awk -F'!!' "/^${SERVICE}\!\!/ { print \\$5 }" /etc/frontview/addons/addons.conf`

# Remove program files
if ! [ "$1" = "-upgrade" ]; then
  # Remove entries from services file
  sed -i "/^${SERVICE}[_=]/d" /etc/default/services

  if [ "$CONF_FILES" != "" ]; then
    for i in $CONF_FILES; do
      rm -rf $i &>/dev/null
    done
  fi
fi

if [ "$PROG_FILES" != "" ]; then
  for i in $PROG_FILES; do
    rm -rf $i
  done
fi

# Remove entry from addons.conf file
sed -i "/^${SERVICE}\!\!/d" /etc/frontview/addons/addons.conf

# Reread modified service configuration files
killall -USR1 apache-ssl

# Now remove ourself
rm -f $0

exit 0
