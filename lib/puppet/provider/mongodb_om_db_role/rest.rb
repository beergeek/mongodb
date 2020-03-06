require File.join(File.dirname(__FILE__), '../mongodb_om')
require 'json'

Puppet::Type.type(:mongodb_om_db_role).provide(:rest, parent: Puppet::Provider::Mongodb_om) do

  def self.instances
    instances = []
    projs = Puppet::Provider::Mongodb_om.call_items('/api/public/v1.0/groups')
    Puppet.debug "Data: #{projs}"
    return [] if projs.nil?

    projs['results'].each do |proj|
      Puppet.debug "Data: #{proj}"
      proj_settings = Puppet::Provider::Mongodb_om.call_items("/api/public/v1.0/groups/#{proj['id']}/automationConfig")

      proj_settings['roles'].each do |role|

        instances << new(
          ensure:                      :present,
          name:                        role['role'],
          project_id:                  proj['id'],
          authentication_restrictions: role['authenticationRestrictions'],
          db:                          role['db'],
          privileges:                  role['privileges'],
          roles:                       role['roles'],
        )
      end
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

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    fail ArgumentError, "The `project_id` must exist" if resource[:project_id].nil?
    fail ArgumentError, "The `project_id` must exist" if (resource[:privileges].nil? or resource[:privileges].length == 0)
    # make config
    new_role = {
      'role'                       => resource[:name],
      'authenticationRestrictions' => resource[:authentication_restrictions],
      'db'                         => resource[:db],
      'privileges'                 => resource[:privileges],
      'roles'                      => resource[:roles],
    }
    # current project data so we can merge
    current_config = Puppet::Provider::Mongodb_om.get("/api/public/v1.0/groups/#{resource[:project_id]}/automationConfig")
    # make the config for the project
    update_payload = JSON.parse(current_config.body)
    update_payload['roles'] << new_role
    config_result = Puppet::Provider::Mongodb_om.put("/api/public/v1.0/groups/#{resource[:project_id]}/automationConfig", update_payload.to_json)
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return config_result
  end

  def flush
    if @property_hash != {}
      updated_role = {
        'role'                       => @property_hash[:name],
        'authenticationRestrictions' => @property_hash[:authentication_restrictions],
        'db'                         => @property_hash[:db],
        'privileges'                 => @property_hash[:privileges],
        'roles'                      => @property_hash[:roles],
      }
      # current project data so we can merge
      current_config = Puppet::Provider::Mongodb_om.get("/api/public/v1.0/groups/#{resource[:project_id]}/automationConfig")
      # make the config for the project
      update_payload = JSON.parse(current_config.body).merge({'roles' => [updated_role]})
      config_result = Puppet::Provider::Mongodb_om.put("/api/public/v1.0/groups/#{resource[:project_id]}/automationConfig", update_payload.to_json)

      return config_result
    end
  end

  def destroy
    # current project data so we can merge
    current_config = Puppet::Provider::Mongodb_om.get("/api/public/v1.0/groups/#{resource[:project_id]}/automationConfig")
    update_payload = JSON.parse(current_config.body)
    update_payload['roles'] = update_payload['roles'].delete_if {|role| role['role'] == resource[:name]}
    # need to get the ID of the Project before we can delete!
    result = Puppet::Provider::Mongodb_om.put("/api/public/v1.0/groups/#{resource[:project_id]}/automationConfig", update_payload.to_json)
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  mk_resource_methods

end