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
    ensure => file,
    path   => $conf_file,
    owner  => 'mongod',
    group  => 'mongod',
    mode   => '0600',
  }

  file_line { 'aa_group_id':
    ensure             => present,
    path               => $conf_file,
    match              => '^mmsGroupId.*',
    line               => "mmsGroupId=${mongodb::automation_agent::mms_group_id}",
    append_on_no_match => true,
  }

  file_line { 'aa_api_key':
    ensure             => present,
    path               => $conf_file,
    match              => '^mmsApiKey.*',
    line               => Sensitive("mmsApiKey=${unwrap($mongodb::automation_agent::mms_api_key)}"),
    append_on_no_match => true,
  }

  file_line { 'aa_om_url':
    ensure             => present,
    path               => $conf_file,
    match              => '^mmsBaseUrl.*',
    line               => "mmsBaseUrl=${mongodb::automation_agent::url_svc_type}://${mongodb::automation_agent::ops_manager_fqdn}",
    append_on_no_match => true,
  }

  if $mongodb::automation_agent::enable_ssl {
    file_line { 'aa_pem_file':
      ensure             => present,
      path               => $conf_file,
      match              => '^sslMMSServerClientCertificate.*',
      line               => "sslMMSServerClientCertificate=${mongodb::automation_agent::pem_file_path}",
      append_on_no_match => true,
    }

    file_line { 'ca_cert_file':
      ensure             => present,
      path               => $conf_file,
      match              => '^sslTrustedMMSServerCertificate.*',
      line               => "sslTrustedMMSServerCertificate=${mongodb::automation_agent::ca_file_path}",
      append_on_no_match => true,
    }
  }
}
