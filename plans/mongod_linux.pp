# REQUIRES Bolt 1.8.0
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
  Integer             $cache_size_GB        = 3,
  Optional[String[1]] $bindnic              = undef,
  Optional[String[1]] $ca_path              = undef,
  Optional[String[1]] $extra_config         = undef,
  Optional[String[1]] $keyfile_path         = undef,
  Optional[String[1]] $sharding             = undef,
  Optional[String[1]] $x509_path            = undef,
  String[1]           $mongodb_service_user = 'mongod',
) {

  ## Check we are on the right operating system
  run_task('mongodb::check_el', $nodes)

  # Setup repos
  upload_file($repo_file_path, '/etc/yum.repos.d/mongodb.repo', $nodes, '_run_as' => 'root')
  if $update_os {
    # Update repos
    run_task('mongodb::mongo_repos_linux', $nodes, '_run_as' => 'root')
  }
  if $db_install {
    # Install server
    run_task('mongodb::mongo_server_install', $nodes, '_run_as' => 'root')
  }
  # Configure database
  run_task('mongodb::mongod_server_config', $nodes, use_keyfile => $use_keyfile, use_x509 => $use_x509, x509_path => $x509_path, ca_path => $ca_path, mongodb_service_user => $mongodb_service_user, config_file => $config_file, db_path => $db_path, log_file => $log_file, base_path => $base_path, repset => $repset, keyfile_path => $keyfile_path, bindnic => $bindnic, port => $port, extra_config => $extra_config, sharding => $sharding, '_run_as' => 'root')
  # Run service
  run_task('mongodb::mongod_server_service', $nodes, run_as_service => $run_as_service, config_file => $config_file, '_run_as' => $mongodb_service_user )
  # Initialise Replica Set
  run_task('mongodb::mongod_rs_initiate', $nodes[0], nodes => $rs_nodes, sharding => $sharding, port => $port, repset => $repset, x509_path => $x509_path, ca_path => $ca_path)
  # Sleep for a bit to ensure stuff is setup
  ctrl::sleep(30)
  # Create admin user
  run_task('mongodb::mongod_admin_user', $nodes[0], user => $admin_user, passwd => $admin_password, port => $port, x509_path => $x509_path, ca_path => $ca_path, '_run_as' => $mongodb_service_user )
}
