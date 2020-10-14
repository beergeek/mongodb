# A plan to instance and configure mongo server on Linux.
#
# @summary A plan to instance and configure mongo server on Linux.
# @note REQUIRES Bolt 1.8.0
#
# @param admin_password Password for the first user (admin user).
# @param admin_user Name of the first user (admin user).
# @param base_path The absolute path of where all the database, log and PKI directories will reside.
# @param config_file The absolute path of the configuration file to manage.
# @param db_path The absolute path to where the database will be stored (should include the `base_path`).
# @param log_file The absolute path of the log file (should include the `base_path`).
# @param log_append Boolean to determine if log is appended or a new log created on restart.
# @param port Port number of the service.
# @param repo_file_path Absolute path of the repo config file to manage.
# @param repset Name of the replica set to create.
# @param nodes A comma-separated list of nodes to configure. Can be IP or hostnames.
# @param db_install Boolean to determine if server package is installed.
# @param run_as_service Boolean to determine if mongod is run as service or just command.
# @param update_os Boolean to determine if the operating system is updated before installing MongoDB.
# @param bindip If set it will use the FQDN of the instance, or '0.0.0.0'.
# @param ca_path Absolute path for the CA certificate on the remote node.
# @param extra_config Any extra parameters to include in the config file.
# @param keyfile_path Absolute path for the keyfile on the remote node, if required.
# @param x509_path Absolute path for the x509 certificate, if required.
# @param mongodb_service_user Name of the service user.
# @param instances An array of hashes containing data of replica set members used to build the replica set.
#   The node in the array will start off as the primary node, therefore do NOT make this an arbitor or hidden node.
# @param ssl_mode The mode of SSL/TLS.
# @param member_auth The mode of the replica set cluster authentication.
#
plan mongodb::mongod_linux (
  Array[
    Struct[{
      host                   => TargetSpec,
      Optional[arbiter]      => Boolean,
      Optional[base_path]    => String[1],
      Optional[bindip]       => String[1],
      Optional[config_file]  => String[1],
      Optional[db_path]      => String[1],
      Optional[hidden]       => Boolean,
      Optional[log_file]     => String[1],
      Optional[log_append]   => Boolean,
      Optional[port]         => Integer,
      Optional[priority]     => Integer,
      Optional[slavedelay]   => Integer,
      Optional[tags]         => Hash,
      Optional[votes]        => Integer,
      Optional[keyfile_path] => String[1],
      Optional[x509_path]    => String[1],
    }]
  ]                                        $instances,
  String[1]                                $admin_password,
  String[1]                                $admin_user,
  String[1]                                $repo_file_path,
  String[1]                                $repset,
  Boolean                                  $db_install           = true,
  Boolean                                  $run_as_service       = true,
  Boolean                                  $update_os            = true,
  Optional[String[1]]                      $ca_path              = undef,
  Optional[String[1]]                      $extra_config         = undef,
  String[1]                                $mongodb_service_user = 'mongod',
  Enum['x509', 'keyFile', 'none']          $member_auth          = 'x509',
  Enum['requireSSL','preferSSL','none']    $ssl_mode             = 'requireSSL',
) {

  $nodes = $instances.map |$instance| {$instance['host']}
  $primary_node = get_targets($nodes[0])

  ## Check we are on the right operating system
  run_task('mongodb::check_el', $nodes)

  # Setup repos
  upload_file($repo_file_path, '/etc/yum.repos.d/mongodb.repo', $nodes, _run_as => 'root')
  if $update_os {
    # Update repos
    notice('Upgrading node....')
    $update_data = run_task('mongodb::mongo_repos_linux', $nodes, _run_as => 'root')
    $update_data.each |$data| {
      out::message("OS upgrades: ${data}\n")
    }
  }
  if $db_install {
    # Install server
    $install_db_data = run_task('mongodb::mongo_server_install', $nodes, _run_as => 'root')
    $install_db_data.each |$data| {
      out::message("DB install: ${data}\n")
    }
  }
  # Configure database
  $instances.each |Hash $instance_data| {

    if $member_auth == 'keyFile' and !($instance_data['keyfile_path']) {
      fail('If `keyFile` is selected for the $member_auth a keyfile location must be provided')
    }

    if ($member_auth == 'x509' or $ssl_mode != 'none') and !($instance_data['x509_path']) {
      fail('The selection of `x509` for $member_auth or enabling SSL/TLS (via $ssl_mode) requires a value for `pem_file`')
    }

    $_instance = get_targets($instance_data['host'])
    if $instance_data['bindip'] {
      $_bindip = $instance_data['bindip']
    } else {
      $_bindip = '0.0.0.0'
    }
    if $instance_data['base_path'] {
      $_base_path = $instance_data['base_path']
    } else {
      $_base_path = '/data'
    }
    if $instance_data['db_path'] {
      $_db_path = $instance_data['db_path']
    } else {
      $_db_path = "${_base_path}/db"
    }
    if $instance_data['config_file'] {
      $_config_file = $instance_data['config_file']
    } else {
      $_config_file = "${_db_path}/mongod.conf"
    }
    if $instance_data['log_file'] {
      $_log_file = $instance_data['log_file']
    } else {
      $_log_file = "${_base_path}/logs/mongod.log"
    }
    if $instance_data['port'] {
      $_port = $instance_data['port']
    } else {
      $_port = '27017'
    }
    $_pid = "/var/run/mongodb/mongod_${repset}_${_port}"

    $config_hash = epp('mongodb/config.epp', {
      auth_list           => 'SCRAM-SHA-256',
      bindip              => $_bindip,
      cluster_pem_file    => undef,
      ca_file             => $ca_path,
      dbpath              => $_db_path,
      enable_kerberos     => false,
      enable_ldap_authn   => false,
      enable_ldap_authz   => false,
      keyfile_path        => $instance_data['keyfile_path'],
      log_filename        => basename($_log_file),
      log_append          => $log_append,
      logpath             => dirname($_log_file),
      pem_file            => $instance_data['x509_path'],
      pid_file            => $_pid,
      port                => $_port,
      repset              => $repset,
      ssl_mode            => $ssl_mode,
      wiredtiger_cache_gb => undef,
      member_auth         => $member_auth,
    })

    $config_data = run_task('mongodb::mongod_server_config', $_instance,
      base_path            => $_base_path,
      config_file_data     => $config_hash,
      config_file          => $_config_file,
      db_path              => $_db_path,
      log_file             => $_log_file,
      mongodb_service_user => $mongodb_service_user,
      _run_as              => 'root'
    )

    $config_data.each |$data| {
      out::message("DB config: ${data}\n")
    }

    # Create service file if service required
    if $run_as_service {
      $service_config = epp('mongodb/service_file', {
        conf_file           => $_config_file,
        debug_kerberos      => false,
        enable_kerberos     => false,
        kerberos_trace_path => undef,
        keytab_file_path    => undef,
        pid_file            => $_pid,
        pid_path            => dirname($_pid),
        svc_user            => $mongodb_service_user,
      })
      run_command("echo -en '${service_config}' | sudo tee /lib/systemd/system/mongod_${repset}_${_port}.service", $_instance, _run_as => 'root')
      $reload = run_command('systemctl daemon-reload', $_instance, _run_as => 'root')
      $reload.each |$data| {
        out::message("DB service reload: ${data}\n")
      }
    }
    run_command('systemctl stop mongod', $_instance, _run_as => 'root')
    run_command('systemctl disable mongod', $_instance, _run_as => 'root')

    # Run service
    $service_data = run_task('mongodb::mongod_server_service', $_instance,
      config_file    => $_config_file,
      service_name   => "mongod_${repset}_${_port}.service",
      run_as_service => $run_as_service,
      _run_as        => 'root'
    )
    $service_data.each |$data| {
      out::message("DB service: ${data}\n")
    }
  }

  if $instances[0]['priority'] {
    $_priority = $instances[0]['priority']
  } else {
    $_priority = 1
  }
  if $instances[0]['votes'] {
    $_votes = $instances[0]['votes']
  } else {
    $_votes = 1
  }
  if $instances[0]['tags'] {
    $_tags = $instances[0]['tags']
  } else {
    $_tags = {}
  }
  if $instances[0]['port'] {
    $_port = $instances[0]['port']
  } else {
    $_port = 27017
  }
  # Initialise Replica Set
  $init_data = run_task('mongodb::mongod_rs_initiate', $primary_node,
    {
      ca_path    => $ca_path,
      port       => $_port,
      repset     => $repset,
      host       => $instances[0]['host'],
      x509_path  => $instances[0]['x509_path'],
      arbiter    => 0,
      priority   => $_priority,
      hidden     => 0,
      slavedelay => 0,
      tags       => $_tags,
      votes      => $_votes,
    }
  )
  $init_data.each |$data| {
    notice("${data.target} RS Initiate: ${data}")
  }

  # Sleep for a bit to ensure stuff is setup
  ctrl::sleep(30)

  # Create admin user
  $user_data = run_task('mongodb::mongod_admin_user', $primary_node,
    ca_path           => $ca_path,
    passwd            => $admin_password,
    port              => $_port,
    user              => $admin_user,
    x509_path         => $instances[0]['x509_path'],
    _run_as           => $mongodb_service_user
  )
  $user_data.each |$data| {
    notice("${data.target} User: ${data}")
  }

  $instances.each |Integer $index, Hash $instance_hash| {
    if $index != 0 {
      if $instance_hash['priority'] {
        $_priority = $instance_hash['priority']
      } else {
        $_priority = 1
      }
      if $instance_hash['votes'] {
        $_votes = $instance_hash['votes']
      } else {
        $_votes = 1
      }
      if $instance_hash['tags'] {
        $_tags = $instance_hash['tags']
      } else {
        $_tags = {}
      }
      if $instance_hash['arbiter'] {
        $_arbiter = $instance_hash['arbiter']
      } else {
        $_arbiter = 0
      }
      if $instance_hash['hidden'] {
        $_hidden = $instance_hash['hidden']
      } else {
        $_hidden = 0
      }
      if $instance_hash['slavedelay'] {
        $_slavedelay = $instance_hash['slavedelay']
      } else {
        $_slavedelay = 0
      }
      if $instance_hash['port'] {
        $_port = $instance_hash['port']
      } else {
        $_port = '27017'
      }
      if $instances[0]['port'] {
        $_primary_port = $instances[0]['port']
      } else {
        $_primary_port = '27017'
      }
      $finish_data = run_task('mongodb::mongod_rs_finish', $primary_node,
        {
          arbiter    => $_arbiter,
          ca_path    => $ca_path,
          count      => $index,
          hidden     => $_hidden,
          host       => $instance_hash['host'],
          password   => $admin_password,
          port       => $_port,
          priority   => $_priority,
          repset     => $repset,
          slavedelay => $_slavedelay,
          tags       => $_tags,
          user       => $admin_user,
          votes      => $_votes,
          x509_path  => $instance_hash['x509_path'],
          primary    => $instances[0]['host'],
          primary_pt => $_primary_port,
        }
      )
      $finish_data.each |$data| {
        notice("${data.target} RS Completion: ${data}")
      }
    }
  }
}
