#!/bin/bash
#
# This should contain necessary code to stop the service

LOG_PATH=/var/log/frontview
LOGFILE=$LOG_PATH/autofs.log

. /etc/default/services

DELIMITER="|"                                                    
IFS='%20' read -a MOUNTS <<< "$AUTONFS_MOUNTS"
LOG=true

# End of configuration

function log {
    if $LOG; then
        echo "$(date +%F-%T) $1" >> $LOGFILE 
    fi
}

start-stop-daemon --stop  --pidfile /var/run/AUTONFS.pid --signal KILL --quiet

if [ "$1" == "UNMOUNT" ]; then
  declare -a MOUNTP

  for MOUNT in ${MOUNTS[@]}; do
    # Split up the share into the remote and local mount point.
    MOUNTP=(`echo ${MOUNT//$DELIMITER/ }`)
    # The second part of the mount string is the local mount point.
    # If there is no second part, local and remote are mounted on
    # the same location.
    HERE=${MOUNTP[${#MOUNTP[@]}-1]}
    THERE=${MOUNTP[0]}

    if grep -qsE "^([^ ])+ ${HERE}" /proc/mounts; then
      # NFS mount is still mounted; attempt umount
      log "options changed, unmounting NFS share ${HERE}."
      umount -f ${HERE}
    fi
  done
fi
