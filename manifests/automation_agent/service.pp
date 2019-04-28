# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include mongodb::automation_agent::service
class mongodb::automation_agent::service {

  assert_private()

  service { 'mongodb-mms-automation-agent':
    ensure => running,
    enable => true,
  }
}
