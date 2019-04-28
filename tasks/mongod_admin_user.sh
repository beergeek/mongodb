#!/bin/sh

user=$PT_user
passwd=$PT_passwd
port=$PT_port
x509_path=$PT_x509_path
ca_path=$PT_ca_path

if [ ! -z "${x509_path}" ] && [ "${x509_path}" != 'null' ]; then
echo "db.createUser( { 'user': '${user}', 'pwd': '${passwd}', roles: [ { 'db': 'admin', 'role': 'root'} ] } )"
mongo admin --port $port --ssl --sslAllowInvalidHostnames --sslPEMKeyFile ${x509_path} --sslCAFile ${ca_path} --eval "db.createUser( { 'user': '${user}', 'pwd': '${passwd}', roles: [ { 'db': 'admin', 'role': 'root'} ] } )"
else
mongo admin --port $port --eval "db.createUser( { 'user': '${user}', 'pwd': '${passwd}', roles: [ { 'db': 'admin', 'role': 'root'} ] } )"
fi
exit 0