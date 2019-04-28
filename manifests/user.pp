# Manage the mongodb instance service user
#
# @summary Manage the mongodb instance service user
#
# @param svc_user The name of the user and group to create and manage.
# @param home_dir The absolute path of the home directory for the serivce user.
#
# @example
#   include mongodb::user
class mongodb::user (
  String[1]            $svc_user,
  Stdlib::Absolutepath $home_dir,
) {

  user { $svc_user:
    ensure     => present,
    gid        => $svc_user,
    home       => $home_dir,
    managehome => true,
    system     => true,
  }

  group { $svc_user:
    ensure => present,
  }

  file { $home_dir:
    ensure => directory,
    owner  => $svc_user,
    group  => $svc_user,
    mode   => '0750',
  }
}
