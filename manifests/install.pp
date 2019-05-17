# Class to manage the installation of MongoDB.
#
# @summary Class to manage the installation of MongoDB.
#
# @param mongodb_version Version of MongoDB to install.
# @param install_shell Boolean to determine if shell is installed.
# @param install_tools Boolean to determine if tools are installed.
# @param disable_default_svc Boolean to determine if default service is stopped and disabled.
# @param win_file_source URL of source for Windows installer.
#
# @example
#   include mongodb::install
class mongodb::install (
  # Hiera in-module
  String[1]                 $mongodb_version,

  # Standard defaults
  Boolean                   $install_shell       = true,
  Boolean                   $install_tools       = true,
  Boolean                   $disable_default_svc = true,
  Stdlib::Filesource        $win_file_source     = "https://downloads.mongodb.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${mongodb_version}-signed.msi"
) {

  if $facts['os']['family'] == 'windows' {
    $_package_source = "${facts['windows_env']['TEMP']}\\mongodb-enterprise-server.msi"

    file { $_package_source:
      ensure => file,
      source => $win_file_source,
      before => Package['mongodb-enterprise-server'],
    }

    if $install_shell and $install_tools {
      $_install_options = "ADDLOCAL='Client,ImportExportTools,MiscellaneousTools,MonitoringTools'"
    } elsif $install_shell {
      $_install_options = "ADDLOCAL='Client'"
    } elsif $install_tools {
      $_install_options = "ADDLOCAL='ImportExportTools,MiscellaneousTools,MonitoringTools'"
    } else {
      $_install_options = undef
    }

    $_install_options_array = ['/l*v mdbinstall.log', '/qb', '/i',"SHOULD_INSTALL_COMPASS='0'", $_install_options]
  } else {
    require mongodb::repos

    if $install_shell {
      package { 'mongodb-enterprise-shell':
        ensure  => present,
        require => Package['mongodb-enterprise-server'],
      }
    }

    if $install_tools {
      package { 'mongodb-enterprise-tools':
        ensure  => present,
        require => Package['mongodb-enterprise-server'],
      }
    }

    $_package_source        = undef
    $_install_options_array = undef
  }

  package { 'mongodb-enterprise-server':
    ensure          => present,
    source          => $_package_source,
    install_options => $_install_options_array,
  }

  if $disable_default_svc {
    service { 'mongod':
      ensure  => stopped,
      enable  => false,
      require => Package['mongodb-enterprise-server'],
    }
  }
}
