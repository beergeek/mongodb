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
) {
}
