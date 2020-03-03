plan mongodb::deploy_rs (
  String[24]          $project_id,
  String[1]           $curl_token,
  String[1]           $curl_username,
  String[1]           $ops_manager_url,
  Optional[String[1]] $curl_ca_file_path = undef,
) {

  $current_state = run_task('mongodb::current_deployment','localhost',{
    curl_token      => $curl_token,
    curl_username   => $curl_username,
    ops_manager_url => $ops_manager_url,
    project_id      => $project_id
  })

  return $current_state.first.results
}
