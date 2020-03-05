plan mongodb::deploy_rs (
  Hash[
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
  ]                                     $replica_set_members,
  String[24]                            $project_id,
  String[1]                             $curl_token,
  String[1]                             $curl_username,
  String[1]                             $ops_manager_url,
  String[1]                             $replica_set_name,
  Boolean                               $enable_encryption       = false,
  Boolean                               $enable_kerberos         = true,
  Enum['none','preferSSL','requireSSL'] $ssl_mode                = 'preferSSL',
  Enum['none','x509','keyFile']         $cluster_auth_type       = 'x509',
  Optional[String[1]]                   $client_certificate_path = '/data/pki/server.pem',
  Optional[String[1]]                   $curl_ca_file_path       = undef,
  Optional[String[1]]                   $encryption_keyfile_path = undef,
  Optional[String[1]]                   $keytab_file_path        = undef,
  Optional[String[1]]                   $kmip_key_id             = undef,
  Optional[String[1]]                   $kmip_server             = undef,
  Optional[Integer[1,65535]]            $kmip_port               = 5696,
  Optional[String[1]]                   $kmip_client_cert_path   = $client_certificate_path,
  Optional[String[1]]                   $kmip_ca_cert_path       = undef,
  String[1]                             $db_path                 = '/data/db',
  String[1]                             $log_file_path           = '/data/logs/mongodb.log',
  String[1]                             $mongodb_compat_version  = '4.2',
  String[1]                             $mongodb_version         = '4.2.3-ent',
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

  # we have to merge the defaults into each hash of the array.....
  # Try not to let your brain explode!
  $_replica_set_members_data = $replica_set_members.reduce({}) |$k, $v| {
    $k + {$v[0] => merge($_defaults, $replica_set_members[$v[0]])}
  }

  # Create the processes hash
  $_replica_set_members = $_replica_set_members_data.map() |$v| {
    $member_data = merge($_defaults + $v[1])

    # Network and replication options
    $net_and_rep = {
      'net' => {
        'bindIpAll'    => true,
        'port'         => $member_data['port'],
        'ssl' => {
          'PEMKeyFile' => $client_certificate_path,
          'mode'       => $ssl_mode
        }
      },
      'replication' => {
        'replSetName'  => $replica_set_name
      },
    }

    # Create the security options
    if $cluster_auth_type == 'keyfile' {
      $auth = {
        'clusterAuth' => $cluster_auth_type,
        'keyFile'     => $auth_keyfile_path
      }
    } else {
      $auth = {
        'clusterAuth' => $cluster_auth_type
      }
    }
    if $enable_encryption{
      if $kmip_server {
        $ear = {
            'enableEncryption'        => true,
            'kmip'  => {
              'keyIdentifier'         => $kmip_key_id,
              'serverName'            => $kmip_server,
              'port'                  => $kmip_port,
              'clientCertificateFile' => $kmip_client_cert_path,
              'serverCAFile'          => $kmip_ca_cert_path,
            }
        }
      } else {
        $ear = {
              'enableEncryption'      => true,
              'encryptionKeyFile'     => $encryption_keyfile_path
        }
      }
    } else {
      $ear = {}
    }

    # Combine the security info
    $security = {
      'security' => $auth + $ear
    }

    # Make the storage and log options
    $storage_and_log = {
      'storage' => {
        'dbPath'                  => $db_path,
        'directoryPerDB'          => true,
        'wiredTiger' => {
          'collectionConfig'      => { },
          'engineConfig'          => {
            'directoryForIndexes' => true
          },
          'indexConfig'           => { }
        }
      },
      'systemLog' => {
        'destination' => 'file',
        'path'        => $log_file_path
      }
    }

    # All other options
    $other = {
      'authSchemaVersion'           => 5,
      'disabled'                    => false,
      'featureCompatibilityVersion' => $mongodb_compat_version,
      'hostname'                    => $v[0],
      'logRotate' => {
        'sizeThresholdMB'           => 1000.0,
        'timeThresholdHrs'          => 24
      },
      'manualMode'                  => false,
      'name'                        => $v[0],
      'processType'                 => 'mongod',
      'version'                     => $mongodb_version
    }
    if $enable_kerberos {
      $krb5 = {
        'kerberos' => {
          'keytab' => $keytab_file_path
        }
      }
    }
    $x = merge({'args2_6' => merge($net_and_rep, $security, $storage_and_log)}, $krb5, $other)
  }

  # Create the replicaSets hash
  $replica_sets_data = $_replica_set_members_data.map() |$member_fqdn, $member_data| {
    $k = {
      '_id'          => $member_data['id'],
      'arbiterOnly'  => $member_data['arbitor'],
      'buildIndexes' => $member_data['build_indexes'],
      'hidden'       => $member_data['hidden'],
      'host'         => $member_fqdn,
      'priority'     => $member_data['priority'],
      'slaveDelay'   => $member_data['slave_delay'],
      'votes'        => $member_data['vote']
    }
  }

  $replica_sets =  {
    '_id'             => $replica_set_name,
    'members'         => $replica_sets_data,
    'protocolVersion' => '1',
    'settings'        => { },
  }

  $proj_data_hash = merge($current_state.first.value, {'processes' => $_replica_set_members}, {'replicaSets' => [$replica_sets]})

  # Remove the build info to make the payload smaller
  $new_hash = $current_state.first.value.reduce({}) |$current, $value| {
    if $value[0] != 'mongodbVersions' {
      notice($current)
      notice($value[0])
      $current + {$value[0] => $value[1]}
    } else {
      $current
    }
  }

  $new_deployment = run_task('mongodb::deploy_instance', 'localhost', {
    curl_ca_cert_path => $curl_ca_file_path,
    curl_token        => $curl_token,
    curl_username     => $curl_username,
    ops_manager_url   => $ops_manager_url,
    project_id        => $project_id,
    json_payload      => $new_hash.first.value,
  })

  return $new_deployment
}
