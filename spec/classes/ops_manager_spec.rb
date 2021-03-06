require 'spec_helper'

describe 'mongodb::ops_manager' do
  context 'SSL on RHEL 7' do
    let :facts do
      {
        os:              { 'family' => 'RedHat', 'release' => { 'major' => '7', 'minor' => '0' } },
        osfamily:        'RedHat',
        operatingsystem: 'RedHat',
        kernel:          'Linux',
      }
    end

    let :params do
      {
        ca_cert_path:         '/etc/mongodb-mms/ca.cert',
        pem_file_path:        '/etc/mongodb-mms/om.pem',
        mms_source:           'https://downloads.mongodb.local/mongodb-mms-latest.rpm',
        pem_file_content:     RSpec::Puppet::RawString.new("Sensitive('vftybeisudvfkyj rtysaerfvacjtyDMZHfvfgty')"),
        central_url:          'https://ops-manager.mongodb.local:8443',
        gen_key_file_content: 'O5jXGG0M7SmoXUJObZ/zSsqtis41JTDU',
        appsdb_uri:           'mongodb://sdfghjkl:dfcvgbhjk@mongod0.mongodb.local:27017,mongod1.mongodb.local:27017,mongod2.mongodb.local:27017',
        email_hostname:       'emailer.mongodb.local',
        admin_email_addr:     'admin@mongodb.local',
        from_email_addr:      'om@mongodb.local',
        reply_email_addr:     'om@mongodb.local',
      }
    end

    it {
      is_expected.to contain_user('mongodb-mms').with(
        'ensure'     => 'present',
        'gid'        => 'mongodb-mms',
        'home'       => '/home/mongodb',
        'managehome' => true,
      )
    }

    it {
      is_expected.to contain_group('mongodb-mms').with(
        'ensure'     => 'present',
      )
    }

    it {
      is_expected.to contain_package('mongodb_mms_pkg').with(
        'ensure'   => 'latest',
        'source'   => 'https://downloads.mongodb.local/mongodb-mms-latest.rpm',
        'provider' => 'rpm',
      )
    }

    it {
      is_expected.to contain_file('mms_config_file').with(
        'ensure'  => 'file',
        'path'    => '/opt/mongodb/mms/conf/conf-mms.properties',
        'owner'   => 'mongodb-mms',
        'group'   => 'mongodb-mms',
        'mode'    => '0644',
      ).that_requires('Package[mongodb_mms_pkg]')
    }

    it {
      is_expected.to contain_file('gen_key_file').with(
        'ensure'  => 'file',
        'path'    => '/etc/mongodb-mms/gen.key',
        'owner'   => 'mongodb-mms',
        'group'   => 'mongodb-mms',
        'mode'    => '0400',
      ).that_requires('Package[mongodb_mms_pkg]')
    }

    it {
      is_expected.to contain_file('/etc/security/limits.d/99-mongodb-mms.conf').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'source'  => 'puppet:///modules/mongodb/99-mongodb-mms.conf',
      ).that_notifies('Service[mongodb-mms]')
    }

    it {
      is_expected.to contain_service('mongodb-mms').with(
        'ensure' => 'running',
        'enable' => true,
      ).that_subscribes_to('File[mms_config_file]').that_subscribes_to('File[gen_key_file]')
    }

    it {
      is_expected.not_to contain_service('mongodb-mms-backup-daemon')
    }
  end

  context 'disabling mms service and enableing backup daemon on RHEL 7' do
    let :facts do
      {
        os:              { 'family' => 'RedHat', 'release' => { 'major' => '7', 'minor' => '0' } },
        osfamily:        'RedHat',
        operatingsystem: 'RedHat',
        kernel:          'Linux',
      }
    end

    let :params do
      {
        enable_http_service:  false,
        enable_backup_daemon: true,
        ca_cert_path:         '/etc/mongodb-mms/ca.cert',
        pem_file_path:        '/etc/mongodb-mms/om.pem',
        mms_source:           'https://downloads.mongodb.local/mongodb-mms-latest.rpm',
        pem_file_content:     RSpec::Puppet::RawString.new("Sensitive('vftybeisudvfkyj rtysaerfvacjtyDMZHfvfgty')"),
        central_url:          'https://ops-manager.mongodb.local:8443',
        gen_key_file_content: 'O5jXGG0M7SmoXUJObZ/zSsqtis41JTDU',
        appsdb_uri:           'mongodb://sdfghjkl:dfcvgbhjk@mongod0.mongodb.local:27017,mongod1.mongodb.local:27017,mongod2.mongodb.local:27017',
        email_hostname:       'emailer.mongodb.local',
        admin_email_addr:     'admin@mongodb.local',
        from_email_addr:      'om@mongodb.local',
        reply_email_addr:     'om@mongodb.local',
      }
    end

    it {
      is_expected.to contain_service('mongodb-mms').with(
        'ensure' => 'stopped',
        'enable' => false,
      ).that_subscribes_to('File[mms_config_file]').that_subscribes_to('File[gen_key_file]')
    }

    it {
      is_expected.to contain_service('mongodb-mms-backup-daemon').with(
        'ensure' => 'running',
        'enable' => true,
      ).that_subscribes_to('File[mms_config_file]').that_subscribes_to('File[gen_key_file]')
    }
  end
end
