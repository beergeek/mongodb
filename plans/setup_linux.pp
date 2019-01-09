plan mongodb::setup_linux (
  Array[String[1]] $nodes_public_ip,
  String[1]        $certs_dir,
  String[1]        $host_file,
  String[1]        $mongodb_service_user = 'mongod',
) {
  ## Setup MongoDB user to run service
  run_task('mongodb::mongod_linux_user', $nodes_public_ip, username => $mongodb_service_user, '_run_as' => 'root')
  run_command("echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuzXKQA/xsgKrE3GnsGEIBJCMBrryoOtrBukJVv/0w10FLdqT2USNRPsclk3ywUKRL/LMsB9oR10liKOcmeQ3Ddyeh2HFihoZxJmIywWUQPY7YNz6sZ4R368LY8Vnkj939Kuy7uEVrD36/RYP3oeA1zCwoSrqsmdmiWTgO9P/nZQF4tT68znaTb8gw0rutEm3pa2uDzPuyH5qDkaI0NJ49tlcXMcIu8TlFfQmyxeJCmK+8ja+9W271EGvOSE6eO7oidtrnya7iOuMb08ssEsRF+pvUftB3bTnoGCMCWz/DPs52DKFg8IaG00vagHrD59JJMNK8DEgLUiouh5tiVcMv ec2-user@ip-192-168-0-4.ap-southeast-2.compute.internal' >> /home/ec2-user/.ssh/authorized_keys", $nodes_public_ip)
  upload_file($host_file, '/etc/hosts', $nodes_public_ip, '_run_as' => 'root')
  run_command('mkdir -p /var/mongodb/pki', $nodes_public_ip, '_run_as' => 'root')
  upload_file("${certs_dir}/ca.cert.pem","/var/mongodb/pki/ca.pem", $nodes_public_ip, '_run_as' => 'root') 
  $nodes_public_ip.each |Integer $index, String $value| {
    run_command("sudo sh -c \"echo 'hostname=server${index}.mongodb.local' > /etc/sysconfig/network\"", $value)
    run_command("hostname server${index}.mongodb.local", $value, '_run_as' => 'root')
    upload_file("${certs_dir}/server${index}.pem", "/var/mongodb/pki/app0.pem", $value, '_run_as' => 'root')
    run_command("chown ${mongodb_service_user} /var/mongodb/pki/app0.pem", $value, '_run_as' => 'root')
    run_command("chown 0400 /var/mongodb/pki/app0.pem", $value, '_run_as' => 'root')
    run_command("hostname", $value, '_run_as' => 'root')
  }

}
