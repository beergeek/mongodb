require File.join(File.dirname(__FILE__), '../mongodb_om')
require 'json'

Puppet::Type.type(:mongodb_om_proj).provide(:rest, parent: Puppet::Provider::Mongodb_om) do

  def self.instances
    instances = []
    projs = Puppet::Provider::Mongodb_om.call_items('/api/public/v1.0/groups')
    Puppet.debug "Data: #{projs}"
    return [] if projs.nil?

    projs['results'].each do |proj|
      ldap_owners = nil
      ldap_member = nil
      ldap_readonly = nil
      if !proj['ldapGroupMappings'].empty?
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
        ensure:              :present,
        name:                proj['name'],
        id:                  proj['id'],
        ldap_owner_group:   ldap_owners,
        ldap_member_group:  ldap_member,
        ldap_read_only:     ldap_readonly,
      )
    end

    instances
  end

  def self.prefetch(resources)
    projs = instances
    resources.keys.each do |name|
      if provider = projs.find { |proj| proj.name == name }
        resources[name].provider = provider
        resources[name].id = name[:id]
      end
    end
  end

  def make_ldap_array(data_body)
    ldap_array = []

    if data_body.has_key?(:ldap_owner_group)
      ldap_array << {'ldapGroups' => data_body[:ldap_owner_group], 'roleName' => 'GROUP_OWNER'}
      data_body.delete(:ldap_owner_group)
    end
    if data_body.has_key?(:ldap_member_group)
      ldap_array << {'ldapGroups' => data_body[:ldap_member_group], 'roleName' => 'GROUP_MEMBER'}
      data_body.delete(:ldap_member_group)
    end
    if data_body.has_key?(:ldap_read_only)
      ldap_array << {'ldapGroups' => data_body[:ldap_read_only], 'roleName' => 'GROUP_READ_ONLY'}
      data_body.delete(:ldap_read_only)
    end
    data_body['ldapGroupMappings'] = ldap_array

    return data_body
  end

  def clean_hash(unclean_hash)
    unclean_hash[:orgId] = unclean_hash[:org_id]
    unclean_hash.delete(:org_id)
    unclean_hash.delete(:provider)
    unclean_hash.delete(:loglevel)
    unclean_hash.delete(:ensure)
    return unclean_hash
  end


  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    cleaned_hash = clean_hash(resource.to_hash)
    result = Puppet::Provider::Mongodb_om.post("/api/public/v1.0/groups", make_ldap_array(cleaned_hash).to_json)

    return result
  end

  def destroy
    # need to get the ID of the Project before we can delete!
    result = Puppet::Provider::Mongodb_om.delete("/api/public/v1.0/groups/#{@property_hash[:id]}")

    return result
  end

  mk_resource_methods

end