plan mongodb::deploy_rs (
  Array[Hash[
    String[1],
    Struct[{
      id                      => Integer[0],
      Optional[arbitor]       => Boolean,
      Optional[build_indexes] => Boolean,
      Optional[hidden]        => Boolean,
      Optional[port]          => Integer[1,65535],
      Optional[priority]      => Integer[0,1000],
      Optional[slave_delay]   => Integer[0],
      Optional[vote]          => Integer[0],
    }]
  ]]                  $replica_set_members,
  String[24]          $project_id,
  String[1]           $curl_token,
  String[1]           $curl_username,
  String[1]           $ops_manager_url,
  String[1]           $replica_set_name,
  Enum['none','preferSSL','requireSSL'] $ssl_mode                    = 'preferSSL',
  Enum['none','x509','keyFile']         $cluster_auth_type           = 'x509',
  Boolean                               $enable_encryption           = false,
  Optional[String[1]] $curl_ca_file_path       = undef,
  Boolean             $enable_kerberos         = true,
  Optional[String[1]] $encryption_keyfile_path = undef,
  Optional[String[1]] $keytab_file_path        = undef,
  Optional[String[1]] $client_certificate_path = undef,
  String[1]           $db_path                 = '/data/db',
  String[1]           $log_file_path           = '/data/logs/mongodb.log',
  String[1]           $mongodb_version         = '4.2.3-ent',
  String[1]           $mongodb_compat_version  = '4.2',
) {

  $_defaults = {
    'arbitor'       => false,
    'build_indexes' => true,
    'hidden'        => false,
    'port'          => 27017,
    'priority'      => 1,
    'slave_delay'   => 0,
    'vote'          => 1,
  }

  $current_state = run_task('mongodb::current_deployment','localhost',{
    curl_token        => $curl_token,
    curl_username     => $curl_username,
    ops_manager_url   => $ops_manager_url,
    curl_ca_cert_path => $curl_ca_file_path,
    project_id        => $project_id,
  })

  #$current_config = $current_state.first.value.reduce({}) |$current, $value| {
  #  if ($value[0] != 'processes') and ($value[0] != 'replicaSets') {
  #    $current + {$value[0] => $value[1]}
  #  } else {
  #    $current
  #  }
  #}

  # we have to merge the defaults into each hash of the array.....
  # Try not to let your brain explode!
  $_replica_set_members = $replica_set_members.reduce({}) |$k, $v| {
    $member_data = merge($_defaults + $v[1])
    $net_and_rep = {
      'net' => {
        'ssl' => {
          'PEMKeyFile' => "${client_certificate_path}",
          'mode' => "${ssl_mode}"
        },
        'bindIpAll' => true,
        'port' => $member_data['port']
      },
      'replication' => {
        'replSetName' => "${replica_set_name}"
      },
    }

    case $cluster_auth_type {
      'none','x509': {
        $auth = {
          'security' => {
            'clusterAuth' => "${cluster_auth_type}"
          }
        }
      }
      'keyfile': {
        $auth = {
          'clusterAuth' => "${cluster_auth_type}",
          'keyFile' => "${auth_keyfile_path}"
        }
      }
    }
    if $enable_encryption{
      $ear = {
            'enableEncryption' => true,
            'encryptionKeyFile' => "${encryption_keyfile_path}"
      }
    } else {
      $ear = {}
    }
    $security = {
      'security' => $auth + $ear
    }
    $storage_and_log = {
      'storage' => {
        'dbPath' => "${db_path}",
        'directoryPerDB' => true,
        'wiredTiger' => {
          'collectionConfig' => { },
          'engineConfig' => {
            'directoryForIndexes' => true
          },
          'indexConfig' => { }
        }
      },
      'systemLog' => {
        'destination' => "file",
        'path' => "${log_file_path}"
      },
      'authSchemaVersion' => 5,
      'disabled' => false,
      'featureCompatibilityVersion' => "${mongodb_compat_version}",
      'hostname' => "${v[0]}",
      'logRotate' => {
        'sizeThresholdMB' => 1000.0,
        'timeThresholdHrs' => 24
      },
      'manualMode' => false,
      'name' => "${v[0]}",
      'processType' => "mongod",
      'version' => "${mongodb_version}"
    }
    if $enable_kerberos {
      $krb5 = {
        'kerberos' => {
          'keytab' => "${keytab_file_path}"
        }
      }
    }
    $k + {$v[0] => {'args2_6' => merge($net_and_rep, $security, $storage_and_log, $krb5)}}
  }

  #$new_config = $current_state.first.value + Hash(epp('mongodb/new_rs.epp', {
  #  replica_set_members => $_replica_set_members,
  #  ssl_mode            => $ssl_mode,
  #  replica_set_name    => $replica_set_name,
  #  cluster_auth_type   => $cluster_auth_type,
  #  enable_encryption   => $enable_encryption,
  #  encryption_keyfile_path => $encryption_keyfile_path,
  #  db_path                 => $db_path,
  #  log_file_path           => $log_file_path,
  #  mongodb_version         => $mongodb_version,
  #  mongodb_compat_version  => $mongodb_compat_version,
  #  enable_kerberos         => $enable_kerberos,
  #  keytab_file_path        => $keytab_file_path,
  #}))

  return $_replica_set_members
}
