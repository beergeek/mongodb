# Class to manage the ancillary supporting resources for an instance of mongodb.
#
# @summary Class to manage the ancillary supporting resources for an
#   instance of mongodb.
#
# @param gen_key_file_content Content of the `keyFile` for encryption-at-rest, this needs to be in Base64.
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
# @param installer_autodownload_ent Boolean to determine if enterprise binaries are automatically downloaded.
# @param installer_autodownload Boolean to determine if community binaries are automatically downloaded.
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
  Enum['mongodb','hybrid','local']                $installer_source,
  Boolean                                         $installer_autodownload_ent,
  Boolean                                         $installer_autodownload,
  Stdlib::Absolutepath                            $config_file_path,
  Stdlib::Absolutepath                            $gen_key_file_path,
  Stdlib::Filesource                              $mms_source,
  String[1]                                       $group,
  String[1]                                       $mms_package_name,
  String[1]                                       $user,

  # For SSL no default and is optional
  Optional[Sensitive[String[1]]]                  $pem_file_passwd,
  # For SSL in Hiera in-module
  Boolean                                         $manage_ca,
  Boolean                                         $manage_pem,
  Enum['none','agents_only','required']           $client_cert_mode,
  Optional[Stdlib::Absolutepath]                  $ca_cert_path,
  Optional[Stdlib::Absolutepath]                  $pem_file_path,
  Optional[String[1]]                             $ca_cert_content,
  Optional[Sensitive[String[1]]]                  $pem_file_content,
  Optional[Stdlib::Absolutepath]                  $https_ca_cert_path     = $ca_cert_path,
  Optional[Stdlib::Absolutepath]                  $https_pem_file_path    = $pem_file_path,
  Optional[String[1]]                             $https_ca_cert_content  = $ca_cert_content,
  Optional[Sensitive[String[1]]]                  $https_pem_file_content = $pem_file_content,

  # Auth
  Enum['com.xgen.svc.mms.svc.user.UserSvcDb',
      'com.xgen.svc.mms.svc.user.UserSvcLdap',
      'com.xgen.svc.mms.svc.user.UserSvcSaml']    $auth_type,
  Optional[String]                                $ldap_bind_dn,
  Optional[Stdlib::Port]                          $ldap_url_port,
  Optional[Sensitive[String[1]]]                  $ldap_bind_password,
  Optional[String[1]]                             $ldap_global_owner,
  Optional[Mongodb::LDAPUrl]                      $ldap_url_host,
  Optional[String[1]]                             $ldap_user_group,
  Optional[String[1]]                             $ldap_user_search_attribute,
  Optional[Integer]                               $password_max_days_before_change_required,
  Optional[Integer]                               $password_max_days_inactive_before_account_lock,
  Optional[Integer]                               $password_max_failed_attempts_before_account_lock,
  Optional[Integer]                               $password_min_changes_before_reuse,
  Optional[Boolean]                               $user_bypass_invite_for_existing_users,
  Optional[Boolean]                               $user_invitation_only,
  Optional[Stdlib::Absolutepath]                  $auth_ssl_ca_file,
  Optional[Stdlib::Absolutepath]                  $auth_ssl_pem_key_file,
  Optional[Sensitive[String[1]]]                  $auth_ssl_pem_key_file_passwd,
  Optional[String[1]]                             $global_automation_admin,
  Optional[String[1]]                             $global_backup_admin,
  Optional[String[1]]                             $global_monitoring_admin,
  Optional[String[1]]                             $global_read_only,
  Optional[String[1]]                             $global_user_admin,
  Optional[String[1]]                             $ldap_group_base_dn,
  Optional[String[1]]                             $ldap_group_member,
  Optional[String[1]]                             $ldap_group_seperator,
  Optional[String[1]]                             $ldap_referral,
  Optional[String[1]]                             $ldap_user_base_dn,
  Optional[String[1]]                             $ldap_user_email,
  Optional[String[1]]                             $ldap_user_firstname,
  Optional[String[1]]                             $ldap_user_lastname,
  Optional[Boolean]                               $device_notification,

  # MFA
  Enum['OFF',
      'OPTIONAL',
      'REQUIRED_FOR_GLOBAL_ROLES',
      'REQUIRED']                                 $mfa_level,
  Boolean                                         $mfa_allow_reset,
  Optional[String[1]]                             $mfa_issuer,
  Boolean                                         $mfa_require,
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

  if $auth_type == 'com.xgen.svc.mms.svc.user.UserSvcLdap' and
  ($ldap_bind_dn == undef or $ldap_url_port == undef or
  $ldap_bind_password == undef or $ldap_global_owner == undef or
  $ldap_url_host == undef or $ldap_user_group == undef or
  $ldap_user_search_attribute == undef) {
    fail("If LDAP auth is enabled for Ops Manager the following must be provided:\n\t
    * ldap_bind_dn\n\t* ldap_url_port\n\t* ldap_bind_password\n\t
    * ldap_global_owner\n\t* ldap_url_host\n\t* ldap_user_group\n\t
    * ldap_user_search_attribute")
  }

  if type($auth_ssl_pem_key_file_passwd) == Sensitive {
    $_auth_ssl_pem_key_file_passwd = unwrap($auth_ssl_pem_key_file_passwd)
  } else {
    $_auth_ssl_pem_key_file_passwd = $auth_ssl_pem_key_file_passwd
  }

  if type($ldap_bind_password) == Sensitive {
    $_ldap_bind_password = unwrap($ldap_bind_password)
  } else {
    $_ldap_bind_password = $ldap_bind_password
  }

  if type($pem_file_passwd) == Sensitive {
    $_pem_file_passwd = unwrap($pem_file_passwd)
  } else {
    $_pem_file_passwd = $pem_file_passwd
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
      admin_email_addr                                 => $admin_email_addr,
      appsdb_uri                                       => $appsdb_uri,
      auth_ssl_ca_file                                 => $auth_ssl_ca_file,
      auth_ssl_pem_key_file                            => $auth_ssl_pem_key_file,
      auth_ssl_pem_key_file_passwd                     => $_auth_ssl_pem_key_file_passwd,
      auth_type                                        => $auth_type,
      ca_cert_path                                     => $ca_cert_path,
      central_url                                      => $central_url,
      client_cert_mode                                 => $client_cert_mode,
      device_notification                              => $device_notification,
      email_hostname                                   => $email_hostname,
      email_port                                       => $email_port,
      email_transport                                  => $email_transport,
      email_type                                       => $email_type,
      from_email_addr                                  => $from_email_addr,
      global_automation_admin                          => $global_automation_admin,
      global_backup_admin                              => $global_backup_admin,
      global_monitoring_admin                          => $global_monitoring_admin,
      global_read_only                                 => $global_read_only,
      global_user_admin                                => $global_user_admin,
      https_ca_cert_path                               => $https_ca_cert_path,
      https_pem_file_path                              => $https_pem_file_path,
      installer_autodownload                           => $installer_autodownload,
      installer_autodownload_ent                       => $installer_autodownload_ent,
      installer_source                                 => $installer_source,
      ldap_bind_dn                                     => $ldap_bind_dn,
      ldap_url_port                                    => $ldap_url_port,
      ldap_bind_password                               => $_ldap_bind_password,
      ldap_global_owner                                => $ldap_global_owner,
      ldap_group_base_dn                               => $ldap_group_base_dn,
      ldap_group_member                                => $ldap_group_member,
      ldap_group_seperator                             => $ldap_group_seperator,
      ldap_referral                                    => $ldap_referral,
      ldap_url_host                                    => $ldap_url_host,
      ldap_user_base_dn                                => $ldap_user_base_dn,
      ldap_user_email                                  => $ldap_user_email,
      ldap_user_firstname                              => $ldap_user_firstname,
      ldap_user_group                                  => $ldap_user_group,
      ldap_user_lastname                               => $ldap_user_lastname,
      ldap_user_search_attribute                       => $ldap_user_search_attribute,
      ops_manager_ssl                                  => $ops_manager_ssl,
      password_max_days_before_change_required         => $password_max_days_before_change_required,
      password_max_days_inactive_before_account_lock   => $password_max_days_inactive_before_account_lock,
      password_max_failed_attempts_before_account_lock => $password_max_failed_attempts_before_account_lock,
      password_min_changes_before_reuse                => $password_min_changes_before_reuse,
      pem_file_passwd                                  => $_pem_file_passwd,
      pem_file_path                                    => $pem_file_path,
      reply_email_addr                                 => $reply_email_addr,
      user_bypass_invite_for_existing_users            => $user_bypass_invite_for_existing_users,
      user_invitation_only                             => $user_invitation_only,
      mfa_level                                        => $mfa_level,
      mfa_allow_reset                                  => $mfa_allow_reset,
      mfa_issuer                                       => $mfa_issuer,
      mfa_require                                      => $mfa_require,
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
      ensure_resources('file',
        { $pem_file_path => {
            ensure  => file,
            mode    => '0600',
            content => $pem_file_content,
          }
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
