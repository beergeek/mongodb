# Performs a check to determine if Production Notes have been applied to a Linux node.
#
# @summary Performs a check to determine if Production Notes have been applied to a Linux node.
#
# @param nodes Array of nodes to check, IP addresses or hostnames.
# @param drive The disk to check for NUMA, e.g. `/dev/sda2`.
#
# @example
#   puppet plan run mongodb::mongo_check drive=/dev/sda2 --nodes 1.2.3.4,5.6.7.8
#
plan mongodb::mongo_check (
  TargetSpec $nodes,
  String     $drive,
) {

  $a = run_command('uname -a', $nodes, '_run_as' => 'root')
  $a.each |$data| {
    notice("${data.target} `uname`: ${data['stdout']}")
  }
  $b = run_command("blockdev --getra ${drive}", $nodes, '_run_as' => 'root')
  $b.each |$data| {
    notice("${data.target} blockdev for ${drive}: ${data['stdout']}")
  }
  $c = run_command('mount -l', $nodes, '_run_as' => 'root')
  $c.each |$data| {
    notice("${data.target} mounts: ${data['stdout']}")
  }
  $d = run_command('cat /etc/fstab', $nodes, '_run_as' => 'root')
  $d.each |$data| {
    notice("${data.target} mounts: ${data['stdout']}")
  }
  $e = run_command('cat /sys/kernel/mm/transparent_hugepage/enabled', $nodes, '_run_as' => 'root')
  $e.each |$data| {
    notice("${data.target} mounts: ${data['stdout']}")
  }
  $f = run_command('sysctl -a | grep reclaim', $nodes, '_run_as' => 'root')
  $f.each |$data| {
    notice("${data.target} mounts: ${data['stdout']}")
  }
  $g = run_command('cat /proc/cpuinfo', $nodes, '_run_as' => 'root')
  $g.each |$data| {
    notice("${data.target} mounts: ${data['stdout']}")
  }
  $h = run_command('free -m', $nodes, '_run_as' => 'root')
  $h.each |$data| {
    notice("${data.target} mounts: ${data['stdout']}")
  }
  $i = run_command('cat /etc/security/limits.conf', $nodes, '_run_as' => 'root')
  $i.each |$data| {
    notice("${data.target} mounts: ${data['stdout']}")
  }
  $j = run_command('cat /etc/security/limits.d/*', $nodes, '_run_as' => 'root')
  $j.each |$data| {
    notice("${data.target} mounts: ${data['stdout']}")
  }
  return 'Finished checking'
}
