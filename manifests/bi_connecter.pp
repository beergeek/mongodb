# @summary A class to manage `mongosqld`/Business Intelligence
#   Connector instance.
#
# A class to manage `mongosqld`/Business Intelligence
#   Connector instance.
#
# @example
#   mongodb::bi_connecter { 'namevar': }
class mongodb::bi_connecter (
  String[1]                      $bic_source_url,
  String[1]                      $bic_schema_user,
  Optional[Sensitive[String[1]]] $bic_schema_user_passwd,
  Optional[Stdlib::Absolutepath] $client_keytab_path,
  Optional[Stdlib::Absolutepath] $svc_keytab_path,
  Optional[String[1]]            $client_keytab_content,
  Optional[String[1]]            $svc_keytab_content,
) {

  if $client_keytab_content {
    file { $client_keytab_path:
      ensure  => file,
      mode    => '0400',
      content => $client_keytab_content,
    }
  }
}
