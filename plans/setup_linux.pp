# Plan to setup initial config for installation and operation of MongoDB on RHEL 7
#
# @summary A Plan to setup various OS-level features and security for `mongod` and `mongos`.
#
# @param nodes An Array of the IP addresses or hostnames of the nodes to configure
# @param replicaset_name The name of the application the server certificate will be used for. The certificate
#   will be rename to `${replicaset_name}.pem` under the '/var/mongodb/pki' directory.
# @param ca_path Full path and file name of the CA cert on the remote node for x509 auth.
# @param ca_filename File name of CA cert on local node within the the `$node_certs_dir`.
# @param node_certs_dir Full path of the directory where all the x509 certificates reside for the nodes.
#   Certs are placed in '/var/mongodb/pki'.
# @param node_common_name The common name for each node that a number will be appended to, e.g. 'server'
#   will become server0, server1... etc etc
# @param node_domain_node The domain for each server, e.g. 'mongodb.local'.
# @param use_keyfile Boolean to determine if keyfile is used. Is overriden by `use_x509`.
#   The keyfile is common to all nodes and in the format `${node_certs_dir}/${node_common_name}.key`.
# @param use_x509 Boolean to determine if x509 certs are used. Overrides `use_keyfile`.
#   Format of certificate path and name is `${node_certs_dir}/${node_common_name}${index}.pem`.
# @param host_file Optional file path of the host file to uploaed.
# @param mongodb_service_user Name of the system user to create, with home directory, for the `mongod` or mongos` service.
# @param use_tuned Boolean to determine if 'tuned' or explict commands are used to manage certain Production Nodes.
# @param tuned_config_file The absolute path on the local machine to a 'tuned' configuration file. Must be provided if
#   `use_tuned` is 'true'.
# @param local_certs_dir The local directory where certificates are stored.
#
plan mongodb::setup_linux (
  Array[String[1]]    $nodes,
  String[1]           $replicaset_name,
  String[1]           $node_domain_node,
  Boolean             $use_keyfile          = false,
  Boolean             $use_tuned            = false,
  Boolean             $use_x509             = true,
  Integer             $server_count_offset  = 0,
  Optional[String[1]] $ca_path              = '/data/pki/ca.pem',
  Optional[String[1]] $ca_filename          = undef,
  Optional[String[1]] $host_file            = undef,
  Optional[String[1]] $tuned_config_file    = undef,
  String[1]           $node_certs_dir       = '/certs',
  String[1]           $local_certs_dir      = '/data/pki',
  String[1]           $mongodb_service_user = 'mongod',
  String[1]           $node_common_name     = 'mongod',
) {

  # Check we are on the right operating system
  run_task('mongodb::check_el', $nodes)

  if $use_tuned and !$tuned_config_file {
    fail('When `use_tuned` is true the `tuned_config_file` parameter must be provided.')
  }

  if $use_tuned {
    # Install tuned
    run_command('yum install -y tuned', $nodes, _run_as => 'root')
    run_command('mkdir -p /etc/tuned/mongodb', $nodes, _run_as => 'root')
    run_command('systemctl start tuned', $nodes, _run_as => 'root')
    run_command('systemctl enable tuned', $nodes, _run_as => 'root')
    upload_file($tuned_config_file, '/etc/tuned/mongodb/tuned.conf', $nodes, _run_as => 'root')
    run_command('tuned-adm profile mongodb', $nodes, _run_as => 'root')
  } else {
    run_command('sysctl -w  vm.zone_reclaim_mode=0', $nodes, _run_as => 'root')
    run_command("grep -q 'vm.zone_reclaim_mode' /etc/sysctl.conf || echo 'vm.zone_reclaim_mode=0' | sudo tee --append /etc/sysctl.conf",
      $nodes,
      _run_as => 'root'
    )
    run_command("awk '{if (\$0 ~ /^GRUB_CMDLINE_LINUX=/) {gsub(\"transparent_hugepage=[[:alnum:]]*[[:space:]]\?\",
       \"\", \$0) ; gsub(\"[[:space:]]?\\\"\$\", \" transparent_hugepage=never\\\"\"); print \$0 > \"/etc/default/grub\" }}'
       < /etc/default/grub",
      $nodes,
      _run_as => 'root')
    run_command('[ -d /sys/firmware/efi ] && sudo grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg ||
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg', $nodes, _run_as => 'root')
    run_command("sh -c \"echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled\"", $nodes, _run_as => 'root')
    run_command("sh -c \"echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag\"", $nodes, _run_as => 'root')
    run_command("sh -c \"echo '0' > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag\"", $nodes, _run_as => 'root')
  }
  run_command('sysctl -w  vm.swappiness=1', $nodes, _run_as => 'root')
  run_command("grep -q 'vm.swappiness' /etc/sysctl.conf || echo 'vm.swappiness=1' | sudo tee --append /etc/sysctl.conf",
    $nodes,
    _run_as => 'root'
  )

  # Setup MongoDB user to run service
  run_task('mongodb::mongodb_linux_user', $nodes, username => $mongodb_service_user, _run_as => 'root')

  # Upload hosts file if provided
  if $host_file and $host_file != 'null' {
    upload_file($host_file, '/etc/hosts', $nodes, _run_as => 'root')
  }

  # Create PKI directory for certificates
  run_command("mkdir -p ${node_certs_dir}", $nodes, _run_as => 'root')

  if $ca_path and $ca_path != 'null' and $ca_filename and $ca_filename != 'null' {
    # Upload the CA cert
    upload_file("${local_certs_dir}/${ca_filename}", $ca_path, $nodes, _run_as => 'root')
  }

  # Iterate through each node and configure unique items
  $nodes.each |Integer $index, String $value| {
    notice("Setting specific to ${value}")
    $_index = $index + $server_count_offset
    # Set hostname
    run_command("echo 'hostname=${node_common_name}${_index}.${node_domain_node}' | sudo tee /etc/sysconfig/network",
      $value,
      _run_as => 'root'
    )
    run_command("hostnamectl set-hostname --static ${node_common_name}${_index}.${node_domain_node}", $value, _run_as => 'root')

    if $use_x509 {
      # Upload server certificate to /var/mongodb/pki, then change ownership and permissions
      upload_file("${local_certs_dir}/${node_common_name}${_index}.pem", "${node_certs_dir}/${replicaset_name}.pem",
        $value, _run_as => 'root')
      run_command("chown ${mongodb_service_user} ${node_certs_dir}/${replicaset_name}.pem", $value, _run_as => 'root')
      run_command("chown 0400 ${node_certs_dir}/${replicaset_name}.pem", $value, _run_as => 'root')
    } elsif $use_keyfile {
      # Upload keyfile to /var/mongodb/pki, then change ownership and permissions
      upload_file("${certs_dir}/${node_common_name}.key", "${node_certs_dir}/${replicaset_name}.key", $value, _run_as => 'root')
      run_command("chown ${mongodb_service_user} ${node_certs_dir}/${replicaset_name}.key", $value, _run_as => 'root')
      run_command("chown 0400 ${node_certs_dir}/${replicaset_name}.key", $value, _run_as => 'root')
    }

    run_command('echo `hostname`', $value, _run_as => 'root')
  }

}
