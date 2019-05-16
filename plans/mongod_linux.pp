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
# @param port Port number of the service.
# @param repo_file_path Absolute path of the repo config file to manage.
# @param repset Name of the replica set to create.
# @param rs_nodes A comma-separated list of hostnames of the replica set members.
# @param nodes A comma-separated list of nodes to configure. Can be IP or hostnames.
# @param db_install Boolean to determine if server package is installed.
# @param run_as_service Boolean to determine if mongod is run as service or just command.
# @param update_os Boolean to determine if the operating system is updated before installing MongoDB.
# @param use_keyfile Boolean to determine if keyfile is used for clusterAuth.
# @param use_x509 Boolean to determine if x509 is used for clusterAuth.
# @param bindnic If set to a NIC name will use IP address for `bind` statement. If not set
#   will use hostname.
# @param ca_path Absolute path for the CA certificate on the remote node.
# @param extra_config Any extra parameters to include in the config file.
# @param keyfile_path Absolute path for the keyfile on the remote node, if required.
# @param x509_path Absolute path for the x509 certificate, if required.
# @param mongodb_service_user Name of the service user.
#
plan mongodb::mongod_linux (
  String[1]           $admin_password,
  String[1]           $admin_user,
  String[1]           $base_path,
  String[1]           $config_file,
  String[1]           $db_path,
  String[1]           $log_file,
  String[1]           $port,
  String[1]           $repo_file_path,
  String[1]           $repset,
  String[1]           $rs_nodes,
  TargetSpec          $nodes,
  Boolean             $db_install           = true,
  Boolean             $run_as_service       = true,
  Boolean             $update_os            = true,
  Boolean             $use_keyfile          = false,
  Boolean             $use_x509             = true,
  Optional[String[1]] $bindnic              = undef,
  Optional[String[1]] $ca_path              = undef,
  Optional[String[1]] $extra_config         = undef,
  Optional[String[1]] $keyfile_path         = undef,
  Optional[String[1]] $x509_path            = undef,
  String[1]           $mongodb_service_user = 'mongod',
) {

  ## Check we are on the right operating system
  run_task('mongodb::check_el', $nodes)

  # Setup repos
  upload_file($repo_file_path, '/etc/yum.repos.d/mongodb.repo', $nodes, _run_as => 'root')
  if $update_os {
    # Update repos
    notice('Upgrading node....')
    $update_data = run_task('mongodb::mongo_repos_linux', $nodes, _run_as => 'root')
    $update_data.each |$data| {
      notice("${data.target} upgrades: ${data['stdout']}")
    }
  }
  if $db_install {
    # Install server
    $install_db_data = run_task('mongodb::mongo_server_install', $nodes, _run_as => 'root')
    $install_db_data.each |$data| {
      notice("${data.target} DB install: ${data['stdout']}")
    }
  }
  # Configure database
  $config_data = run_task('mongodb::mongod_server_config', $nodes,
    {
      base_path            => $base_path,
      bindnic              => $bindnic,
      ca_path              => $ca_path,
      config_file          => $config_file,
      db_path              => $db_path,
      extra_config         => $extra_config,
      keyfile_path         => $keyfile_path,
      log_file             => $log_file,
      mongodb_service_user => $mongodb_service_user,
      port                 => $port,
      repset               => $repset,
      use_keyfile          => $use_keyfile,
      use_x509             => $use_x509,
      x509_path            => $x509_path,
    },
    _run_as              => 'root'
  )
  $config_data.each |$data| {
      notice("${data.target} DB config: ${data['stdout']}")
    }
  # Run service
  $service_data = run_task('mongodb::mongod_server_service', $nodes,
    {
      config_file    => $config_file,
      run_as_service => $run_as_service,
    },
    _run_as          => $mongodb_service_user
  )
  $service_data.each |$data| {
    notice("${data.target} DB service: ${data['stdout']}")
  }
  # Initialise Replica Set
  $init_data = run_task('mongodb::mongod_rs_initiate', $nodes[0],
    {
      ca_path   => $ca_path,
      port      => $port,
      repset    => $repset,
      rs_nodes  => $rs_nodes,
      x509_path => $x509_path,
    },
  )
  $init_data.each |$data| {
    notice("${data.target} RS Initiate: ${data['stdout']}")
  }
  # Sleep for a bit to ensure stuff is setup
  ctrl::sleep(30)
  # Create admin user
  $user_data = run_task('mongodb::mongod_admin_user', $nodes[0],
    {
      ca_path   => $ca_path,
      passwd    => $admin_password,
      port      => $port,
      user      => $admin_user,
      x509_path => $x509_path,
    },
    _run_as => $mongodb_service_user
  )
  $user_data.each |$data| {
    notice("${data.target} User: ${data['stdout']}")
  }
}
