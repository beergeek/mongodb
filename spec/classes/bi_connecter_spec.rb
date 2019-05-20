require 'spec_helper'

describe 'mongodb::bi_connecter' do
  context 'default on RHEL 7' do
    let :facts do
      {
        os: { 'family' => 'RedHat', 'release' => { 'major' => '7', 'minor' => '0' } },
        osfamily: 'RedHat',
        operatingsystem: 'RedHat',
        kernel: 'Linux',
      }
    end

    let(:params) do
      {
        bic_source_url: 'https://downloads.mongodb.com/bi-connector.tgz',
        bic_schema_user: 'schema_user',
        bic_schema_user_passwd: RSpec::Puppet::RawString.new("Sensitive('test')"),
        bic_sample_database: 'mflix',
        mongodb_connection_string: 'mongodb://server0:271017,server1:27017,server2:27017',
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_user('mongosql').with(
        'ensure'     => 'present',
        'gid'        => 'mongosql',
        'home'       => '/var/lib/mongosql',
        'managehome' => true,
        'system'     => true,
      )
    }

    it {
      is_expected.to contain_group('mongosql').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_file('/var/lib/mongosql').with(
        'ensure'  => 'directory',
        'owner'   => 'mongosql',
        'group'   => 'mongosql',
        'mode'    => '0750',
      )
    }

    it {
      is_expected.not_to contain_file('/var/lib/mongosql/svc.keytab')
    }

    it {
      is_expected.not_to contain_file('/var/lib/mongosql/client.keytab')
    }

    it do
      is_expected.to contain_file('/etc/mongosql.conf')
        .with(
          'ensure'  => 'file',
          'owner'   => 'mongosql',
          'group'   => 'mongosql',
          'mode'    => '0400',
        )
        .with_content(%r{.*password:.*\n})
        .with_content(%r{.*username: "schema_user"\n})
        .with_content(%r{.*mechanism: "SCRAM.*"\n})
    end

    it do
      is_expected.to contain_file('/etc/systemd/system/mongosql.service')
        .with(
          'ensure'  => 'file',
          'owner'   => 'mongosql',
          'group'   => 'mongosql',
          'mode'    => '0755',
        )
        .without_content(%r{.*Environment="KRB5_KTNAME.*\n})
        .without_content(%r{.*Environment="KRB5_CLIENT_KTNAME.*\n})
    end

    it do
      is_expected.to contain_exec('/usr/bin/systemctl daemon-reload')
        .with(
          'refreshonly' => true,
        )
        .that_subscribes_to('File[/etc/systemd/system/mongosql.service]')
        .that_notifies('Service[mongosql]')
    end

    it do
      is_expected.to contain_archive('mongosqld').with(
        'ensure'       => 'present',
        'path'         => '/tmp/bic.tgz',
        'extract'      => true,
        'extract_path' => '/usr/bin',
        'source'       => 'https://downloads.mongodb.com/bi-connector.tgz',
        'creates'      => '/usr/bin/mongosqld',
        'cleanup'      => true,
      )
    end

    it do
      is_expected.to contain_exec('install_mongosqld').with(
        'command'     => '/bin/install -m0755 /usr/bin/mongo* && /usr/bin/mongosqld -f /etc/mongosql.conf',
        'refreshonly' => true,
      ).that_subscribes_to('Archive[mongosqld]')
    end

    it do
      is_expected.to contain_service('mongosql').with(
        'ensure' => 'running',
        'enable' => true,
      ).that_subscribes_to('File[/etc/mongosql.conf]')
    end
  end

  context 'default on RHEL 7 kerberos schema user with password' do
    let :facts do
      {
        os: { 'family' => 'RedHat', 'release' => { 'major' => '7', 'minor' => '0' } },
        osfamily: 'RedHat',
        operatingsystem: 'RedHat',
        kernel: 'Linux',
      }
    end

    let(:params) do
      {
        bic_source_url: 'https://downloads.mongodb.com/bi-connector.tgz',
        bic_schema_user: 'schema_user@MONGODB.LOCAL',
        bic_schema_user_passwd: RSpec::Puppet::RawString.new("Sensitive('test')"),
        bic_schema_user_kerberos: true,
        bic_svc_kerberos: true,
        bic_sample_database: 'mflix',
        mongodb_connection_string: 'mongodb://server0:271017,server1:27017,server2:27017',
        bic_svc_keytab_content: RSpec::Puppet::RawString.new("Sensitive('svc_keytab')"),
        bic_schema_user_keytab_content: RSpec::Puppet::RawString.new("Sensitive('schema user keytab')"),
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_user('mongosql').with(
        'ensure'     => 'present',
        'gid'        => 'mongosql',
        'home'       => '/var/lib/mongosql',
        'managehome' => true,
        'system'     => true,
      )
    }

    it {
      is_expected.to contain_group('mongosql').with(
        'ensure' => 'present',
      )
    }

    it {
      is_expected.to contain_file('/var/lib/mongosql').with(
        'ensure'  => 'directory',
        'owner'   => 'mongosql',
        'group'   => 'mongosql',
        'mode'    => '0750',
      )
    }

    it {
      is_expected.to contain_file('/var/lib/mongosql/svc.keytab').with(
        'ensure'  => 'file',
        'owner'   => 'mongosql',
        'group'   => 'mongosql',
        'mode'    => '0400',
      )
    }

    it {
      is_expected.to contain_file('/var/lib/mongosql/client.keytab').with(
        'ensure'  => 'file',
        'owner'   => 'mongosql',
        'group'   => 'mongosql',
        'mode'    => '0400',
      )
    }

    it do
      is_expected.to contain_file('/etc/mongosql.conf')
        .with(
          'ensure'  => 'file',
          'owner'   => 'mongosql',
          'group'   => 'mongosql',
          'mode'    => '0400',
        )
        .with_content(%r{.*password:.*\n})
        .with_content(%r{.*username: "schema_user@MONGODB.LOCAL"\n})
        .with_content(%r{.*mechanism: "GSSAPI.*\n})
    end

    it do
      is_expected.to contain_file('/etc/systemd/system/mongosql.service')
        .with(
          'ensure'  => 'file',
          'owner'   => 'mongosql',
          'group'   => 'mongosql',
          'mode'    => '0755',
        )
        .with_content(%r{.*Environment="KRB5_KTNAME=.*\n})
        .with_content(%r{.*Environment="KRB5_CLIENT_KTNAME=.*\n})
    end

    it do
      is_expected.to contain_exec('/usr/bin/systemctl daemon-reload')
        .with(
          'refreshonly' => true,
        )
        .that_subscribes_to('File[/etc/systemd/system/mongosql.service]')
        .that_notifies('Service[mongosql]')
    end

    it do
      is_expected.to contain_archive('mongosqld').with(
        'ensure'       => 'present',
        'path'         => '/tmp/bic.tgz',
        'extract'      => true,
        'extract_path' => '/usr/bin',
        'source'       => 'https://downloads.mongodb.com/bi-connector.tgz',
        'creates'      => '/usr/bin/mongosqld',
        'cleanup'      => true,
      )
    end

    it do
      is_expected.to contain_exec('install_mongosqld').with(
        'command'     => '/bin/install -m0755 /usr/bin/mongo* && /usr/bin/mongosqld -f /etc/mongosql.conf',
        'refreshonly' => true,
      ).that_subscribes_to('Archive[mongosqld]')
    end

    it do
      is_expected.to contain_service('mongosql').with(
        'ensure' => 'running',
        'enable' => true,
      ).that_subscribes_to('File[/etc/mongosql.conf]')
    end
  end
end
