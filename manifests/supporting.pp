# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include mongodb::supporting
class mongodb::supporting (
  Optional[Sensitive[String[1]]] $cluster_auth_pem_content,
  Optional[Sensitive[String[1]]] $keyfile_content,
  Optional[Sensitive[String[1]]] $pem_file_content,
  Optional[Sensitive[String[1]]] $server_keytab_content,
  Optional[Stdlib::Absolutepath] $cluster_auth_file_path,
  Optional[Stdlib::Absolutepath] $keyfile_path,
  Optional[Stdlib::Absolutepath] $pki_dir,
  Optional[Stdlib::Absolutepath] $server_keytab_path,
  Optional[String[1]]            $ca_cert_pem_content,
  Stdlib::Absolutepath           $ca_file_path,
  Stdlib::Absolutepath           $pem_file_path,
  String[1]                      $svc_user,
) {

  File {
    owner => $svc_user,
    group => $svc_user,
    mode  => '0400',
  }

  if $keyfile_content {
    file { $keyfile_path:
      ensure  => file,
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
    file { $server_keytab_path:
      ensure  => file,
      content => $server_keytab_content,
    }
  }

  if $ca_cert_pem_content {
    file { $ca_file_path:
      ensure  => file,
      content => $ca_cert_pem_content,
      mode  => '0644',
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
    file { $cluster_auth_file_path:
      ensure  => file,
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
    file { $pem_file_path:
      ensure  => file,
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
