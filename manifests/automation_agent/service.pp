# Class to manage automation agent service
#
# @summary Class to manage automation agent service
# @api private
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
