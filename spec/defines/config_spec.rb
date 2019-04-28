require 'spec_helper'

describe 'mongodb::config' do
  let(:title) { 'rep01' }
  
  context 'default on RHEL 7 with `none` for clusterAuth' do
    let :facts do
      {
        os:                        { 'family' => 'RedHat', 'release' => { 'major' => '7' , 'minor' => '0'} },
        osfamily:                  'RedHat',
        operatingsystem:           'RedHat',
        operatingsystemmajrelease: '7',
        kernel:                    'Linux',
        networking:                { 'ip' => '192.168.0.1', 'fqdn' => 'mongo-prod01.puppet.local'},
        fqdn:                      'mongo-prod01.puppet.local',
      }
    end
    let :params do
      {
        member_auth: 'none',
        ssl_mode: 'none',
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('/data/db/rep01').with(
        'ensure'  => 'directory',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0755',
        'seltype' => 'mongod_var_lib_t',
        'seluser' => 'system_u',
      )
    }

    it {
      is_expected.to contain_selinux__fcontext('set-/data/db/rep01-context').with(
        'ensure'    => 'present',
        'seltype'   => 'mongod_var_lib_t', 
        'seluser'   => 'system_u', 
        'pathspec'  => '/data/db/rep01.*',
      ).that_notifies('Exec[selinux-/data/db/rep01]')
    }

    it {
      is_expected.to contain_exec('selinux-/data/db/rep01').with(
        'command'     => '/sbin/restorecon -R -v /data/db/rep01',
        'refreshonly' => true,
      )
    }

    it {
      is_expected.to contain_file('/etc/mongod_rep01.conf').with(
        'ensure'  => 'file',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0400',
        'seltype' => 'etc_t',
      )
    }

    it {
      is_expected.to contain_file('/lib/systemd/system/mongod_rep01.service').with(
        'ensure'  => 'file',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0644',
        'seltype' => 'mongod_unit_file_t',
        'seluser' => 'system_u',
      ).that_notifies('Exec[restart_systemd_daemon-rep01]')
    }

    it {
      is_expected.to contain_exec('restart_systemd_daemon-rep01').with(
        'command'     => '/usr/bin/systemctl daemon-reload',
        'refreshonly' => true,
      )
    }
  end
end
