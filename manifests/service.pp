# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include mongodb::service
define mongodb::service (
  Enum['stopped','running'] $ensure       = 'running',
  String[1]                 $service_name = "mongod_${title}",
) {

  service { $service_name:
    ensure => $ensure,
    enable => true,
  }
}
