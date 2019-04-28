require 'spec_helper'

describe 'mongodb::repos' do
  context 'default on RHEL 7' do
    let :facts do
      {
        os:              { 'family' => 'RedHat', 'release' => { 'major' => '7' , 'minor' => '0'} },
        osfamily:        'RedHat',
        operatingsystem: 'RedHat',
      }
    end

    it do
      is_expected.to contain_yumrepo('mongodb-enterprise').with(
        'ensure'    => 'present',
        'descr'     => 'MongoDB Enterprise Repository',
        'baseurl'   => 'https://repo.mongodb.com/yum/redhat/7/mongodb-enterprise/4.0/x86_64/',
        'gpgcheck'  => true,
        'enabled'   => true,
        'gpgkey'    => 'https://www.mongodb.org/static/pgp/server-4.0.asc',
      )
    end
  end
end
