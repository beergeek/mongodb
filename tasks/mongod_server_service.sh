#!/bin/sh

config_file=$PT_config_file
run_as_service=$PT_run_as_service
service_name=$PT_service_name

if [ $run_as_service == true ]; then
  systemctl status $service_name
  output=$?
  if [ $output -ne 0 ]; then
    systemctl start $service_name
    result=$?
    if [ $result -eq 0 ] || [ $result -eq 2 ]; then
      echo "Mongod instance started"
      exit 0
    else
      echo "Mongod instance failed"
      exit $result
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