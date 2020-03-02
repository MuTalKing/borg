#!/bin/bash
BORG_SERVER="borg@borg-server"
NAMEOFBACKUP=${1}
DIRS=${2}
REPOSITORY="${BORG_SERVER}:$(hostname)-${NAMEOFBACKUP}"

borg create --list -v --stats \
  $REPOSITORY::"files-{now:%Y-%m-%d_%H:%M:%S}" \
  $(echo $DIRS | tr ',' ' ') || \
   echo "borg create failed"
