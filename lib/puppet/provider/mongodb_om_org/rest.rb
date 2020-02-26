require File.join(File.dirname(__FILE__), '../mongodb_om')
require 'json'

Puppet::Type.type(:mongodb_om_org).provide(:rest, parent: Puppet::Provider::Mongodb_om) do

  def self.instances
    instances = []
    orgs = Puppet::Provider::Mongodb_om.call_items('/api/public/v1.0/orgs')
    Puppet.info "Data: #{orgs}"
    return [] if orgs.nil?

    orgs['results'].each do |org|
      Puppet.info org

      instances << new(
        ensure:          :present,
        name:            org['name'],
        id:              org['id'],
      )
    end

    instances
  end

  def self.prefetch(resources)
    orgs = instances
    Puppet.info instances
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
    result = Puppet::Provider::Mongodb_om.post("/api/public/v1.0/org", resource)

    return result
  end

  def destroy
    result = Puppet::Provider::Mongodb_om.delete("/api/public/v1.0/org/#{resource[:id]}")

    return result
  end

  mk_resource_methods

end