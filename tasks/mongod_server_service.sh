#!/bin/sh

config_file=$PT_config_file
run_as_service=$PT_run_as_service

if [ $run_as_service == true ]; then
  systemctl status mongod.service
  output=$?
  if [ $output -ne 0 ]; then
    systemctl start mongod.service
    result=$?
    if [ $result -eq 0 ] || [ $result -eq 2 ]; then
      exit 0
    fi
  else
    echo "Mongod instance is already running, we are too scared to restart!"
    exit 0
  fi
else
  ps aux | grep "mongod -f ${config_file}" | grep -v grep
  output=$?
  if [ $output -eq 1 ]; then
    mongod -f ${config_file}
  else
    echo "Mongod instance is already running, we are too scared to restart!"
    exit 0
  fi
fi