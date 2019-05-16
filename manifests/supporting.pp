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
# @param pki_dir Absolute path for PKI and keytab files (if common), if management is desired.
# @param server_keytab_path Absolute path of the keytab file, required if managing keytab file.
# @param ca_cert_pem_content Content of the CA cert file, if management is desired.
# @param svc_user User for the service and file ownership.
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
  Optional[Stdlib::Absolutepath] $pki_dir,
  Optional[Stdlib::Absolutepath] $server_keytab_path,
  Optional[String[1]]            $ca_cert_pem_content,
  String[1]                      $svc_user,
) {

  File {
    owner => $svc_user,
    group => $svc_user,
    mode  => '0400',
  }

  if $keyfile_content {
    unless $keyfile_path {
      fail('When manage the keyfile you require `keyfile_path`')
    }
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
    unless $server_keytab_path {
      fail('When manage the keytab you require `server_keytab_path`')
    }
    file { $server_keytab_path:
      ensure  => file,
      content => $server_keytab_content,
    }
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
