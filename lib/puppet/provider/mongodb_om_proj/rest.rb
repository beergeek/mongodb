require File.join(File.dirname(__FILE__), '../mongodb_om')
require 'json'
require 'securerandom'

Puppet::Type.type(:mongodb_om_proj).provide(:rest, parent: Puppet::Provider::Mongodb_om) do

  def self.instances
    instances = []
    projs = Puppet::Provider::Mongodb_om.call_items('/api/public/v1.0/groups')
    Puppet.debug "Data: #{projs}"
    return [] if projs.nil?

    projs['results'].each do |proj|
      proj_settings = Puppet::Provider::Mongodb_om.call_items("/api/public/v1.0/groups/#{proj['id']}/automationConfig")
      ldap_owners = nil
      ldap_member = nil
      ldap_readonly = nil
      unless proj['ldapGroupMappings'].empty?
        proj['ldapGroupMappings'].each do |ldap_hash|
          case ldap_hash['roleName']
          when 'GROUP_OWNER'
            ldap_owners = ldap_hash['ldapGroups']
          when 'GROUP_MEMBER'
            ldap_member = ldap_hash['ldapGroups']
          when 'GROUP_READ_ONLY'
            ldap_readonly = ldap_hash['ldapGroups']
          end
        end
      end

      instances << new(
        ensure:                :present,
        name:                  proj['name'] + '@' + proj['orgId'],
        id:                    proj['id'],
        projname:              proj['name'],
        ldap_owner_group:      ldap_owners,
        ldap_member_group:     ldap_member,
        ldap_read_only:        ldap_readonly,
        org_id:                proj['orgId'],
        aa_auth_mech:          proj_settings['auth']['autoAuthMechanism'],
        aa_auth_mechs:         proj_settings['auth']['autoAuthMechanisms'],
        deployment_auth_mechs: proj_settings['auth']['deploymentAuthMechanisms'],
        krb5_svc_name:         proj_settings['kerberos']['serviceName'],
        tls_ca_cert_path:      proj_settings['ssl']['CAFilePath'],
        aa_pem_path:           proj_settings['ssl']['autoPEMKeyFilePath'],
        tls_client_cert_mode:  proj_settings['ssl']['clientCertificateMode'],
      )
    end

    instances
  end

  def self.prefetch(resources)
    projs = instances
    resources.keys.each do |name|
      if provider = projs.find { |proj| proj.name == name }
        resources[name].provider = provider
      end
    end
  end

  def make_ldap_array(data_body)
    ldap_array = []

    if data_body.key?(:ldap_owner_group)
      ldap_array << { 'ldapGroups' => data_body[:ldap_owner_group], 'roleName' => 'GROUP_OWNER' }
    end
    if data_body.key?(:ldap_member_group)
      ldap_array << { 'ldapGroups' => data_body[:ldap_member_group], 'roleName' => 'GROUP_MEMBER' }
    end
    if data_body.key?(:ldap_read_only)
      ldap_array << { 'ldapGroups' => data_body[:ldap_read_only], 'roleName' => 'GROUP_READ_ONLY' }
    end

    ldap_array
  end

  def make_tls(data_body)
    if data_body.key?(:tls_enabled)
      ssl = {
        'CAFilePath'            => data_body[:tls_ca_cert_path],
        'autoPEMKeyFilePath'    => data_body[:aa_pem_path],
        'clientCertificateMode' => data_body[:tls_client_cert_mode],
      }
      ssl
    end
  end

  def users_wanted(data_body)
    if resource[:aa_auth_mech] == 'GSSAPI'
      db = '$external'
      passwd = ''
    else
      db = 'admin'
      passwd = SecureRandom.hex(16)
    end
    aa_users = [
      {
        'authenticationRestrictions' => [],
        'db'                         => db,
        'initPwd'                    => passwd,
        'roles' => [{
          'db'   => 'admin',
          'role' => 'clusterMonitor',
        }],
        'user' => 'mms-monitoring-agent',
      }, {
        'authenticationRestrictions' => [],
        'db'                         => 'admin',
        'initPwd'                    => SecureRandom.hex(16),
        'roles'                      => [{
          'db'   => 'admin',
          'role' => 'clusterAdmin',
        }, {
          'db'   => 'admin',
          'role' => 'readAnyDatabase',
        }, {
          'db'   => 'admin',
          'role' => 'userAdminAnyDatabase',
        }, {
          'db'   => 'local',
          'role' => 'readWrite',
        }, {
          'db'   => 'admin',
          'role' => 'readWrite',
        }],
        'user'                        => 'mms-backup-agent',
      }
    ]
    aa_users
  end

  def make_auth(data_body)
    auth = {
      'authoritativeSet'         => false,
      'autoAuthMechanism'        => data_body[:aa_auth_mech],
      'autoAuthMechanisms'       => data_body[:aa_auth_mechs],
      'autoKerberosKeytabPath'   => '/data/pki/server.keytab',
      'autoAuthRestrictions'     => [],
      'autoLdapGroupDN'          => '',
      'autoPwd'                  => SecureRandom.hex(16),
      'autoUser'                 => 'mms-automation',
      'deploymentAuthMechanisms' => data_body[:deployment_auth_mechs],
      'disabled'                 => false,
      'key'                      => SecureRandom.hex(512),
      'keyfile'                  => '/var/lib/mongodb-mms-automation/keyfile',
      'keyfileWindows'           => '%SystemDrive%\\MMSAutomation\\versions\\keyfile',
      'usersDeleted'             => [],
      'usersWanted'              => users_wanted(data_body),
    }
    auth
  end

  def make_krb5(data_body)
    kerberos = {
      'serviceName' => data_body[:krb5_svc_name],
    }
    kerberos
  end

  def make_proj(data_body)
    proj_payload = {
      'name'              => data_body[:name],
      'ldapGroupMappings' => make_ldap_array(data_body),
      'orgId'             => data_body[:org_id],
    }
    proj_payload
  end

  def update_auth(data_body)
    auth = {
      'authoritativeSet'         => false,
      'autoAuthMechanism'        => resource[:aa_auth_mech],
      'autoAuthMechanisms'       => resource[:aa_auth_mechs],
      'autoKerberosKeytabPath'   => '/data/pki/server.keytab',
      'autoAuthRestrictions'     => [],
      'autoLdapGroupDN'          => '',
      'autoPwd'                  => data_body['auth']['autoPwd'],
      'autoUser'                 => 'mms-automation',
      'deploymentAuthMechanisms' => resource[:deployment_auth_mechs],
      'disabled'                 => false,
      'key'                      => data_body['auth']['key'],
      'keyfile'                  => '/var/lib/mongodb-mms-automation/keyfile',
      'keyfileWindows'           => '%SystemDrive%\\MMSAutomation\\versions\\keyfile',
      'usersDeleted'             => [],
      'usersWanted'              => data_body['auth']['usersWanted'], # FIX THIS!
    }
    auth
  end

  def update_krb5()
    kerberos = {
      'serviceName' => resource[:krb5_svc_name],
    }
    kerberos
  end

  def update_tls()
    if resource[:tls_enabled]
      ssl = {
        'CAFilePath'            => resource[:tls_ca_cert_path],
        'autoPEMKeyFilePath'    => resource[:aa_pem_path],
        'clientCertificateMode' => resource[:tls_client_cert_mode],
      }
    else
      ssl = {}
    end
  end

  def config_proj(data_body)
    proj_payload = {
      'auth'              => make_auth(data_body),
      'kerberos'          => make_krb5(data_body),
      'ssl'               => make_tls(data_body),
    }
    proj_payload
  end

  def update_proj(data_body)
    data_body['auth']     = update_auth(data_body)
    data_body['kerberos'] = update_krb5()
    data_body['ssl']      = update_tls()
    data_body
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    raise ArgumentError, 'The `org_id` must exist' if @resource[:org_id].nil?
    # create the project
    proj_data = make_proj(resource.to_hash)
    result = Puppet::Provider::Mongodb_om.post('/api/public/v1.0/groups', proj_data.to_json)
    id = JSON.parse(result.body)['id']
    payload = config_proj(resource.to_hash)
    Puppet::Provider::Mongodb_om.put("/api/public/v1.0/groups/#{id}/automationConfig", payload.to_json)
  end

  def flush
    if @property_hash != {}
      # current project data so we can merge
      current_config = Puppet::Provider::Mongodb_om.get("/api/public/v1.0/groups/#{@property_hash[:id]}/automationConfig")
      # make the config for the project
      new_config = update_proj(JSON.parse(current_config.body))
      # make the config for the project
      config_result = Puppet::Provider::Mongodb_om.put("/api/public/v1.0/groups/#{@property_hash[:id]}/automationConfig", new_config.to_json)

      config_result
    end
  end

  def destroy
    # need to get the ID of the Project before we can delete!
    Puppet::Provider::Mongodb_om.delete("/api/public/v1.0/groups/#{@property_hash[:id]}")
  end

  mk_resource_methods
end
