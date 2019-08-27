#!/bin/sh

host=$PT_host
votes=$PT_votes
priority=$PT_priority
hidden=$PT_hidden
replica_set=$PT_repset
port=$PT_port
x509_path=$PT_x509_path
ca_path=$PT_ca_path
count=$PT_count
user=$PT_user
password=$PT_password
primary=$PT_primary
slavedelay=$PT_slavedelay
arbiter=$PT_arbiter
primary_pt=$PT_primary_pt

host_data="{ _id: ${count}, host: '${host}:${port}', priority: ${priority}, votes: ${votes}, arbiterOnly: ${arbiter}, hidden: ${hidden}, slaveDelay: ${slavedelay} }"
let count+=1
echo $host_data
if [ ! -z "${x509_path}" ] && [ "${x509_path}" != 'null' ]; then
  out=$(mongo "mongodb://${user}:${password}@${primary}:${primary_pt}/?replicaSet=${replica_set}&authSource=admin&authMechanism=SCRAM-SHA-256" --ssl --sslAllowInvalidHostnames --sslPEMKeyFile ${x509_path} --sslCAFile ${ca_path} --eval "rs.add( ${host_data} )")
else
  out=$(mongo "mongodb://${user}:${password}@${primary}:${primary_pt}/?replicaSet=${replica_set}&authSource=admin&authMechanism=SCRAM-SHA-256" --eval "rs.add( ${host_data} )")
fi
exit_code=$?
echo $out
if [ $exit_code -eq 252 ] || [ $exit_code -eq 0 ]; then
  exit 0
else
  exit $exit_code
fi