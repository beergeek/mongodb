# Class to manage the ancillary supporting resources for an instance of mongodb.
#
# @summary Class to manage the ancillary supporting resources for an
#   instance of mongodb.
#
# @param gen_key_file_content Content of the `keyFile` for encryption-at-rest.
# @param appsdb_uri Connection string for the application backing database for
#   Ops Manager.
# @param central_url URL that will be used by agents to connect to Ops Manager.
#   This overrides the value in the UI/Database!
# @param email_hostname The hostname of the email server.
# @param admin_email_addr The email address used for the admin user.
# @param from_email_addr The email address to use as the 'from' address.
# @param reply_email_addr The email address to use as the 'reply' address.
# @param email_transport Email transport mechanism. Optionals are `smtp` or `smtps`.
# @param email_type Type of email system to use. Options are `com.xgen.svc.core.dao.email.AwsEmailDao` or
#   `com.xgen.svc.core.dao.email.JavaEmailDao`. Use `com.xgen.svc.core.dao.email.JavaEmailDao` for SMTP.
# @param email_port Port number for the email server.
# @param manage_group Boolean to determine if the service group is managed.
# @param manage_user Boolean to determine if the service user is managed.
# @param ops_manager_ssl Boolean to determine if SSL is used for communications.
# @param config_file_path The absolute path for the configuration file.
# @param gen_key_file_path The absolute path for the 'gen.key'.
# @param mms_source URL or source of Ops Manager install package, does not include the Ops Manager package name.
# @param group Service group name.
# @param mms_package_name Name of the Ops Manager installer package.
# @param user Name of the service user.
# @param pem_file_passwd Password for the PEM file, if needed.
# @param manage_ca Boolean to determine if the CA cert file is managed.
# @param manage_pem Boolean to determine if the SSL PEM file is managed.
# @param client_cert_mode Mode that SSL is in for clients. Options are `none`, `agents_only`, or `required`.
# @param ca_cert_path The absolute path for the CA file.
# @param pem_file_path The absolute path for the SSL PEM file.
# @param ca_cert_content The content of the CA file used for mongod communication, if to managed.
# @param pem_file_content The content of the SSL PEM file used for mongod communication, if to managed.
# @param https_ca_cert_path The absolute path for the CA cert for the HTTPS service.
# @param https_pem_file_path The absolute path for the PEM file for the HTTPS service.
# @param https_ca_cert_content The content of the CA cert for the HTTPS service, if managed.
# @param https_pem_file_content The content of the PEM file for the HTTPS service, if managed.
# @param installer_source Where the agents will get the install packages from. Use `direct` for MongoDB or `host` for
#   Ops Manager.
# @param binary_source Where Ops Manager will get the binaries for the various products.
# @param enable_http_service Boolean to determine if the Ops Manager service is running and enabled
# @param enable_backup_daemon Boolean to determine if the Ops Manager Backup Daemon is running as a separate
#   process. Only valid if `enable_http_service` is `false`.
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

  # Using Hiera in-module
  Boolean                                         $enable_http_service,
  Boolean                                         $enable_backup_daemon,
  Boolean                                         $manage_group,
  Boolean                                         $manage_user,
  Boolean                                         $ops_manager_ssl,
  Enum['direct','host']                           $installer_source,
  Enum['internet','local']                        $binary_source,
  Stdlib::Absolutepath                            $config_file_path,
  Stdlib::Absolutepath                            $gen_key_file_path,
  Stdlib::Filesource                              $mms_source,
  String[1]                                       $group,
  String[1]                                       $mms_package_name,
  String[1]                                       $user,

  # For SSL no default
  Optional[Sensitive[String[1]]]                  $pem_file_passwd,
  # For SSL in Hiera in-module
  Boolean                                         $manage_ca,
  Boolean                                         $manage_pem,
  Enum['none','agents_only','required']           $client_cert_mode,
  Optional[Stdlib::Absolutepath]                  $ca_cert_path,
  Optional[Stdlib::Absolutepath]                  $pem_file_path,
  Optional[String[1]]                             $ca_cert_content,
  Sensitive[Optional[String[1]]]                  $pem_file_content,
  Optional[Stdlib::Absolutepath]                  $https_ca_cert_path     = $ca_cert_path,
  Optional[Stdlib::Absolutepath]                  $https_pem_file_path    = $pem_file_path,
  Optional[String[1]]                             $https_ca_cert_content  = $ca_cert_content,
  Sensitive[Optional[String[1]]]                  $https_pem_file_content = $pem_file_content,
) {

  unless is_email_address($admin_email_addr) {
    fail('`admin_email_addr` must be a valid email address!')
  }

  unless is_email_address($from_email_addr) {
    fail('`from_email_addr` must be a valid email address!')
  }

  unless is_email_address($reply_email_addr) {
    fail('`reply_email_addr` must be a valid email address!')
  }

  if $ops_manager_ssl and !($ca_cert_path and $pem_file_path) {
    fail('`ca_cert_path` and `pem_file_path` are required if `ops_manager_ssl` is true.')
  }

  if $enable_http_service {
    $_enable = true
    $_ensure = running
  } else {
    $_enable = false
    $_ensure = stopped
  }

  File {
    owner  => $user,
    group  => $group,
  }

  if $facts['os']['family'] == 'windows' {
    $mms_provider = 'msi'
  } elsif $facts['os']['family'] == 'RedHat' {
    $mms_provider = 'rpm'
  } else {
    fail('Need a supported OS')
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
      binary_source       => $binary_source,
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
      installer_source    => $installer_source,
      ops_manager_ssl     => $ops_manager_ssl,
      pem_file_passwd     => $pem_file_passwd,
      pem_file_path       => $pem_file_path,
      reply_email_addr    => $reply_email_addr,
    }),
    require => Package['mongodb_mms_pkg'],
  }

  if $manage_ca {
    if $ca_cert_content and $ca_cert_path  {
      # ensure_resources as this might be shared
      ensure_resources(
        file { $ca_cert_path:
          ensure  => file,
          mode    => '0644',
          content => $ca_cert_content,
        }
      )
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
      # ensure_resources as this might be shared
      ensure_resources(
        file { $pem_file_path:
          ensure  => file,
          mode    => '0600',
          content => $pem_file_content,
        }
      )
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
    ensure    => $_ensure,
    enable    => $_enable,
    subscribe => File['mms_config_file','gen_key_file'],
  }

  if $enable_http_service == false and $enable_backup_daemon {
    service { 'mongodb-mms-backup-daemon':
      ensure    => running,
      enable    => true,
      subscribe => File['mms_config_file','gen_key_file'],
    }
  }
}
