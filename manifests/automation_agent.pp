# A class to install the Ops Manager Automation Agent on nodes
#
# @summary A class to install the Ops Manager Automation Agent on nodes
#
# @param ops_manager_fqdn The fully qualified domain name of the Ops Manager.
#   Used to construct the URL to download the automation agent. Required if
#   Puppet will construct this URL, not required if full URL given for the
#   package, e.g. `auto_agent_pkg_source_url`
#
# @example
#   include mongodb::automation_agent
class mongodb::automation_agent (
  # Required
  Sensitive[String[1]]           $mms_api_key,
  String                         $mms_group_id,

  # When automation agent is built from the Ops Manager FQDN
  String                         $ops_manager_fqdn,
  Enum['http','https']           $url_svc_type,
  String                         $svc_user,

  # Other settings
  Optional[Stdlib::Absolutepath] $ca_file_path,
  Optional[Stdlib::Absolutepath] $pem_file_path,
  Optional[String[1]]            $ca_file_content,
  Optional[Sensitive[String[1]]] $pem_file_content,
  Boolean                        $enable_ssl,
) {

  if $mongodb::automation_agent::enable_ssl and !($pem_file_path or $ca_file_path)  {
    fail('When selecting SSL for the automation agent the absolute path for the PEM file and CA cert must be provided')
  }

  include mongodb::automation_agent::install
  include mongodb::automation_agent::config
  include mongodb::automation_agent::service

  Class['mongodb::automation_agent::install'] ->
  Class['mongodb::automation_agent::config'] ~>
  Class['mongodb::automation_agent::service']
}
