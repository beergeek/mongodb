# A description of what this class does
#
# @summary Class to manage the ancillary supporting resources for an
#   instance of mongodb
#
# @param gen_key_file_content Content of the `keyFile` for encryption-at-rest.
# @param appsdb_uri Connection string for the application backing database for
#   Ops Manager.
# @param central_url URL that will be used by agents to connect to Ops Manager.
#   This overrides the value in the UI/Database!
# @
#
# @example
#   include mongodb::ops_manager
class mongodb::ops_manager (
  # No default
  Stdlib::Base64                                  $gen_key_file_content,
  String[1]                                       $appsdb_uri,
  String                                          $central_url,

  # Email with no default
  Stdlib::Host                                    $email_hostname,
  String[1]                                       $admin_email_addr,
  String[1]                                       $from_email_addr,
  String[1]                                       $reply_email_addr,
  # Email with data from Hiera in-module
  Enum['smtp','smtps']                            $email_transport,
  Enum['com.xgen.svc.core.dao.email.AwsEmailDao',
      'com.xgen.svc.core.dao.email.JavaEmailDao'] $email_type,
  String[1]                                       $email_port,

  # For SSL no default
  Optional[Sensitive[String[1]]]                  $pem_file_passwd,
  # For SSL in Hiera in-module
  Boolean                                         $manage_ca,
  Boolean                                         $manage_pem,
  Optional[Stdlib::Absolutepath]                  $ca_cert_path,
  Optional[Stdlib::Absolutepath]                  $pem_file_path,
  Optional[String[1]]                             $ca_cert_content,
  Sensitive[Optional[String[1]]]                  $pem_file_content,
  Optional[Stdlib::Absolutepath]                  $https_ca_cert_path     = $ca_cert_path,
  Optional[Stdlib::Absolutepath]                  $https_pem_file_path    = $pem_file_path,
  Optional[String[1]]                             $https_ca_cert_content  = $ca_cert_content,
  Sensitive[Optional[String[1]]]                  $https_pem_file_content = $pem_file_content,
  Enum['none','agents_only','required']           $client_cert_mode,



  # Using Hiera in-module
  Boolean                                         $manage_group,
  Boolean                                         $manage_user,
  Boolean                                         $ops_manager_ssl,
  Enum['rpm','msi']                               $mms_provider,
  Stdlib::Absolutepath                            $config_file_path,
  Stdlib::Absolutepath                            $gen_key_file_path,
  Stdlib::Filesource                              $mms_source,
  String[1]                                       $group,
  String[1]                                       $mms_package_name,
  String[1]                                       $user,
) {

  File {
    owner  => $user,
    group  => $group,
  }

  if $facts['kernal'] != 'windows'{
    File {
      mode => '0644',
    }

    # Manage limits as backup daemon may be used
    file { '/etc/security/limits.d/99-mongodb-mms.conf':
      ensure => file,
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/mongodb/99-mongodb-mms.conf',
      notify => Service['mongodb-mms'],
    }
  } else {

    acl { $config_file_path:
      purge                      => false,
      permissions                => [
        { identity => $user, rights => ['full'], perm_type=> 'allow', child_types => 'all', affects => 'all'}
      ],
      owner                      => $user,
      group                      => $user,
      inherit_parent_permissions => true,
    }
  }

  if $manage_user {
    user { $user:
      ensure     => present,
      gid        => $group,
      home       => '/home/mongodb',
      managehome => true,
    }
  }

  if $manage_group {
    group { $group:
      ensure => present,
    }
  }

  package { 'mongodb_mms_pkg':
    ensure   => present,
    name     => $mms_package_name,
    source   => $mms_source,
    provider => $mms_provider,
  }

  file { 'mms_config_file':
    ensure  => file,
    path    => $config_file_path,
    content => epp('mongodb/mms_config_file.epp', {
      admin_email_addr    => $admin_email_addr,
      appsdb_uri          => $appsdb_uri,
      ca_cert_path        => $ca_cert_path,
      central_url         => $central_url,
      client_cert_mode    => $client_cert_mode,
      email_hostname      => $email_hostname,
      email_port          => $email_port,
      email_transport     => $email_transport,
      email_type          => $email_type,
      from_email_addr     => $from_email_addr,
      https_ca_cert_path  => $https_ca_cert_path,
      https_pem_file_path => $https_pem_file_path,
      ops_manager_ssl     => $ops_manager_ssl,
      pem_file_passwd     => $pem_file_passwd,
      pem_file_path       => $pem_file_path,
      reply_email_addr    => $reply_email_addr,
    }),
    require => Package['mongodb_mms_pkg'],
  }

  if $manage_ca {
    if $ca_cert_content and $ca_cert_path  {
      file { $ca_cert_path:
        ensure  => file,
        mode    => '0644',
        content => $ca_cert_content,
      }
    } else {
      fail('Content of CA cert file must be supplied if being managed')
    }
    if $ca_cert_content != $https_ca_cert_content and $https_ca_cert_content != undef {
      file { $https_ca_cert_path:
        ensure  => file,
        mode    => '0600',
        content => $https_ca_cert_content,
      }
    }
  }

  if $manage_pem {
    if $pem_file_content and $pem_file_path {
      file { $pem_file_path:
        ensure  => file,
        mode    => '0600',
        content => $pem_file_content,
      }
    } else {
      fail('Content of CA cert file must be supplied if being managed')
    }
    if $pem_file_content != $https_pem_file_content and $https_pem_file_content != undef {
      file { $https_pem_file_path:
        ensure  => file,
        mode    => '0600',
        content => $https_pem_file_content,
      }
    }
  }

  file { 'gen_key_file':
    ensure  => file,
    path    => $gen_key_file_path,
    content => Binary($gen_key_file_content),
    mode    => '0400',
    require => Package['mongodb_mms_pkg'],
  }

  service { 'mongodb-mms':
    ensure    => running,
    enable    => true,
    subscribe => File['mms_config_file','gen_key_file'],
  }

}
