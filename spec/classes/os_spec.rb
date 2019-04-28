require 'spec_helper'

describe 'mongodb::os' do
  context "on RedHat 7" do
    let :facts do
      {
        os: {'family' => 'RedHat', 'release' => {'major' => '7'}},
      }
    end
    it { is_expected.to compile }

    it {
      is_expected.to contain_package('cyrus-sasl-gssapi').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('cyrus-sasl-plain').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('cyrus-sasl').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('krb5-libs').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('libcurl').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('libpcap').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('lm_sensors-libs').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('net-snmp-agent-libs').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('net-snmp').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('openldap').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('openssl').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('policycoreutils-python').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('rpm-libs').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('tcp_wrappers-libs').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_exec('thp_enabled').with(
        'command' => "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled",
        'unless'  => "/bin/grep -q '\\[never\\]' /sys/kernel/mm/transparent_hugepage/enabled",
      )
    }

    it {
      is_expected.to contain_exec('thp_defrag').with(
        'command' => "echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag",
        'unless'  => "/bin/grep -q '\\[never\\]' /sys/kernel/mm/transparent_hugepage/defrag",
      )
    }

    it {
      is_expected.to contain_exec('hugepage_defrag').with(
        'command' => "echo '0' > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag",
        'unless'  => "/bin/grep -q '^0$' /sys/kernel/mm/transparent_hugepage/khugepaged/defrag",
      )
    }

    it {
      is_expected.to contain_sysctl('vm.zone_reclaim_mode').with(
        'ensure'  => 'present',
        'value'   => '0',
        'persist' => true
      )
    }

    it {
      is_expected.to contain_sysctl('vm.swappiness').with(
        'ensure'  => 'present',
        'value'   => '1',
        'persist' => true
      )
    }

    it {
      is_expected.to contain_sysctl('net.ipv4.tcp_keepalive_time').with(
        'ensure'  => 'present',
        'value'   => '300',
        'persist' => true
      )
    }

    it {
      is_expected.to contain_shellvar('GRUB_CMDLINE_LINUX').with(
        'ensure'       => 'present',
        'target'       => "/etc/default/grub",
        'value'        => "transparent_hugepage=never",
        'array_append' => true,
      ).that_notifies("Exec[fix grub]")
    }

    it {
      is_expected. to contain_exec('fix grub').with(
        'command'     => '/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg',
        'refreshonly' => true,
      )
    }

  end
end
