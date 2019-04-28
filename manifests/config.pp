# Manages the configuration of a mongod instance
#
# @summary Manages the configuration of a mongod instance
#
# @note As this is a defined type we are not using in-module Hiera for defaults (although we
#   do use a `lookup` for some per operating system defaults).
#
# @param keyfile The absolute path of the member authentication keyfile, if using keyfile for cluster authentication.
# @param member_auth What, if any, cluster authentication is selected. Possible options: `x509`, `keyfile`, or `none`.
# @param repsetname Name of the replica set. Defaults to `$title` of resource.
# @param svc_user The name of the user the mongod instance will run as. Used to modify the 
#   unit file for the service if using SystemD.
# @param conf_file Absolute path where the mongod instance config file should be created.
# @param base_path The base path of where database, logs and certs will be stored.
#   These can be changed individually if desired.
# @param db_base_path Absolute path of where logs files will be stored.
# @param 
define mongodb::config (
  Optional[Stdlib::Absolutepath]        $keyfile             = undef,
  Optional[String]                      $wiredtiger_cache_gb = undef,
  String[1]                             $repsetname          = $title,
  String[1]                             $svc_user            = 'mongod',
  Stdlib::Absolutepath                  $conf_file           = "${lookup('mongodb::config::conf_path')}/mongod_${title}.conf",
  String[1]                             $bindip              = $facts['networking']['fqdn'],
  String[1]                             $port                = '27017',
  String[1]                             $log_filename        = "${title}.log",
  String[1]                             $auth_list           = 'SCRAM-SHA-1,SCRAM-SHA-256',

  # needed before $db_data_path, $db_data_path, $log_base_path and $log_path
  # Base directories
  Stdlib::Absolutepath                  $base_path           = lookup('mongodb::config::base_path'),
  Stdlib::Absolutepath                  $db_base_path        = "${base_path}/db",
  Stdlib::Absolutepath                  $db_data_path        = "${db_base_path}/${title}",
  Stdlib::Absolutepath                  $log_path            = "${base_path}/logs",
  Stdlib::Absolutepath                  $pid_file            = "${lookup('mongodb::config::pid_path')}/${title}.pid",
  Stdlib::Absolutepath                  $pki_path            = "${base_path}/pki",

  # Certificates and SSL/TLS
  Enum['x509', 'keyFile', 'none']       $member_auth         = 'x509',
  Enum['requireSSL','preferSSL','none'] $ssl_mode            = 'requireSSL',
  Optional[Stdlib::Absolutepath]        $pem_file            = undef,
  Optional[Stdlib::Absolutepath]        $cluster_pem_file    = undef,
  Stdlib::Absolutepath                  $ca_file             = "${pki_path}/ca.cert",
) {

  if $member_auth == 'keyFile' and !($keyfile) {
    fail('If `keyFile` is selected for the $member_auth a keyfile location must be provided')
  }

  if ($member_auth == 'x509' or $ssl_mode != 'none') and !($pem_file) {
    fail('The selection of `x509` for $member_auth or enabling SSL/TLS (via $ssl_mode) requires a value for `pem_file`')
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
      owner   => $svc_user,
      group   => $svc_user,
    }
  }

  file { $db_data_path:
    ensure  => directory,
    mode    => '0755',
  }

  file { $conf_file:
    ensure  => file,
    mode    => '0400',
    seltype => 'etc_t',
    content => epp('mongodb/config.epp', {
      'auth_list'           => $auth_list,
      'bindip'              => "localhost,${bindip}",
      'ca_file'             => $ca_file,
      'cluster_pem_file'    => $cluster_pem_file,
      'dbpath'              => $db_data_path,
      'keyfile'             => $keyfile,
      'log_filename'        => $log_filename,
      'logpath'             => $log_path,
      'member_auth'         => $member_auth,
      'pem_file'            => $pem_file,
      'pid_file'            => $pid_file,
      'port'                => $port,
      'repset'              => $repsetname,
      'ssl_mode'            => $ssl_mode,
      'wiredtiger_cache_gb' => $wiredtiger_cache_gb,
    })
  }

  if $facts['os']['family'] == 'RedHat' {
    file { "/lib/systemd/system/mongod_${repsetname}.service":
      ensure  => file,
      mode    => '0644',
      seltype => 'mongod_unit_file_t',
      content => epp('mongodb/service_file.epp', {
        'svc_user'  => $svc_user,
        'pid_file'  => $pid_file,
        'pid_path'  => dirname($pid_file),
        'conf_file' => $conf_file,
      }),
      notify        => Exec["restart_systemd_daemon-${repsetname}"],
    }

    exec { "restart_systemd_daemon-${repsetname}":
      command     => '/usr/bin/systemctl daemon-reload',
      refreshonly => true,
    }
  }
}
