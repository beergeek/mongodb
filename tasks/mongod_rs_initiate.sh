#!/bin/sh

host=$PT_host
votes=$PT_votes
priority=$PT_priority
hidden=$PT_hidden
repset=$PT_repset
port=$PT_port
x509_path=$PT_x509_path
ca_path=$PT_ca_path
slavedelay=$PT_slavedelay
arbiter=$PT_arbiter

host_data="{ _id: 0, host: '${host}:${port}', priority: ${priority}, votes: ${votes}, arbiterOnly: ${arbiter}, hidden: ${hidden}, slaveDelay: ${slavedelay} }"
let count+=1
echo $host_data
if [ ! -z "${x509_path}" ] && [ "${x509_path}" != 'null' ]; then
  out=$(mongo admin --port $port --ssl --sslAllowInvalidHostnames --sslPEMKeyFile ${x509_path} --sslCAFile ${ca_path} --eval "rs.initiate({ _id: '${repset}', members: [${host_data}] })")
else
  out=$(mongo admin --port $port --eval "rs.initiate({ _id: '${repset}', members: [${host_data}] })")
fi
exit_code=$?
echo $out
if [ $exit_code -eq 252 ] || [ $exit_code -eq 0 ]; then
  exit 0
else
  exit $exit_code
fi