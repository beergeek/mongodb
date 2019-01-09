#
#
plan mongodb::mongos_linux (
  TargetSpec          $nodes,
  Boolean             $update_os = false,
  Boolean             $db_install = true,
  String[1]           $repo_file_path,
  String[1]           $mongodb_service_user = 'mongod',
  String[1]           $config_file,
  String[1]           $log_file,
  String[1]           $base_path,
  String[1]           $config_svr_list,
  String[1]           $repset,
  String[1]           $port,
  Optional[String[1]] $bindnic      = undef,
  Optional[String[1]] $extra_config = undef,
  Optional[String[1]] $keyfile_path = undef,
  Optional[String[1]] $keyfile      = undef,
  Optional[String[1]] $x509_path    = undef,
  Optional[String[1]] $ca_path      = undef,
) {

  ## Setup repos
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
  run_task('mongodb::mongos_server_config', $nodes, repset => $repset, config_svr_list => $config_svr_list, x509_path => $x509_path, ca_path => $ca_path, mongodb_service_user => $mongodb_service_user, config_file => $config_file, log_file => $log_file, base_path => $base_path, keyfile => $keyfile, keyfile_path => $keyfile_path, bindnic => $bindnic, port => $port, extra_config => $extra_config, '_run_as' => 'root')
  # Run service
  run_task('mongodb::mongos_server_service', $nodes, config_file => $config_file, '_run_as' => $mongodb_service_user )
}
