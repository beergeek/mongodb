require 'spec_helper'

describe 'mongodb::supporting' do
  context 'on RedHat 7' do
    let :facts do
      {
        os: { 'family' => 'RedHat', 'release' => { 'major' => '7' } },
      }
    end

    it { is_expected.to compile }
  end

  context 'on RedHat 7 with content' do
    let :facts do
      {
        os:         { 'family' => 'RedHat', 'release' => { 'major' => '7' } },
        networking: { 'fqdn' => 'mongod0.mongodb.local' },
      }
    end
    let :params do
      {
        cluster_auth_pem_content: RSpec::Puppet::RawString.new("Sensitive('tvydcu=@#$%^&*(hsvghGHVG1')"),
        pem_file_content:         RSpec::Puppet::RawString.new("Sensitive('tvydcu=@#$%^&*(hsvghGHVGq')"),
        ca_cert_pem_content:      'tvydcu=@#$%^&*(hsvghGHVGa',
        server_keytab_content:    RSpec::Puppet::RawString.new("Sensitive('tvydcu=@#$%^&*(hsvghGHVGz')"),
        keyfile_content:          RSpec::Puppet::RawString.new("Sensitive('tvydcu=@#$%^&*(hsvghGHVGs')"),
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('/data/pki/cluser_auth.pem').with(
        'ensure'  => 'file',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0400',
      )
    }

    it {
      is_expected.not_to contain_acl('C:\data\pki\cluser_auth.pem')
    }

    it {
      is_expected.to contain_file('/data/pki/mongod0.mongodb.local.pem').with(
        'ensure'  => 'file',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0400',
      )
    }

    it {
      is_expected.not_to contain_acl('C:\data\pki\mongod0.mongodb.local.pem')
    }

    it {
      is_expected.to contain_file('/data/pki/ca.cert').with(
        'ensure'  => 'file',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0644',
      )
    }

    it {
      is_expected.not_to contain_acl('C:\data\pki\ca.cert')
    }

    it {
      is_expected.to contain_file('/data/pki/svc_keytab').with(
        'ensure'  => 'file',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0400',
      )
    }

    it {
      is_expected.to contain_file('/data/pki/mongodb_keyfile').with(
        'ensure'  => 'file',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0400',
      )
    }

    it {
      is_expected.not_to contain_acl('C:\data\pki\mongodb_keyfile')
    }
  end

  context 'on Windows with content' do
    let :facts do
      {
        os:         { 'family' => 'windows', 'release' => { 'major' => '2016' } },
        networking: { 'fqdn' => 'mongod0.mongodb.local' },
      }
    end
    let :params do
      {
        cluster_auth_pem_content: RSpec::Puppet::RawString.new("Sensitive('tvydcu=@#$%^&*(hsvghGHVG1')"),
        pem_file_content:         RSpec::Puppet::RawString.new("Sensitive('tvydcu=@#$%^&*(hsvghGHVGq')"),
        ca_cert_pem_content:      'tvydcu=@#$%^&*(hsvghGHVGa',
        keyfile_content:          RSpec::Puppet::RawString.new("Sensitive('tvydcu=@#$%^&*(hsvghGHVGs')"),
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('C:\data\pki\cluser_auth.pem').with(
        'ensure'  => 'file',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0400',
      )
    }

    it {
      is_expected.to contain_acl('C:\data\pki\cluser_auth.pem').with(
        'purge'                      => false,
        'permissions'                => '[{"identity"=>"mongod", "rights"=>["full"], "perm_type"=>"allow", "child_types"=>"all", "affects"=>"all"}]',
        'owner'                      => 'mongod',
        'group'                      => 'mongod',
        'inherit_parent_permissions' => false,
      )
    }

    it {
      is_expected.to contain_file('C:\data\pki\mongod0.mongodb.local.pem').with(
        'ensure'  => 'file',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0400',
      )
    }

    it {
      is_expected.to contain_acl('C:\data\pki\mongod0.mongodb.local.pem').with(
        'purge'                      => false,
        'permissions'                => '[{"identity"=>"mongod", "rights"=>["full"], "perm_type"=>"allow", "child_types"=>"all", "affects"=>"all"}]',
        'owner'                      => 'mongod',
        'group'                      => 'mongod',
        'inherit_parent_permissions' => false,
      )
    }

    it {
      is_expected.to contain_file('C:\data\pki\ca.cert').with(
        'ensure'  => 'file',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0644',
      )
    }

    it {
      is_expected.to contain_acl('C:\data\pki\ca.cert').with(
        'purge'                      => false,
        'permissions'                => '[{"identity"=>"mongod", "rights"=>["full"], "perm_type"=>"allow", "child_types"=>"all", "affects"=>"all"}]',
        'owner'                      => 'mongod',
        'group'                      => 'mongod',
        'inherit_parent_permissions' => true,
      )
    }

    it {
      is_expected.not_to contain_file('C:\data\pki\svc_keytab').with(
        'ensure'  => 'file',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0400',
      )
    }

    it {
      is_expected.to contain_file('C:\data\pki\mongodb_keyfile').with(
        'ensure'  => 'file',
        'owner'   => 'mongod',
        'group'   => 'mongod',
        'mode'    => '0400',
      )
    }

    it {
      is_expected.to contain_acl('C:\data\pki\mongodb_keyfile').with(
        'purge'                      => false,
        'permissions'                => '[{"identity"=>"mongod", "rights"=>["full"], "perm_type"=>"allow", "child_types"=>"all", "affects"=>"all"}]',
        'owner'                      => 'mongod',
        'group'                      => 'mongod',
        'inherit_parent_permissions' => false,
      )
    }
  end
end
