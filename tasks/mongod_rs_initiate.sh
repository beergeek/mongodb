#!/bin/sh

nodes=$PT_nodes
repset=$PT_repset
port=$PT_port

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
echo ${host_data}
echo "rs.initiate( { _id: '${repset}', version: 1, members: [ ${host_data} ]} )"
  
mongo admin --port $port --eval "rs.initiate( { _id: '${repset}', version: 1, members: [ ${host_data} ]} )"
