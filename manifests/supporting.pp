# @summary Class that manage ancillary resources, such as certs and keytab files.
#
# Class that manage ancillary resources, such as certs and keytab files.
#
# @param cluster_auth_pem_content Content of the cluster auth file, if management is desired.
# @param keyfile_content Content of the encryption-at-rest keyfile, if management is desired.
# @param pem_file_content Content of the x509 PEM file, if management is desired.
# @param server_keytab_content Content of Kerberos keytab, if management is desired.
# @param ca_file_path Absolute path of the CA file, required if managing CA file.
# @param cluster_auth_file_path Absolute path of the cluster auth file, required if managing cluster auth file.
# @param keyfile_path Absolute path of the encryption-at-rest keyfile, required if managing keyfile.
# @param pem_file_path Absolute path of the PEM file, required if managing the PEM file.
# @param server_keytab_path Absolute path of the keytab file, required if managing keytab file.
# @param ca_cert_pem_content Content of the CA cert file, if management is desired.
# @param base_path Absolute path of the base directory where database, logs and PKI reside.
# @param db_base_path The absolute path where the database will reside.
#   SELinux will be modified on Linux to accommodate this directory.
# @param log_path The absolute path where the logs will reside.
#   SELinux will be modified on Linux to accommodate this directory.
# @param pki_path The absolute oath where the PKI, keyfiles and keytab will reside.
#   SELinux will be modified on Linux to accommodate this directory.
# @param svc_user The name of the user and group to create and manage.
# @param home_dir The absolute path of the home directory for the serivce user.
#
# @example
#   include mongodb::supporting
class mongodb::supporting (
  Optional[Sensitive[String[1]]] $cluster_auth_pem_content,
  Optional[Sensitive[String[1]]] $keyfile_content,
  Optional[Sensitive[String[1]]] $pem_file_content,
  Optional[Sensitive[String[1]]] $server_keytab_content,
  Optional[Stdlib::Absolutepath] $ca_file_path,
  Optional[Stdlib::Absolutepath] $cluster_auth_file_path,
  Optional[Stdlib::Absolutepath] $keyfile_path,
  Optional[Stdlib::Absolutepath] $pem_file_path,
  Optional[Stdlib::Absolutepath] $server_keytab_path,
  Optional[String[1]]            $ca_cert_pem_content,
  Stdlib::Absolutepath           $base_path,
  Stdlib::Absolutepath           $db_base_path,
  Stdlib::Absolutepath           $home_dir,
  Stdlib::Absolutepath           $log_path,
  Stdlib::Absolutepath           $pki_path,
  String[1]                      $svc_user,
) {

  File {
    owner => $svc_user,
    group => $svc_user,
  }

  if $facts['kernel'] == 'windows' {
    $_gid = undef
  } else {
    $_gid = $svc_user
  }

  user { $svc_user:
    ensure     => present,
    gid        => $_gid,
    home       => $home_dir,
    managehome => true,
    system     => true,
  }

  group { $svc_user:
    ensure => present,
  }

  file { $home_dir:
    ensure => directory,
    mode   => '0750',
  }

  if $facts['os']['family'] == 'RedHat' {
    File {
      mode    => '0755',
      seltype => 'mongod_var_lib_t',
      seluser => 'system_u',
    }

    selinux::fcontext { "set-${db_base_path}-context":
      ensure   => present,
      seltype  => 'mongod_var_lib_t',
      seluser  => 'system_u',
      pathspec => "${db_base_path}.*",
      notify   => Exec["selinux-${db_base_path}"],
    }

    exec { "selinux-${db_base_path}":
      command     => "/sbin/restorecon -R -v ${db_base_path}",
      refreshonly => true,
    }

    selinux::fcontext { "set-${pki_path}-context":
      ensure   => present,
      seltype  => 'mongod_var_lib_t',
      seluser  => 'system_u',
      pathspec => "${pki_path}.*",
      notify   => Exec["selinux-${pki_path}"],
    }

    exec { "selinux-${pki_path}":
      command     => "/sbin/restorecon -R -v ${pki_path}",
      refreshonly => true,
    }

    selinux::fcontext { "set-${log_path}-context":
      ensure   => present,
      seltype  => 'mongod_log_t',
      seluser  => 'system_u',
      pathspec => "${log_path}.*",
      notify   => Exec["selinux-${log_path}"],
    }

    exec { "selinux-${log_path}":
      command     => "/sbin/restorecon -R -v ${log_path}",
      refreshonly => true,
    }
  }

  file { [ $base_path, $db_base_path, $pki_path ]:
    ensure  => directory,
  }

  file { $log_path:
    ensure  => directory,
    seltype => 'mongod_log_t',
    seluser => 'system_u',
  }

  if $keyfile_content {
    unless $keyfile_path {
      fail('When manage the keyfile you require `keyfile_path`')
    }
    file { $keyfile_path:
      ensure  => file,
      mode    => '0400',
      content => $keyfile_content,
    }

    if $facts['os']['family'] == 'windows' {

      acl { $keyfile_path:
        purge                      => false,
        permissions                => [
          { identity => $svc_user, rights => ['full'], perm_type=> 'allow', child_types => 'all', affects => 'all'}
        ],
        owner                      => $svc_user,
        group                      => $svc_user,
        inherit_parent_permissions => false,
      }
    }
  }

  if $server_keytab_content and $facts['os']['family'] != 'windows' {
    unless $server_keytab_path {
      fail('When manage the keytab you require `server_keytab_path`')
    }
    notify { unwrap($server_keytab_content): }
    #file { $server_keytab_path:
    #  ensure  => file,
    #  mode    => '0400',
    #  content => Binary(unwrap($server_keytab_content)),
    #}
  }

  if $ca_cert_pem_content {
    unless $ca_file_path {
      fail('When manage the CA cert you require `ca_file_path`')
    }
    file { $ca_file_path:
      ensure  => file,
      content => $ca_cert_pem_content,
      mode    => '0644',
    }

    if $facts['os']['family'] == 'windows' {

      acl { $ca_file_path:
        purge                      => false,
        permissions                => [
          { identity => $svc_user, rights => ['full'], perm_type=> 'allow', child_types => 'all', affects => 'all'}
        ],
        owner                      => $svc_user,
        group                      => $svc_user,
        inherit_parent_permissions => true,
      }
    }
  }

  if $cluster_auth_pem_content {
    unless $ca_file_path {
      fail('When manage the cluster auth file you require `cluster_auth_file_path`')
    }
    file { $cluster_auth_file_path:
      ensure  => file,
      mode    => '0400',
      content => $cluster_auth_pem_content,
    }

    if $facts['os']['family'] == 'windows' {

      acl { $cluster_auth_file_path:
        purge                      => false,
        permissions                => [
          { identity => $svc_user, rights => ['full'], perm_type=> 'allow', child_types => 'all', affects => 'all'}
        ],
        owner                      => $svc_user,
        group                      => $svc_user,
        inherit_parent_permissions => false,
      }
    }
  }

  if $pem_file_content {
    unless $pem_file_path {
      fail('When manage the PEM file you require `pem_file_path`')
    }
    file { $pem_file_path:
      ensure  => file,
      mode    => '0400',
      content => $pem_file_content,
    }

    if $facts['os']['family'] == 'windows' {

      acl { $pem_file_path:
        purge                      => false,
        permissions                => [
          { identity => $svc_user, rights => ['full'], perm_type=> 'allow', child_types => 'all', affects => 'all'}
        ],
        owner                      => $svc_user,
        group                      => $svc_user,
        inherit_parent_permissions => false,
      }
    }
  }
}
