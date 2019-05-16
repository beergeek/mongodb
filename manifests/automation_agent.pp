# A class to install, configure, and run the Ops Manager Automation Agent on nodes
#
# @summary A class to install, configure, and run the Ops Manager Automation Agent on nodes
#
# @param ops_manager_fqdn The fully qualified domain name of the Ops Manager.
#   Used to construct the URL to download the automation agent.
#
# @param mms_api_key The API key for the agent.
# @param mms_group_id The Project ID for the agent.
# @param url_svc_type If the Ops Manager is `HTTP` or `HTTPS`. Values can be `http` or `https`.
# @param svc_user The user that automation agent will run as.
# @param ca_file_path The absolute path for the CA file.
# @param pem_file_path The absolute path for the SSL PEM file.
# @param ca_file_content The content of the CA file, if it will be managed.
# @param pem_file_content The content of the SSL PEM file, if it will be managed.
# @param enable_ssl Boolean to determine if SSL enabled for the automation agent communications.
#
# @example
#   class { 'mongodb::automation_agent':
#     mms_api_key      => Sensitive('ertcvybuinkljnicusdyTRGYV GH456'),
#     mms_group_id     => 'xretRTCTVYTCHVBUYIU2345678',
#     ops_manager_fqdn => 'ops-manager.mongodb.local',
#     enable_ssl       => false,
#   }
#
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

  Class['mongodb::automation_agent::install']
  -> Class['mongodb::automation_agent::config']
  ~> Class['mongodb::automation_agent::service']
}
