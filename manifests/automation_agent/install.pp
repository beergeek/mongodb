# A class to install the Ops Manager Automation Agent on nodes
#
# @summary A class to install the Ops Manager Automation Agent on nodes
# @api private
#
# @example
#   include mongodb::server::install
class mongodb::automation_agent::install(
) {

  assert_private()

  case $facts['os']['family'] {
    'RedHat': {
      Archive {
        user  => 'root',
        group => 'root',
      }

      $_pkg_file = "/tmp/mongodb-mms-automation-agent-manager-latest.x86_64.rhel${facts['os']['release']['major']}.rpm"
      $_provider = 'rpm'
      $_creates  = '/opt/mongodb-mms-automation/bin/mongodb-mms-automation-agent'
      $_auto_agent_pkg_source_uri = "${mongodb::automation_agent::url_svc_type}://${mongodb::automation_agent::ops_manager_fqdn}/download/agent/automation/mongodb-mms-automation-agent-manager-latest.x86_64.rhel${facts['os']['release']['major']}.rpm"
    }
    'windows': {
      $_pkg_file = "mongodb-mms-automation-agent-manager-latest.x86_64.rhel${facts['os']['release']['major']}.rpm"
      $_provider = 'msi'
      $_auto_agent_pkg_source_uri = "${mongodb::automation_agent::url_svc_type}://${mongodb::automation_agent::ops_manager_fqdn}/download/agent/automation/mongodb-mms-automation-agent-manager-latest.x86_64.rhel${facts['os']['release']['major']}.msi"
    }
    default: {
      fail("Your operating system is unsupported: ${facts['os']['family']}")
    }
  }

  archive { $_pkg_file:
    ensure           => present,
    extract          => false,
    source           => $_auto_agent_pkg_source_uri,
    creates          => $_creates,
    download_options => ['--insecure'],
    before           => Package['mongodb-mms-automation-agent-manager'],
  }

  package { 'mongodb-mms-automation-agent-manager':
    ensure   => present,
    source   => $_pkg_file,
    provider => $_provider,
  }

  if $mongodb::automation_agent::enable_ssl and $mongodb::automation_agent::ca_file_content {
    file { 'aa_ca_cert_file':
      ensure  => file,
      path    => $mongodb::automation_agent::ca_file_path,
      owner   => $mongodb::automation_agent::svc_user,
      group   => $mongodb::automation_agent::svc_user,
      mode    => '0644',
      content => $mongodb::automation_agent::ca_file_content,
      require => Package['mongodb-mms-automation-agent-manager'],
    }
  }

  if $mongodb::automation_agent::enable_ssl and $mongodb::automation_agent::pem_file_content {
    file { 'aa_pem_file':
      ensure  => file,
      path    => $mongodb::automation_agent::pem_file_path,
      owner   => $mongodb::automation_agent::svc_user,
      group   => $mongodb::automation_agent::svc_user,
      mode    => '0400',
      content => $mongodb::automation_agent::pem_file_content,
      require => Package['mongodb-mms-automation-agent-manager'],
    }
  }

  if $mongodb::automation_agent::keytab_file_path and $mongodb::automation_agent::keytab_file_content {
    file { 'aa_keytab_file':
      ensure  => file,
      path    => $mongodb::automation_agent::keytab_file_path,
      owner   => $mongodb::automation_agent::svc_user,
      group   => $mongodb::automation_agent::svc_user,
      mode    => '0400',
      content => $mongodb::automation_agent::keytab_file_content,
      require => Package['mongodb-mms-automation-agent-manager'],
    }
  }
}
