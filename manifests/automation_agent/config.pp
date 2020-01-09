# Class to configure the automation agent
#
# @summary Class to configure the automation agent
# @api private
#
# @example
#   include mongodb::automation_agent::config
class mongodb::automation_agent::config (
) {

  assert_private()

  case $facts['os']['family'] {
    'RedHat': {
      $conf_file = '/etc/mongodb-mms/automation-agent.config'
    }
    'windows': {
      $conf_file = 'C:\MMSData\Automation\automation-agent.config'
    }
    default: {
      fail("We are sorry, but ${facts['os']['family']} does not appear to be an operating system we supprot")
    }
  }

  file { 'aa_config':
    ensure                        => file,
    path                          => $conf_file,
    owner                         => 'mongod',
    group                         => 'mongod',
    mode                          => '0600',
    content => epp('mongodb/aa_config.epp', {
      aa_loglevel                 => $mongodb::automation_agent::aa_loglevel,
      backup_agent_krb5_path      => $mongodb::automation_agent::backup_agent_krb5_path,
      ca_file_path                => $mongodb::automation_agent::ca_file_path,
      http_proxy                  => $mongodb::automation_agent::http_proxy,
      krb5_conf_path              => $mongodb::automation_agent::krb5_conf_path,
      log_file_duration           => $mongodb::automation_agent::log_file_duration,
      log_file_path               => $mongodb::automation_agent::log_file_path,
      max_log_files               => $mongodb::automation_agent::max_log_files,
      max_log_size                => $mongodb::automation_agent::max_log_size,
      mms_api_key                 => chomp(unwrap($mongodb::automation_agent::mms_api_key)),
      mms_config_backup_file_path => $mongodb::automation_agent::mms_config_backup_file_path,
      mms_group_id                => $mongodb::automation_agent::mms_group_id,
      monitor_agent_krb5_path     => $mongodb::automation_agent::monitor_agent_krb5_path,
      om_timeout                  => $mongodb::automation_agent::om_timeout,
      ops_manager_fqdn            => $mongodb::automation_agent::ops_manager_fqdn,
      pem_file_path               => $mongodb::automation_agent::pem_file_path,
      pem_password                => $mongodb::automation_agent::pem_password,
      validate_ssl_certs          => $mongodb::automation_agent::validate_ssl_certs,
    })
  }
}
