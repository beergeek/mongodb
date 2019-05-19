require 'spec_helper'

describe 'mongodb::supporting' do
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
