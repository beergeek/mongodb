require 'spec_helper'

describe 'mongodb::service' do
  let(:title) { 'appsdb' }
  
  context 'default on RHEL 7' do
    let :facts do
      {
        os:               { 'family' => 'RedHat', 'release' => { 'major' => '7' , 'minor' => '0'} },
        osfamily:         'RedHat',
        operatingsystem:  'RedHat',
        kernel:           'Linux',
        networking:       { 'ip' => '192.168.0.1'},
        fqdn:             'mongo-prod01.puppet.local',
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_service('mongod_appsdb').with(
        'ensure' => 'running',
        'enable' => true,
      )
    }
  end
end
