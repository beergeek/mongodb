# @summary A class to manage `mongosqld`/Business Intelligence
#   Connector instance. [WIP]
#
# A class to manage `mongosqld`/Business Intelligence
#   Connector instance.
#
# @example
#   mongodb::bi_connecter { 'namevar': }
class mongodb::bi_connecter (
  Boolean                               $bic_schema_user_kerberos,
  Boolean                               $bic_svc_kerberos,
  Boolean                               $ssl_weak_certs, #sadness
  Boolean                               $ssl_client_weak_certs, #sadness
  Enum['none','allowSSL','requireSSL']  $bic_ssl_mode,
  Enum['none','allowSSL','requireSSL']  $bic_client_ssl_mode,
  Optional[Sensitive[String[1]]]        $bic_schema_user_keytab_content,
  Optional[Sensitive[String[1]]]        $bic_schema_user_passwd,
  Optional[Sensitive[String[1]]]        $bic_svc_keytab_content,
  Optional[Stdlib::Absolutepath]        $bic_schema_user_keytab_path,
  Optional[Stdlib::Absolutepath]        $bic_svc_keytab_path,
  Optional[Stdlib::Absolutepath]        $ca_path,
  Optional[Stdlib::Absolutepath]        $pem_path,
  Optional[Sensitive[String[1]]]        $pem_password,
  Stdlib::Absolutepath                  $bic_svc_user_home,
  Stdlib::Absolutepath                  $log_path,
  String[1]                             $bic_sample_database,
  String[1]                             $bic_schema_user,
  String[1]                             $bic_source_url,
  String[1]                             $bic_svc_user,
  String[1]                             $mongodb_connection_string,
  String[1]                             $port,
  Optional[Sensitive[String[1]]]        $client_pem_password = $pem_password,
  Optional[Stdlib::Absolutepath]        $client_ca_path      = $ca_path,
  Optional[Stdlib::Absolutepath]        $client_pem_path     = $pem_path,
) {

  if $bic_svc_kerberos {
    $_auth_mechanism = 'GSSAPI'
  } else {
    $_auth_mechanism = 'SCRAM-SHA-1,SCRAM-SHA-256'
  }

  if $facts['os']['family'] == 'windows' {
    $_tmp_path = "${facts['windows_env']['TEMP']}\\bic.zip"
    $_extract_path = ''
    $_creates = ''
  } else {
    $_tmp_path = '/tmp/bic.tgz'
    $_extract_path = '/usr/bin'
    $_creates = '/usr/bin/mongosqld'
    $_config_file = '/etc/mongosql.conf'
    $_install_cmd = "/bin/install -m0755 /usr/bin/mongo* && ${_creates} -f ${_config_file}"

    file { '/etc/systemd/system/mongosql.service':
      ensure  => 'file',
      owner   => $bic_svc_user,
      group   => $bic_svc_user,
      mode    => '0755',
      content => epp('mongodb/mongosql.service.epp', {
        bic_schema_user_kerberos    => $bic_schema_user_kerberos,
        bic_schema_user_keytab_path => $bic_schema_user_keytab_path,
        bic_svc_kerberos            => $bic_svc_kerberos,
        bic_svc_keytab_path         => $bic_svc_keytab_path,
        config_file                 => $_config_file,
      }),
      require => Archive['mongosqld'],
    }

    exec { '/usr/bin/systemctl daemon-reload':
      refreshonly => true,
      subscribe   => File['/etc/systemd/system/mongosql.service'],
      notify      => Service['mongosql'],
    }
  }

  user { $bic_svc_user:
    ensure     => present,
    gid        => $bic_svc_user,
    home       => $bic_svc_user_home,
    managehome => true,
    system     => true,
  }

  group { $bic_svc_user:
    ensure => present,
  }

  file { $bic_svc_user_home:
    ensure => directory,
    owner  => $bic_svc_user,
    group  => $bic_svc_user,
    mode   => '0750',
  }

  file { dirname($log_path):
    ensure => directory,
    owner  => $bic_svc_user,
    group  => $bic_svc_user,
    mode   => '0750',
  }

  file { $_config_file:
    ensure  => file,
    owner   => $bic_svc_user,
    group   => $bic_svc_user,
    mode    => '0400',
    content => epp('mongodb/mongosql.conf.epp', {
      auth_mechanism            => $_auth_mechanism,
      bic_client_ssl_mode       => $bic_client_ssl_mode,
      bic_sample_database       => $bic_sample_database,
      bic_schema_user           => $bic_schema_user,
      bic_schema_user_kerberos  => $bic_schema_user_kerberos,
      bic_schema_user_passwd    => $bic_schema_user_passwd,
      bic_ssl_mode              => $bic_ssl_mode,
      bic_svc_kerberos          => $bic_svc_kerberos,
      ca_path                   => $ca_path,
      client_ca_path            => $client_ca_path,
      client_pem_password       => $client_pem_password,
      client_pem_path           => $client_pem_path,
      log_path                  => $log_path,
      mongodb_connection_string => $mongodb_connection_string,
      pem_password              => $pem_password,
      pem_path                  => $pem_path,
      port                      => $port,
      ssl_client_weak_certs     => $ssl_client_weak_certs,
      ssl_weak_certs            => $ssl_weak_certs,
    })
  }

  if $bic_schema_user_kerberos {
    file { $bic_schema_user_keytab_path:
      ensure  => file,
      owner   => $bic_svc_user,
      group   => $bic_svc_user,
      mode    => '0400',
      content => $bic_schema_user_keytab_content,
    }
  }

  if $bic_svc_kerberos {
    file { $bic_svc_keytab_path:
      ensure  => file,
      owner   => $bic_svc_user,
      group   => $bic_svc_user,
      mode    => '0400',
      content => $bic_svc_keytab_content,
    }
  }

  archive { 'mongosqld':
    ensure       => 'present',
    path         => $_tmp_path,
    extract      => true,
    extract_path => $_extract_path,
    source       => $bic_source_url,
    creates      => $_creates,
    cleanup      => true,
  }

  exec { 'install_mongosqld':
    command     => $_install_cmd,
    refreshonly => true,
    subscribe   => Archive['mongosqld'],
  }

  service { 'mongosql':
    ensure    => running,
    enable    => true,
    subscribe => File[$_config_file],
  }
}
