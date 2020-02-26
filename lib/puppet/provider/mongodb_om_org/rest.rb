require File.join(File.dirname(__FILE__), '../mongodb_om')
require 'json'

Puppet::Type.type(:mongodb_om_org).provide(:rest, parent: Puppet::Provider::Mongodb_om) do

  def self.instances
    instances = []
    orgs = Puppet::Provider::Mongodb_om.call_items('/api/public/v1.0/orgs')
    Puppet.debug "Data: #{orgs}"
    return [] if orgs.nil?

    orgs['results'].each do |org|
      ldap_owners = nil
      ldap_member = nil
      ldap_readonly = nil
      if !org['ldapGroupMappings'].empty?
        org['ldapGroupMappings'].each do |ldap_hash|
          case roleName
          when 'ORG_OWNER'
            ldap_owners = ldap_hash['ldapGroups']
          when 'ORG_MEMBER'
            ldap_member = ldap_hash['ldapGroups']
          when 'ORG_READ_ONLY'
            ldap_readonly = ldap_hash['ldapGroups']
          end
        end
      end

      instances << new(
        ensure:              :present,
        name:                org['name'],
        id:                  org['id'],
        ldap_owner_group:   ldap_owners,
        ldap_member_group:  ldap_member,
        ldap_read_only:     ldap_readonly,
      )
    end

    instances
  end

  def self.prefetch(resources)
    orgs = instances
    resources.keys.each do |name|
      if provider = orgs.find { |org| org.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::Mongodb_om.post("/api/public/v1.0/orgs", {'name' => resource.name}.to_json)

    return result
  end

  def destroy
    result = Puppet::Provider::Mongodb_om.delete("/api/public/v1.0/orgs/#{resource[:id]}")

    return result
  end

  mk_resource_methods

end