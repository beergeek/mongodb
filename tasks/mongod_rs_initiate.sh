#!/bin/sh

nodes=$PT_nodes
repset=$PT_repset
port=$PT_port
x509_path=$PT_x509_path
ca_path=$PT_ca_path
sharding=$PT_sharding

IFS=',' read -ra node_list <<< "${nodes}"
count=0
for i in "${node_list[@]}"
do
  if [ $count -ne 0 ]; then
    host_data="${host_data},"
  fi
  host_data="${host_data}{ _id: ${count}, host: '${i}:${port}' }"
  let count+=1
done
echo $host_data
if [ $sharding == 'configsvr' ] && [ ! -z "${x509_path}" ] && [ "${x509_path}" != 'null' ]; then
mongo admin --port $port --ssl --sslAllowInvalidHostnames --sslPEMKeyFile ${x509_path} --sslCAFile ${ca_path} --eval "rs.initiate( { _id: '${repset}', configsvr: true, members: [ ${host_data} ]} )"
elif [ ! -z "${x509_path}" ] && [ "${x509_path}" != 'null' ]; then
mongo admin --port $port --ssl --sslAllowInvalidHostnames --sslPEMKeyFile ${x509_path} --sslCAFile ${ca_path} --eval "rs.initiate( { _id: '${repset}', version: 1, members: [ ${host_data} ]} )"
else
mongo admin --port $port --eval "rs.initiate( { _id: '${repset}', version: 1, members: [ ${host_data} ]} )"
fi