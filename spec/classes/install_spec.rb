require 'spec_helper'

describe 'mongodb::install' do
  context "on RedHat 7" do
    let :facts do
      {
        os: {'family' => 'RedHat', 'release' => {'major' => '7'}},
        operatingsystemmajrelease: '7',
        osfamily: 'RedHat',
        operatingsystem: 'RedHat',
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('/data').with(
        'ensure'  => 'directory',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0755',
        'seltype' => 'mongod_var_lib_t',
      )
    }

    it {
      is_expected.to contain_file('/data/db').with(
        'ensure'  => 'directory',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0755',
        'seltype' => 'mongod_var_lib_t',
      )
    }

    it {
      is_expected.to contain_file('/data/logs').with(
        'ensure'  => 'directory',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0755',
        'seltype' => 'mongod_log_t',
      )
    }

    it {
      is_expected.to contain_file('/data/pki').with(
        'ensure'  => 'directory',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0755',
        'seltype' => 'mongod_var_lib_t',
      )
    }
    
    it {
      is_expected.to contain_file('/data/db').with(
        'ensure'  => 'directory',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0755',
        'seltype' => 'mongod_var_lib_t',
        'seluser' => 'system_u',
      )
    }

    it {
      is_expected.to contain_selinux__fcontext('set-/data/db-context').with(
        'ensure'    => 'present',
        'seltype'   => 'mongod_var_lib_t', 
        'seluser'   => 'system_u', 
        'pathspec'  => '/data/db.*',
      ).that_notifies('Exec[selinux-/data/db]')
    }

    it {
      is_expected.to contain_exec('selinux-/data/db').with(
        'command'     => '/sbin/restorecon -R -v /data/db',
        'refreshonly' => true,
      )
    }

    it {
      is_expected.to contain_selinux__fcontext('set-/data/pki-context').with(
        'ensure'    => 'present',
        'seltype'   => 'mongod_var_lib_t', 
        'seluser'   => 'system_u', 
        'pathspec'  => '/data/pki.*',
      ).that_notifies('Exec[selinux-/data/pki]')
    }

    it {
      is_expected.to contain_exec('selinux-/data/pki').with(
        'command'     => '/sbin/restorecon -R -v /data/pki',
        'refreshonly' => true,
      )
    }

    it {
      is_expected.to contain_selinux__fcontext('set-/data/logs-context').with(
        'ensure'    => 'present',
        'seltype'   => 'mongod_log_t', 
        'seluser'   => 'system_u', 
        'pathspec'  => '/data/logs.*',
      ).that_notifies('Exec[selinux-/data/logs]')
    }

    it {
      is_expected.to contain_exec('selinux-/data/logs').with(
        'command'     => '/sbin/restorecon -R -v /data/logs',
        'refreshonly' => true,
      )
    }

    it {
      is_expected.to contain_package('mongodb-enterprise-shell').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('mongodb-enterprise-tools').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_package('mongodb-enterprise-server').with(
        'ensure' => 'present',
      ).without(['source']).without(['install_options'])
    }

    it {
      is_expected.to contain_service('mongod').with(
        'ensure' => 'stopped',
        'enable' => false,
      )
    }
  end

  context "on Windows 2016" do
    let :facts do
      {
        os:          {'family' => 'windows', 'release' => {'major' => '2016'}},
        windows_env: {'TEMP' => 'C:\temp'}
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('C:\data').with(
        'ensure'  => 'directory',
        'owner'   => 'mongod',
        'group'   => 'mongod',
      )
    }

    it {
      is_expected.to contain_file('C:\data\db').with(
        'ensure'  => 'directory',
        'owner'   => 'mongod',
        'group'   => 'mongod',
      )
    }

    it {
      is_expected.to contain_file('C:\data\logs').with(
        'ensure'  => 'directory',
        'owner'   => 'mongod',
        'group'   => 'mongod',
      )
    }

    it {
      is_expected.to contain_file('C:\data\pki').with(
        'ensure'  => 'directory',
        'owner'   => 'mongod',
        'group'   => 'mongod',
      )
    }

    it {
      is_expected.to contain_file('C:\temp\mongodb-enterprise-server.msi').with(
        'ensure'  => 'file',
        'source'  => 'https://downloads.mongodb.com/win32/mongodb-win32-x86_64-enterprise-windows-64-4.0.9-signed.msi'
      ).that_comes_before('Package[mongodb-enterprise-server]')
    }

    it {
      is_expected.to contain_package('mongodb-enterprise-server').with(
        'ensure' => 'present',
        'source' => 'C:\temp\mongodb-enterprise-server.msi',
      )
    }

    it {
      is_expected.to contain_service('mongod').with(
        'ensure' => 'stopped',
        'enable' => false,
      )
    }
  end
end
