require 'spec_helper'

describe 'mongodb::bi_connecter' do

  context 'default on RHEL 7' do
    let :facts do
      {
        os: { 'family' => 'RedHat', 'release' => { 'major' => '7' , 'minor' => '0'} },
        osfamily: 'RedHat',
        operatingsystem: 'RedHat',
        kernel: 'Linux',
      }
    end
    let(:params) do
      {
        bic_source_url: 'https://',
        bic_schema_user: 'schema_user',
        bic_schema_user_passwd: RSpec::Puppet::RawString.new("Sensitive('test')"),
      }
    end
    it { is_expected.to compile }

    it do
      is_expected.to_not contain_file('/etc/mongosql.conf')
    end

    it do
      is_expected.to_not contain_file('')
    end
  end
end
