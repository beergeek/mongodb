# Defined type to manage mongod service
#
# @summary Defined type to manage mongod service.
#
# @param ensure What state to have the service in. `running` or `stopped`.
# @param service_name Name of the service to manage.
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
