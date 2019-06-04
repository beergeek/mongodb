require 'spec_helper'

describe 'mongodb::automation_agent' do
  context 'Default on RHEL7' do
    let :facts do
      {
        os:              { 'family' => 'RedHat', 'release' => { 'major' => '7' } },
        operatingsystem: 'RedHat',
        osfamily:        'RedHat',
      }
    end

    let :params do
      {
        ops_manager_fqdn: 'ops-manager.mongodb.local:8080',
        mms_group_id:     'abcdefghijklmnopqrstuvwxyz',
        mms_api_key:      RSpec::Puppet::RawString.new("Sensitive('1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ')"),
        pem_file_content: RSpec::Puppet::RawString.new("Sensitive('vftybeisudvfkyj rtysaerfvacjtyDMZHfvfgty')"),
        ca_file_content:  'fueorybvurfdyubxytcibuknliu',
        pem_file_path:    '/etc/mongodb-mms/aa.pem',
        ca_file_path:     '/etc/mongodb-mms/ca.cert',
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_class('mongodb::automation_agent::install')
    }

    it {
      is_expected.to contain_class('mongodb::automation_agent::config')
    }

    it {
      is_expected.to contain_class('mongodb::automation_agent::service')
    }

    it {
      is_expected.to contain_archive('/tmp/mongodb-mms-automation-agent-manager-latest.x86_64.rhel7.rpm').with(
        'ensure'           => 'present',
        'user'             => 'root',
        'group'            => 'root',
        'creates'          => '/opt/mongodb-mms-automation/bin/mongodb-mms-automation-agent',
        'download_options' => ['--insecure'],
        'source'           => 'https://ops-manager.mongodb.local:8080/download/agent/automation/mongodb-mms-automation-agent-manager-latest.x86_64.rhel7.rpm',
      ).that_comes_before('Package[mongodb-mms-automation-agent-manager]')
    }

    it {
      is_expected.to contain_package('mongodb-mms-automation-agent-manager').with(
        'ensure'   => 'present',
        'source'   => '/tmp/mongodb-mms-automation-agent-manager-latest.x86_64.rhel7.rpm',
        'provider' => 'rpm',
      )
    }

    it {
      is_expected.to contain_file('aa_config').with(
        'ensure'  => 'file',
        'path'    => '/etc/mongodb-mms/automation-agent.config',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0600',
      )
    }

    it {
      is_expected.to contain_file_line('aa_group_id').with(
        'ensure'             => 'present',
        'path'               => '/etc/mongodb-mms/automation-agent.config',
        'match'              => '^mmsGroupId.*',
        'line'               => 'mmsGroupId=abcdefghijklmnopqrstuvwxyz',
        'append_on_no_match' => true,
      )
    }

    it {
      is_expected.to contain_file_line('aa_api_key').with(
        'ensure'             => 'present',
        'path'               => '/etc/mongodb-mms/automation-agent.config',
        'match'              => '^mmsApiKey.*',
        'line'               => 'mmsApiKey=1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'append_on_no_match' => true,
      )
    }

    it {
      is_expected.to contain_file_line('aa_om_url').with(
        'ensure'             => 'present',
        'path'               => '/etc/mongodb-mms/automation-agent.config',
        'match'              => '^mmsBaseUrl.*',
        'line'               => 'mmsBaseUrl=https://ops-manager.mongodb.local:8080',
        'append_on_no_match' => true,
      )
    }

    it {
      is_expected.to contain_service('mongodb-mms-automation-agent').with(
        'ensure'  => 'running',
        'enable'  => true,
      )
    }

    it {
      is_expected.to contain_file_line('ca_cert_file').with(
        'ensure'             => 'present',
        'path'               => '/etc/mongodb-mms/automation-agent.config',
        'match'              => '^sslTrustedMMSServerCertificate.*',
        'line'               => 'sslTrustedMMSServerCertificate=/etc/mongodb-mms/ca.cert',
        'append_on_no_match' => true,
      )
    }

    it {
      is_expected.to contain_file_line('aa_pem_file').with(
        'ensure'             => 'present',
        'path'               => '/etc/mongodb-mms/automation-agent.config',
        'match'              => '^sslMMSServerClientCertificate.*',
        'line'               => 'sslMMSServerClientCertificate=/etc/mongodb-mms/aa.pem',
        'append_on_no_match' => true,
      )
    }

    it {
      is_expected.to contain_file('aa_pem_file').with(
        'ensure'  => 'file',
        'path'    => '/etc/mongodb-mms/aa.pem',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0400',
        'content' => 'vftybeisudvfkyj rtysaerfvacjtyDMZHfvfgty',
      )
    }

    it {
      is_expected.to contain_file('aa_ca_cert_file').with(
        'ensure'  => 'file',
        'path'    => '/etc/mongodb-mms/ca.cert',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0644',
        'content' => 'fueorybvurfdyubxytcibuknliu',
      )
    }
  end

  context 'No SSL on RHEL7 with no CA cert content supplied' do
    let :facts do
      {
        os: { 'family' => 'RedHat', 'release' => { 'major' => '7' } },
      }
    end

    let :params do
      {
        ops_manager_fqdn: 'ops-manager.mongodb.local:8080',
        mms_group_id:     'abcdefghijklmnopqrstuvwxyz',
        mms_api_key:      RSpec::Puppet::RawString.new("Sensitive('1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ')"),
        enable_ssl:       false,
      }
    end

    it {
      is_expected.not_to contain_file_line('aa_ca_cert_file')
    }

    it {
      is_expected.not_to contain_file_line('aa_pem_file')
    }
  end

  context 'On RHEL7 with SSL and Kerberos selected' do
    let :facts do
      {
        os: { 'family' => 'RedHat', 'release' => { 'major' => '7' } },
      }
    end

    let :params do
      {
        ops_manager_fqdn:    'ops-manager.mongodb.local:8080',
        mms_group_id:        'abcdefghijklmnopqrstuvwxyz',
        mms_api_key:         RSpec::Puppet::RawString.new("Sensitive('1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ')"),
        keytab_file_path:    '/etc/mongodb-mms/aa_keytab',
        keytab_file_content: RSpec::Puppet::RawString.new("Sensitive('ersdtcfvyubinomguyvhjbkiougyftcghvjbiugyftghvj345')"),
        pem_file_path:       '/etc/mongodb-mms/aa.pem',
        ca_file_path:        '/etc/mongodb-mms/ca.cert',
      }
    end

    it {
      is_expected.to contain_file('aa_keytab_file').with(
        'ensure'  => 'file',
        'path'    => '/etc/mongodb-mms/aa_keytab',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0400',
        'content' => 'ersdtcfvyubinomguyvhjbkiougyftcghvjbiugyftghvj345',
      )
    }
  end
end
