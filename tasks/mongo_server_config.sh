#!/bin/sh

config_file=$PT_config_file
dbpath=$PT_db_path
logfile=$PT_log_file
base_path=$PT_base_path
sharding=$PT_sharding
repset=$PT_repset
keyfile=$PT_keyfile
keyfile_path=$PT_keyfile_path
bindnic=$PT_bindnic
port=$PT_port
mongodb_user=$PT_mongodb_service_user
extra_config=$PT_extra_config

mkdir -p "$base_path"
mkdir -p "$dbpath"
mkdir -p $(dirname $keyfile_path)
chown -R $mongodb_user $base_path
chown -R $mongodb_user $dbpath
chown -R $mongodb_user $(dirname $keyfile_path)

bindip=`ifconfig ${bindnic} | grep 'inet ' | awk '{print $2}'`


# add common base to config file
cat <<EOF > $config_file
replication:
  replSetName: $repset
security:
  authorization: enabled
  keyFile: $keyfile_path
net:
  bindIp: localhost,$bindip
  port: $port
systemLog:
  destination: file
  path: $logfile
  logAppend: true
processManagement:
  fork: true
storage:
  dbPath: $dbpath
EOF

# add sharding to config file if supplied
if [ ! -z "${sharding}" ] && [ $sharding -ne 'NULL' ]; then
  cat <<EOF >> $config_file
sharding:
  clusterRole: $sharding
EOF
fi

# add extra config to config file if supplied
if [ ! -z "${extra_config}" ] && [ $extra_config -ne 'NULL' ]; then
cat <<EOF >> $config_file
$extra_config
EOF
fi

# create keyfile
echo $keyfile > $keyfile_path
chown -R $mongodb_user $keyfile_path
chmod 0400 $keyfile_path