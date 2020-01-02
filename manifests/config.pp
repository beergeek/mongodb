# Manages the configuration of a mongod instance
#
# @summary Manages the configuration of a mongod instance
#
# @note As this is a defined type we are not using in-module Hiera for defaults (although we
#   do use a `lookup` for some per operating system defaults).
#
# @param debug_kerberos Debug Kerberos sessions, if Kerberos is enabled (via `enabled_kerberos`).
#   The `kerberos_trace_path` must be provided.
# @param enable_kerberos Boolean to determine if Kerberos is enabled.
# @param enable_ldap_authn Boolean to determine if LDAP authentication is enabled.
# @param enable_ldap_authz Boolean to determine if LDAP authorisation is enabled.
#   `enable_ldap_authn` must be 'true' to use the authorisation.
# @param ldap_authz_query The LDAP authorisation query template to determine the user's groups
#   from the user's logon name.
# @param ldap_bind_password The password for the LDAP Bind User.
# @param ldap_bind_username The username of the LDAP Bind User.
# @param ldap_servers A comma-delimited (no spaces) of LDAP server addresses/hostnames.     
# @param ldap_user_mapping The LDAP user mapping statement.
# @param ldap_security The type of transport security for LDAP communications.
# @param kerberos_trace_path Absolute path of the trace file for Kerberos. 
# @param keytab_file_path The absolute path of the Kerberos keytab file.
# @param keyfile_path The absolute path of the member authentication keyfile, if using keyfile for cluster authentication.
# @param wiredtiger_cache_gb The size of the WiredTiger Cache in Gigabytes.
# @param member_auth What, if any, cluster authentication is selected. Possible options: `x509`, `keyfile_path`, or `none`.
# @param repsetname Name of the replica set. Defaults to `$title` of resource.
# @param svc_user The name of the user the mongod instance will run as. Used to modify the 
#   unit file for the service if using SystemD.
# @param conf_file Absolute path where the mongod instance config file should be created.
# @param bindip The FQDN to use in addition to use with localhost for the service to listen.
# @param port The port number for the service.
# @param log_filename Name of the log file.
# @param auth_list The authentication mechanisms. If `enable_kerberos` is true 'GSSAPI' will also be applied.
# @param base_path The base path of where database, logs and certs will be stored.
#   These can be changed individually if desired.
# @param db_base_path Absolute path of where database directory will be located.
# @param db_data_path The absolute path for the database files.
# @param log_path The absolute path of the where log files will be stored.
# @param pid_file The absolute path of the PID file. Changes in the service and config files.
# @param pki_path The absolute path of the where SSL certs, keytabs and keyfiles will be stored.
# @param pem_file The absolute path of the SSL/TLS PEM file.
# @param member_auth The cluster auth type. Options are `none`, keyFile`, or `x509`.
# @param ssl_mode The SSL mode. Options are `requireSSL`, `preferSSL`, or `none`.
# @param cluster_pem_file The absolute path of the cluster auth file, if different to PEM file.
# @param ca_file The absolute path for the CA cert file.
# @param enable_ear Boolean to determine if encryption at rest is enabled
# @param ear_keyfile Keyfile for encryption at rest, overrides KMIP settings
# @param ear_kmip_port KMIP server port    
# @param ear_kmip_ca_cert CA certificate for KMIP server
# @param ear_kmip_client_cert Client certificate to interact with KMIP server
# @param ear_key_id Identifier for KMIP key, if needed
# @param ear_kmip_server Hostname of KMIP server
#
define mongodb::config (
  Boolean                               $debug_kerberos       = false,
  Boolean                               $enable_kerberos      = false,
  Boolean                               $enable_ldap_authn    = false,
  Boolean                               $enable_ldap_authz    = false,
  Enum['none','tls']                    $ldap_security        = 'tls',
  Optional[Sensitive[String[1]]]        $ldap_bind_password   = undef,
  Optional[Stdlib::Absolutepath]        $kerberos_trace_path  = undef,
  Optional[Stdlib::Absolutepath]        $keyfile_path         = undef,
  Optional[Stdlib::Absolutepath]        $keytab_file_path     = undef,
  Optional[String[1]]                   $ldap_authz_query     = undef,
  Optional[String[1]]                   $ldap_bind_username   = undef,
  Optional[String[1]]                   $ldap_servers         = undef,
  Optional[String[1]]                   $ldap_user_mapping    = undef,
  Optional[String[1]]                   $wiredtiger_cache_gb  = undef,
  Stdlib::Absolutepath                  $conf_file            = "${lookup('mongodb::config::conf_path')}/mongod_${title}.conf",
  String[1]                             $auth_list            = 'SCRAM-SHA-1,SCRAM-SHA-256',
  String[1]                             $bindip               = $facts['networking']['fqdn'],
  String[1]                             $log_filename         = "${title}.log",
  Stdlib::Port                          $port                 = 27017,
  String[1]                             $repsetname           = $title,
  String[1]                             $svc_user             = 'mongod',

  # needed before $db_data_path, $db_data_path, $log_base_path and $log_path
  # Base directories
  Stdlib::Absolutepath                  $base_path            = lookup('mongodb::config::base_path'),
  Stdlib::Absolutepath                  $db_base_path         = "${base_path}/db",
  Stdlib::Absolutepath                  $db_data_path         = "${db_base_path}/${title}",
  Stdlib::Absolutepath                  $log_path             = "${base_path}/logs",
  Stdlib::Absolutepath                  $pid_file             = "${lookup('mongodb::config::pid_path')}/${title}.pid",
  Stdlib::Absolutepath                  $pki_path             = "${base_path}/pki",

  # Certificates and SSL/TLS
  Enum['requireSSL','preferSSL','none'] $ssl_mode             = 'requireSSL',
  Enum['x509', 'keyFile', 'none']       $member_auth          = 'x509',
  Optional[Stdlib::Absolutepath]        $cluster_pem_file     = undef,
  Optional[Stdlib::Absolutepath]        $pem_file             = undef,
  Stdlib::Absolutepath                  $ca_file              = "${pki_path}/ca.cert",

  # Encryption At Rest (EAR)
  Boolean                               $enable_ear           = false,
  Optional[Stdlib::Host]                $ear_kmip_server      = undef,
  Optional[Stdlib::Absolutepath]        $ear_keyfile          = undef,
  Optional[Stdlib::Port]                $ear_kmip_port        = undef,
  Optional[Stdlib::Absolutepath]        $ear_kmip_ca_cert     = undef,
  Optional[Stdlib::Absolutepath]        $ear_kmip_client_cert = undef,
  Optional[String]                      $ear_key_id           = undef,
) {

  if $member_auth == 'keyFile' and !($keyfile_path) {
    fail('If `keyFile` is selected for the $member_auth a keyfile location must be provided')
  }

  if ($member_auth == 'x509' or $ssl_mode != 'none') and !($pem_file) {
    fail('The selection of `x509` for $member_auth or enabling SSL/TLS (via $ssl_mode) requires a value for `pem_file`')
  }

  if $debug_kerberos and !($kerberos_trace_path) {
    fail("Of `debug_kerberos` is 'true' a path for `kerberos_trace_path` must be provided")
  }

  if $enable_kerberos and !($keytab_file_path) {
    fail("Of `enable_kerberos` is 'true' a path for `keytab_file_path` must be provided")
  }

  if $enable_ldap_authn and (!($ldap_security) or !($ldap_user_mapping) or !($ldap_bind_password) and !($ldap_bind_username)
  and !($ldap_servers)) {
    fail("When `enable_ldap_authn` is 'true' the following must be provided:\n\t- `ldap_security`\n\t- `ldap_user_mapping`\n\t
    - `ldap_bind_password`\n\t- `ldap_bind_username`\n\t- `ldap_servers`")
  }

  if $enable_ldap_authz and !($ldap_authz_query) {
    fail("If `enable_ldap_authz` is 'true' then `ldap_authz_query` must be provided")
  }

  if $ldap_bind_password {
    $_ldap_bind_password = unwrap($ldap_bind_password)
  } else {
    $_ldap_bind_password = undef
  }

  if $facts['os']['family'] == 'RedHat' {
    File {
      owner   => $svc_user,
      group   => $svc_user,
      seltype => 'mongod_var_lib_t',
      seluser => 'system_u',
    }

    selinux::fcontext { "set-${db_data_path}-context":
      ensure   => present,
      seltype  => 'mongod_var_lib_t',
      seluser  => 'system_u',
      pathspec => "${db_data_path}.*",
      notify   => Exec["selinux-${db_data_path}"],
    }

    exec { "selinux-${db_data_path}":
      command     => "/sbin/restorecon -R -v ${db_data_path}",
      refreshonly => true,
    }
  } else {
    File {
      owner => $svc_user,
      group => $svc_user,
    }
  }

  file { $db_data_path:
    ensure => directory,
    mode   => '0755',
  }

  file { $conf_file:
    ensure  => file,
    mode    => '0400',
    seltype => 'etc_t',
    content => epp('mongodb/config.epp', {
      auth_list            => $auth_list,
      bindip               => "localhost,${bindip}",
      ca_file              => $ca_file,
      cluster_pem_file     => $cluster_pem_file,
      dbpath               => $db_data_path,
      enable_kerberos      => $enable_kerberos,
      enable_ldap_authn    => $enable_ldap_authn,
      enable_ldap_authz    => $enable_ldap_authz,
      keyfile_path         => $keyfile_path,
      ear_kmip_server      => $ear_kmip_server,
      enable_ear           => $enable_ear,
      ear_keyfile          => $ear_keyfile,
      ear_kmip_port        => $ear_kmip_port,
      ear_kmip_ca_cert     => $ear_kmip_ca_cert,
      ear_kmip_client_cert => $ear_kmip_client_cert,
      ear_key_id           => $ear_key_id,
      ldap_authz_query     => $ldap_authz_query,
      ldap_bind_password   => $_ldap_bind_password,
      ldap_bind_username   => $ldap_bind_username,
      ldap_servers         => $ldap_servers,
      ldap_security        => $ldap_security,
      ldap_user_mapping    => $ldap_user_mapping,
      log_filename         => $log_filename,
      logpath              => $log_path,
      member_auth          => $member_auth,
      pem_file             => $pem_file,
      pid_file             => $pid_file,
      port                 => $port,
      repset               => $repsetname,
      ssl_mode             => $ssl_mode,
      wiredtiger_cache_gb  => $wiredtiger_cache_gb,
    })
  }

  if $facts['os']['family'] == 'RedHat' {
    file { "/lib/systemd/system/mongod_${repsetname}.service":
      ensure  => file,
      mode    => '0644',
      seltype => 'mongod_unit_file_t',
      content => epp('mongodb/service_file.epp', {
        conf_file            => $conf_file,
        debug_kerberos       => $debug_kerberos,
        enable_kerberos      => $enable_kerberos,
        kerberos_trace_path  => $kerberos_trace_path,
        kerberos_keytab_path => $keytab_file_path,
        pid_file             => $pid_file,
        pid_path             => dirname($pid_file),
        svc_user             => $svc_user,
      }),
      notify  => Exec["restart_systemd_daemon-${repsetname}"],
    }

    exec { "restart_systemd_daemon-${repsetname}":
      command     => '/usr/bin/systemctl daemon-reload',
      refreshonly => true,
    }
  }
}
