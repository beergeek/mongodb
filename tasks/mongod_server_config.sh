#!/bin/sh

base_path=$PT_base_path
#bindip=$PT_bindip
#ca_path=$PT_ca_path
config_file=$PT_config_file
config_file_data=$PT_config_file_data
dbpath=$PT_db_path
#extra_config=$PT_extra_config
#keyfile_path=$PT_keyfile_path
logfile=$PT_log_file
mongodb_user=$PT_mongodb_service_user
#port=$PT_port
#repset=$PT_repset
#x509_path=$PT_x509_path

# create directorys with correct ownership
mkdir -p $base_path
mkdir -p $dbpath
mkdir -p $(dirname $logfile)
chown -R $mongodb_user:$mongodb_user $base_path
chown -R $mongodb_user:$mongodb_user $dbpath
chown -R $mongodb_user:$mongodb_user $(dirname $logfile)

# SELinux!
semanage fcontext -a -t mongod_var_lib_t $dbpath.*
semanage fcontext -a -t mongod_log_t $(dirname $logfile).*
chcon -Rv -u system_u -t mongod_var_lib_t $dbpath
chcon -Rv -u system_u -t mongod_log_t $(dirname $logfile)
restorecon -R -v $dbpath
restorecon -R -v $(dirname $logfile)

echo "$config_file_data" > $config_file

## add common base to config file
#cat <<EOF > $config_file
#processManagement:
#  pidFilePath: /var/run/mongodb/mongod.pid
#  fork: true
#replication:
#  replSetName: $repset
#systemLog:
#  destination: file
#  path: $logfile
#  logAppend: true
#storage:
#  dbPath: $dbpath
#  directoryPerDB: true
#  wiredTiger:
#    engineConfig:
#      directoryForIndexes: true
#net:
#  bindIp: localhost,$bindip
#  port: $port
#EOF
#
## determine of a NIC is presented, if not use hostname
#if [ ! -z "${x509_path}" ] && [ $x509_path != 'null' ]; then
#  # confirm there is a path for the CA cert as well
#  if [ -z "${ca_path}" ] || [ $ca_path == 'null' ]; then
#    echo "ERROR: require `ca_path` and `x509_path` for this setting"
#    exit 1
#  fi
#  cat <<EOF >> $config_file
#  ssl:
#    mode: requireSSL
#    PEMKeyFile: $x509_path
#    CAFile: $ca_path
#security:
#  authorization: enabled
#  clusterAuthMode: x509
#EOF
#elif [ ! -z "${keyfile}" ] && [ $keyfile != 'null' ]; then
#  # confirm there is a path for the keyfile as well
#  if [ -z "${keyfile_path}" ] || [ $keyfile_path == 'null' ]; then
#    echo "ERROR: require `keyfile_path` for this setting"
#    exit 1
#  fi
#  # create config for keyfile
#  cat <<EOF >> $config_file
#security:
#  authorization: enabled
#  keyFile: $keyfile_path
#EOF
#else
#cat <<EOF >> $config_file
#security:
#  authorization: enabled
#EOF
#fi
#
## add extra config to config file if supplied
#if [ ! -z "${extra_config}" ] && [ $extra_config != 'null' ]; then
#cat <<EOF >> $config_file
#$extra_config
#EOF
#fi
