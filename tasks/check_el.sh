#!/bin/sh

if [ ! -f '/bin/yum' ] || [ ! -f '/etc/redhat-release' ]; then
  echo "Not an EL system"
  exit 1
fi
