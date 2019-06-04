# A plan to deploy instances of MongoDB via Ops Manager API.
#
# @summary A plan to deploy instances of MongoDB via Ops Manager API.
# @note REQUIRES Bolt 1.8.0
#
# @param replica_set_members A hash of hashes describing the members of the replica set.
#   The root level keys are the FQDNs of the replica set members.
#   The sub-hash must contain the `id` of the host for the replica set.
#   The following are the defaults for each sub-hash:
#   {
#     'arbitor'       => false,
#     'build_indexes' => true,
#     'hidden'        => false,
#     'port'          => 27017,
#     'priority'      => 1,
#     'slave_delay'   => 0,
#     'vote'          => 1,
#   }
#   Optional keys of each sub-hash:
#   * 'pem_file_path' absolute path to PEM file
# @param curl_token The token to be used with cURL to authenticate with Ops Manager API.
# @param curl_username The username to be used with cURL to authenticate with Ops Manager API.
# @param ops_manager_url The URL for the Ops Manager, including the port number. The end point
#   is not required.
# @param project_id The Project ID to where to create the new replica set.
# @param replica_set_name The name of the new replica set.
# @param node The hostname or IP address of the nodes to run the API calls from.
# @param enable_encryption A boolean to determine if encryption-at-rest is enabled or not.
# @param enable_kerberos A boolean to determine if Kerberos authentication is enabled.
# @param ssl_mode The mode that will be used for SSL/TLS.
# @param cluster_auth_type The type of cluster authentication to use between members of the replica set.
# @param aa_pem_file_path The absolute path for the PEM file for the automation agent, if SSL/TLS is required.
# @param ca_file_path The absolute path for the CA certificate file for SSL/TLS, if required.
# @param curl_ca_cert_path The absolute path of the CA certificate on the node that will execute the cURL command.
#   Only required if the Ops Manager server is using SSL/TLS.
# @encryption_keyfile_path The absolute path on the replica set nodes where the encryption-at-rest keyfile is located.
#   This is a common path for all nodes. Only required if `enable_encryption` is `true`.
# @keytab_file_path The absolute path on the replica set nodes where the Kerberos keytab is located for the mongod service.
#   Only required if `enable_kerberos` is `true`.
# @db_path The absolute path where the database files will be located. This path MUST exist prior to execution.
# @inital_auto_agent_pwd An automatically generated password used as the initial password for the automation agent.
# @inital_backup_agent_pwd An automatically generated password used as the initial password for the backup agent.
# @inital_monitoring_agent_pwd An automatically generated password used as the initial password for the monitoring agent.
# @log_file_path The absolute path and filename of the log file. This path MUST exist prior to execution.
# @mongodb_version The MongoDB version to deploy, such as `4.0.9-ent` or `3.6.12-ent`.
#
#
plan mongodb::new_deployment (
  Hash                                  $replica_set_members,
  String[1]                             $curl_token,
  String[1]                             $curl_username,
  String[1]                             $ops_manager_url,
  String[24]                            $project_id,
  String[1]                             $replica_set_name,
  Targetspec                            $node,
  Boolean                               $enable_encryption           = true,
  Boolean                               $enable_kerberos             = true,
  Enum['REQUIRED','OPTIONAL']           $client_cert_weak_mode       = 'OPTIONAL',
  Enum['none','preferSSL','requireSSL'] $ssl_mode                    = 'preferSSL',
  Enum['none','x509','keyFile']         $cluster_auth_type           = 'x509',
  Optional[String[1]]                   $aa_pem_file_path            = undef,
  Optional[String[1]]                   $ca_file_path                = undef,
  Optional[String[1]]                   $curl_ca_cert_path           = undef,
  Optional[String[1]]                   $encryption_keyfile_path     = undef,
  Optional[String[1]]                   $keytab_file_path            = undef,
  String[1]                             $db_path                     = '/data/db',
  String[1]                             $inital_auto_agent_pwd       = generate('/bin/openssl rand -base64 32'),
  String[1]                             $inital_backup_agent_pwd     = generate('/bin/openssl rand -base64 32'),
  String[1]                             $inital_monitoring_agent_pwd = generate('/bin/openssl rand -base64 32'),
  String[1]                             $log_file_path               = '/data/logs/mongodb.log',
  String[1]                             $mongodb_version             = '4.0.9-ent',
  String[1]                             $mongodb_compat_version      = '4.0',
) {

  if $enable_encryption == true and !$encryption_keyfile_path {
    fail('With `enable_encryption` set to true `encryption_keyfile` must be provided')
  }
  if $enable_kerberos == true and !$keytab_file_path {
    fail('With `enable_kerberos` a common path for `keytab_file_path`')
  }
  if $ssl_mode != 'none' and !$ca_file_path {
    fail("The `ca_file_path` must be provided if `ssl_mode` is not 'none'")
  }
  if $ssl_mode != 'none' and !$aa_pem_file_path {
    fail("The `aa_pem_file_path` must be provided if `ssl_mode` is not 'none'")
  }

  $_defaults = {
    'arbitor'       => false,
    'build_indexes' => true,
    'hidden'        => false,
    'port'          => 27017,
    'priority'      => 1,
    'slave_delay'   => 0,
    'vote'          => 1,
  }

  $replica_set_members.each |String $member_name, Hash $member_data| {
    if $ssl_mode != 'none' and !$member_data['pem_file_path'] {
      fail("When `ssl_mode` is nont 'none' the `pem_file_path` must be provide: ${member_name} is missing this key/value")
    }
    if !$member_data['id'] {
      fail("Each member needs an `id` key/value: ${member_name} is missing this key/value")
    }
  }

  # This hurts my head.......takes a while to explain this in detail.
  $_replica_set_members = $replica_set_members.reduce({}) |$k, $v| {
    $k + {$v[0] => merge($_defaults, $replica_set_members[$v[0]])}
  }

  $last_member = $_replica_set_members.keys[size($_replica_set_members.keys)-1]

  $json_payload = epp('mongodb/deployment.epp', {
    aa_pem_file_path            => $aa_pem_file_path,
    ca_file_path                => $ca_file_path,
    client_cert_weak_mode       => $client_cert_weak_mode,
    cluster_auth_type           => $cluster_auth_type,
    db_path                     => $db_path,
    enable_encryption           => $enable_encryption,
    enable_kerberos             => $enable_kerberos,
    encryption_keyfile_path     => $encryption_keyfile_path,
    inital_auto_agent_pwd       => $inital_auto_agent_pwd,
    inital_backup_agent_pwd     => $inital_backup_agent_pwd,
    inital_monitoring_agent_pwd => $inital_monitoring_agent_pwd,
    keytab_file_path            => $keytab_file_path,
    last_member                 => $last_member,
    log_file_path               => $log_file_path,
    mongodb_compat_version      => $mongodb_compat_version,
    mongodb_version             => $mongodb_version,
    replica_set_members         => $_replica_set_members,
    replica_set_name            => $replica_set_name,
    ssl_mode                    => $ssl_mode,
  })

  run_task('mongodb::deploy_instance', $node, {
    curl_ca_cert_path => $curl_ca_cert_path,
    curl_token        => $curl_token,
    curl_username     => $curl_username,
    json_payload      => $json_payload,
    ops_manager_url   => $ops_manager_url,
    project_id        => $project_id,
  })
}
