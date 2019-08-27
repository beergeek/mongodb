#!/bin/sh

user=$PT_user
passwd=$PT_passwd
port=$PT_port
x509_path=$PT_x509_path
ca_path=$PT_ca_path

if [ ! -z "${x509_path}" ] && [ "${x509_path}" != 'null' ]; then
  echo "mongo --host 127.0.0.1 --port ${port}  --ssl --sslAllowInvalidHostnames --sslPEMKeyFile ${x509_path} --sslCAFile ${ca_path} --eval \"db.createUser( { 'user': '${user}', 'pwd': '${passwd}', roles: [ { 'db': 'admin', 'role': 'root'} ], 'mechanisms': ['SCRAM-SHA-256'] } )\" admin"
  user_out=$(mongo  --host 127.0.0.1 --port ${port} --ssl --sslAllowInvalidHostnames --sslPEMKeyFile ${x509_path} --sslCAFile ${ca_path} --eval "db.createUser( { 'user': '${user}', 'pwd': '${passwd}', roles: [ { 'db': 'admin', 'role': 'root'} ], 'mechanisms': ['SCRAM-SHA-256'] } )" admin)
else
  user_out=$(mongo  --host 127.0.0.1 --port ${port} --eval "db.createUser( { 'user': '${user}', 'pwd': '${passwd}', roles: [ { 'db': 'admin', 'role': 'root'} ], 'mechanisms': ['SCRAM-SHA-256'] } ) admin")
fi
exit_code=$?
echo $user_out
if [ $exit_code -eq 0 ]; then
  exit 0
else
  exit $exit_code
fi