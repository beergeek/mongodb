require 'spec_helper'

describe 'mongodb::install' do
  context 'on RedHat 7' do
    let :facts do
      {
        os: { 'family' => 'RedHat', 'release' => { 'major' => '7' } },
        operatingsystemmajrelease: '7',
        osfamily: 'RedHat',
        operatingsystem: 'RedHat',
      }
    end

    it { is_expected.to compile }

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

  context 'on Windows 2016' do
    let :facts do
      {
        os:          { 'family' => 'windows', 'release' => { 'major' => '2016' } },
        windows_env: { 'TEMP' => 'C:\temp' },
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('C:\temp\mongodb-enterprise-server.msi').with(
        'ensure'  => 'file',
        'source'  => 'https://downloads.mongodb.com/win32/mongodb-win32-x86_64-enterprise-windows-64-4.0.9-signed.msi',
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
