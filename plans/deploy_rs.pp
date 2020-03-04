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
  Optional[String[1]] $curl_ca_file_path       = undef,
  Boolean             $enable_encryption       = true,
  Boolean             $enable_kerberos         = true,
  Optional[String[1]] $encryption_keyfile_path = undef,
  Optional[String[1]] $keytab_file_path        = undef,
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
  $_replica_set_members = $replica_set_members.map |$v| {
    $new = $v.reduce({}) |$x, $y| {
      $x + {$y[0] => $_defaults + $y[1]}
    }
    $new
  }

  $new_config = $current_state.first.value + epp('mongodb::new_rs.epp', {
    replica_set_members => $_replica_set_members
  })

  return $new_config
}
