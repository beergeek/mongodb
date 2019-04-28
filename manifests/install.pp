# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @note As this is a defined type we are not using in-module Hiera for defaults.
#
# @example
#   include mongodb::install
class mongodb::install (
  # Hiera in-module
  String[1]                 $mongodb_version,
  String[1]                 $svc_user,
  Stdlib::Absolutepath      $base_path,
  Stdlib::Absolutepath      $db_base_path,
  Stdlib::Absolutepath      $log_path,
  Stdlib::Absolutepath      $pki_path,

  # Standard defaults
  Boolean                   $install_shell       = true,
  Boolean                   $install_tools       = true,
  Boolean                   $disable_default_svc = true,
  Stdlib::Filesource        $win_file_source     = "https://downloads.mongodb.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${mongodb_version}-signed.msi"
) {
    File {
      owner   => $svc_user,
      group   => $svc_user,
    }

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
    File {
      mode    => '0755',
      seltype => 'mongod_var_lib_t',
      seluser => 'system_u',
    }
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

    selinux::fcontext { "set-${db_base_path}-context":
      ensure   => present,
      seltype  => 'mongod_var_lib_t',
      seluser  => 'system_u',
      pathspec => "${db_base_path}.*",
      notify   => Exec["selinux-${db_base_path}"],
    }

    exec { "selinux-${db_base_path}":
      command     => "/sbin/restorecon -R -v ${db_base_path}",
      refreshonly => true,
    }

    selinux::fcontext { "set-${pki_path}-context":
      ensure   => present,
      seltype  => 'mongod_var_lib_t',
      seluser  => 'system_u',
      pathspec => "${pki_path}.*",
      notify   => Exec["selinux-${pki_path}"],
    }

    exec { "selinux-${pki_path}":
      command     => "/sbin/restorecon -R -v ${pki_path}",
      refreshonly => true,
    }

    selinux::fcontext { "set-${log_path}-context":
      ensure   => present,
      seltype  => 'mongod_log_t',
      seluser  => 'system_u',
      pathspec => "${log_path}.*",
      notify   => Exec["selinux-${log_path}"],
    }

    exec { "selinux-${log_path}":
      command     => "/sbin/restorecon -R -v ${log_path}",
      refreshonly => true,
    }
  }

  file { [ $base_path, $db_base_path, $pki_path ]:
    ensure  => directory,
  }

  file { $log_path:
    ensure  => directory,
    seltype => 'mongod_log_t',
    seluser => 'system_u',
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
