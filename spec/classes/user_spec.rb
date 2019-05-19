require 'spec_helper'

describe 'mongodb::user' do
  context 'default on RHEL 7' do
    let :facts do
      {
        os:              { 'family' => 'RedHat', 'release' => { 'major' => '7', 'minor' => '0' } },
        osfamily:        'RedHat',
        operatingsystem: 'RedHat',
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_user('mongod').with(
        'ensure'     => 'present',
        'gid'        => 'mongod',
        'home'       => '/var/lib/mongodb',
        'managehome' => true,
        'system'     => true,
      )
    }

    it {
      is_expected.to contain_group('mongod').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_file('/var/lib/mongodb').with(
        'ensure'  => 'directory',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0750',
      )
    }
  end
end
