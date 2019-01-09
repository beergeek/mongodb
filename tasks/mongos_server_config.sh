#!/bin/sh

config_file=$PT_config_file
logfile=$PT_log_file
base_path=$PT_base_path
keyfile=$PT_keyfile
keyfile_path=$PT_keyfile_path
x509_path=$PT_x509_path
ca_path=$PT_ca_path
bindnic=$PT_bindnic
repset=$PT_repset
port=$PT_port
mongodb_user=$PT_mongodb_service_user
config_svr_list=$PT_config_svr_list
extra_config=$PT_extra_config

mkdir -p "$base_path"
chown -R $mongodb_user $base_path
chown -R $mongodb_user $dbpath

if [ ! -z "${bindnic}" ] && [ "${bindnic}" != 'null' ]; then
  bindip=`ifconfig ${bindnic} | grep 'inet ' | awk '{print $2}'`
else
  bindip=`hostname`
fi

# add common base to config file
cat <<EOF > $config_file
systemLog:
  destination: file
  path: $logfile
  logAppend: true
processManagement:
  fork: true
sharding:
  configDB: ${repset}/${config_svr_list}
net:
  bindIp: localhost,$bindip
  port: $port
EOF

if [ ! -z "${x509_path}" ] && [ $x509_path != 'null' ]; then
cat <<EOF >> $config_file
  ssl:
    mode: requireSSL
    PEMKeyFile: $x509_path
    CAFile: $ca_path
security:
  clusterAuthMode: x509
EOF
elif [ ! -z "${keyfile}" ] && [ $keyfile != 'null' ]; then
cat <<EOF >> $config_file
security:
  authorization: enabled
  keyFile: $keyfile_path
EOF
else
cat <<EOF >> $config_file
security:
  authorization: enabled
EOF
fi

# add extra config to config file if supplied
if [ ! -z "${extra_config}" ] && [ $extra_config != 'null' ]; then
cat <<EOF >> $config_file
$extra_config
EOF
fi

