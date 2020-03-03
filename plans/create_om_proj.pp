plan mongodb::create_om_proj (
  String[1]                                                  $proj_name,
  String[24]                                                 $org_id,
  String[1]                                                  $curl_token,
  String[1]                                                  $curl_username,
  String[1]                                                  $ops_manager_url,
  Enum['MONGODB-CR','SCRAM-SHA-256','GSSAPI','PLAIN']        $auto_auth_mech              = 'SCRAM-SHA-256',
  Array[Enum['MONGODB-CR','SCRAM-SHA-256','GSSAPI','PLAIN']] $auto_auth_mechs             = [ 'SCRAM-SHA-256' ],
  Array[Enum['MONGODB-CR','SCRAM-SHA-256','GSSAPI','PLAIN']] $deployment_auth_mechs       = [ 'SCRAM-SHA-256' ],
  Boolean                                                    $enable_kerberos             = true,
  Enum['REQUIRED','OPTIONAL']                                $client_cert_weak_mode       = 'OPTIONAL',
  Enum['none','preferSSL','requireSSL']                      $ssl_mode                    = 'preferSSL',
  Optional[String]                                           $auto_ldap_group_dn          = undef,
  Optional[String[1]]                                        $aa_pem_file_path            = undef,
  Optional[String[1]]                                        $ca_file_path                = undef,
  Optional[String[1]]                                        $curl_ca_file_path           = undef,
  Optional[String[1]]                                        $keytab_file_path            = undef,
  Optional[String[1025]]                                     $agent_key                   = undef,
  Optional[String[1]]                                        $inital_auto_agent_pwd       = undef,
  Optional[String[1]]                                        $inital_backup_agent_pwd     = undef,
  Optional[String[1]]                                        $inital_monitoring_agent_pwd = undef,
  String[1]                                                  $mongodb_version             = '4.2.2-ent',
  String[1]                                                  $mongodb_compat_version      = '4.2',


  Optional[Array[Struct[{
    Optional[authentication_restrictions]                            => Optional[Array],
    Optional[db]                                                     => Optional[String],
    Optional[privileges]                                             => Optional[Array[Struct[{
      actions                                                        => Array[String[1]],
      resource                                                       => Struct[{
        collection                                                   => String,
        db                                                           => String,
      }],
    }]]],
    role                                                             => String[1],
    Optional[roles]                                                  => Array[Struct[{
      db                                                             => String,
      role                                                           => String,
    }]],
  }]]]                                   $custom_roles                = undef,
) {
  if $ssl_mode != 'none' and !$ca_file_path {
    fail("The `ca_file_path` must be provided if `ssl_mode` is not 'none'")
  }
  if $ssl_mode != 'none' and !$aa_pem_file_path {
    fail("The `aa_pem_file_path` must be provided if `ssl_mode` is not 'none'")
  }

  if !$agent_key {
    $_agent_key = run_command('/bin/openssl rand -hex 512', 'localhost').first.value['stdout'].chop()
  } else {
    $_agent_key = $agent_key
  }
  if !$inital_auto_agent_pwd {
    $_inital_auto_agent_pwd = run_command('/bin/openssl rand -base64 32', 'localhost').first.value['stdout'].chop()
  } else {
    $_inital_auto_agent_pwd = $inital_auto_agent_pwd
  }
  if !$inital_backup_agent_pwd {
    $_inital_backup_agent_pwd = run_command('/bin/openssl rand -base64 32', 'localhost').first.value['stdout'].chop()
  } else {
    $_inital_backup_agent_pwd = $inital_backup_agent_pwd
  }
  if !$inital_monitoring_agent_pwd {
    $_inital_monitoring_agent_pwd = run_command('/bin/openssl rand -base64 32', 'localhost').first.value['stdout'].chop()
  } else {
    $_inital_monitoring_agent_pwd = $inital_monitoring_agent_pwd
  }

  $projects = run_task('mongodb::get_projects', 'localhost',{
    curl_ca_cert_path => $curl_ca_file_path,
    curl_token        => $curl_token,
    curl_username     => $curl_username,
    ops_manager_url   => $ops_manager_url,
    org_id            => $org_id,
  })

  $projects.first['results'].each |Hash $proj_data| {
    if $proj_data['name'] == $proj_name {
      fail('Project already exists')
    }
  }

  $new_proj = run_task('mongodb::make_project', 'localhost', {
    curl_ca_cert_path => $curl_ca_file_path,
    curl_token        => $curl_token,
    curl_username     => $curl_username,
    ops_manager_url   => $ops_manager_url,
    org_id            => $org_id,
    project_name      => $proj_name,
  })

  $proj_data_hash = epp('mongodb/new_om_proj.epp', {
    agent_key                   => $_agent_key,
    aa_pem_file_path            => $aa_pem_file_path,
    client_cert_weak_mode       => $client_cert_weak_mode,
    auto_auth_mech              => $auto_auth_mech,
    auto_auth_mechs             => $auto_auth_mechs,
    auto_ldap_group_dn          => $auto_ldap_group_dn,
    ca_file_path                => $ca_file_path,
    custom_roles                => $custom_roles,
    deployment_auth_mechs       => $deployment_auth_mechs,
    inital_auto_agent_pwd       => $_inital_auto_agent_pwd,
    inital_backup_agent_pwd     => $_inital_backup_agent_pwd,
    inital_monitoring_agent_pwd => $_inital_monitoring_agent_pwd,
    ssl_mode                    => $ssl_mode,
    auto_keytab_path            => $keytab_file_path,
  })

  $basic_config = run_task('mongodb::deploy_instance', 'localhost', {
    curl_ca_cert_path => $curl_ca_file_path,
    curl_token        => $curl_token,
    curl_username     => $curl_username,
    ops_manager_url   => $ops_manager_url,
    project_id        => $new_proj.first['id'],
    json_payload      => $proj_data_hash,
  })

  return "Plan run success was: ${basic_config.ok}. Project ID: ${new_proj.first['id']}. mmsApiKey: ${new_proj.first['agentApiKey']}"

}
