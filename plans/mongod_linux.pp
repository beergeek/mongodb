# REQUIRES Bolt 1.8.0
#
plan mongodb::mongod_linux (
  String[1]           $rs_nodes,
  TargetSpec          $nodes,
  TargetSpec          $primary,
  Boolean             $update_os = true,
  Boolean             $db_install = true,
  String[1]           $repo_file_path = '/Users/brettgray/Documents/Dev/Puppet/mongodb/files/el_7_4.1.repo',
  String[1]           $username = 'mongodb',
  String[1]           $password,
  String[1]           $admin_password,
  String[1]           $admin_user,
  String[1]           $mongodb_service_user = 'mongodb',
  String[1]           $config_file,
  String[1]           $db_path,
  String[1]           $log_file,
  String[1]           $base_path,
  String[1]           $repset,
  String[1]           $keyfile_path,
  String[1]           $bindnic,
  String[1]           $port,
  Optional[String[1]] $sharding     = undef,
  Optional[String[1]] $extra_config = undef,
) {

  $keyfile_data = run_command("openssl rand -base64 756", $primary)
  $keyfile = $keyfile_data.first.value['stdout']
  # Setup MongoDB user to run service
  run_task('mongodb::mongod_linux_user', $nodes, username => $username, password => $password, primary => $primary, '_run_as' => 'root')
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
  run_task('mongodb::mongo_server_config', $nodes, mongodb_service_user => $mongodb_service_user, config_file => $config_file, db_path => $db_path, log_file => $log_file, base_path => $base_path, repset => $repset, keyfile => $keyfile, keyfile_path => $keyfile_path, bindnic => $bindnic, port => $port, extra_config => $extra_config, sharding => $sharding, '_run_as' => 'root')
  # Run service
  run_task('mongodb::mongo_server_service', $nodes, config_file => $config_file, '_run_as' => $mongodb_service_user )
  # Initialise Replica Set
  run_task('mongodb::mongod_rs_initiate', $primary, nodes => $rs_nodes, port => $port, repset => $repset)
  # Sleep for a bit to ensure stuff is setup
  ctrl::sleep(15)
  # Create admin user
  run_task('mongodb::mongod_admin_user', $primary, user => $admin_user, passwd => $admin_password, port => $port, '_run_as' => $mongodb_service_user )
}
