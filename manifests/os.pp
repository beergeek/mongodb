# Modifies kernel parameters for database work loads
#
# @summary Modifies kernel parameters for database work loads
#
# @example
#   include mongodb::os
#
class mongodb::os ()
{

  Exec {
    path => '/bin'
  }

  Sysctl {
    persist => true,
  }

  case $facts['os']['family'] {
    'Redhat': {
      if versioncmp($facts['os']['release']['major'], '7') < 0 {
        fail('Wrong operating system version')
      }

      # packages pre-reqs for MongoDB
      ensure_packages(['cyrus-sasl', 'cyrus-sasl-gssapi', 'cyrus-sasl-plain',
      'krb5-libs', 'libcurl', 'libpcap', 'lm_sensors-libs', 'net-snmp',
      'net-snmp-agent-libs', 'openldap', 'openssl', 'rpm-libs', 'tcp_wrappers-libs',
      'policycoreutils-python'], {ensure => present})

      # this has to be done via 'exec' because of Linux restrictions
      exec { 'thp_enabled':
        command => "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled",
        unless  => "/bin/grep -q '\\[never\\]' /sys/kernel/mm/transparent_hugepage/enabled",
      }

      exec { 'thp_defrag':
        command => "echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag",
        unless  => "/bin/grep -q '\\[never\\]' /sys/kernel/mm/transparent_hugepage/defrag",
      }

      exec { 'hugepage_defrag':
        command => "echo '0' > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag",
        unless  => "/bin/grep -q '^0$' /sys/kernel/mm/transparent_hugepage/khugepaged/defrag",
      }

      # Kernel parameters
      sysctl { 'vm.zone_reclaim_mode':
        ensure => present,
        value  => '0',
      }

      sysctl { 'vm.swappiness':
        ensure => present,
        value  => '1',
      }

      sysctl { 'net.ipv4.tcp_keepalive_time':
        ensure => present,
        value  => '300',
      }

      # fix up GRUB for THP on boot
      shellvar { 'GRUB_CMDLINE_LINUX':
        ensure       => present,
        target       => '/etc/default/grub',
        value        => 'transparent_hugepage=never',
        array_append => true,
        notify       => Exec['fix grub'],
      }

      exec { 'fix grub':
        command     => '/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg',
        refreshonly => true,
      }
    }
    default: {
      fail('Sorry, other operating systems have not been implemented as yet')
    }
  }
}
