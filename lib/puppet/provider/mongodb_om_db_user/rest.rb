require File.join(File.dirname(__FILE__), '../mongodb_om')
require 'json'

Puppet::Type.type(:mongodb_om_db_user).provide(:rest, parent: Puppet::Provider::Mongodb_om) do

  def self.instances
    instances = []
    projs = Puppet::Provider::Mongodb_om.call_items('/api/public/v1.0/groups')
    Puppet.debug "Data: #{projs}"
    return [] if projs.nil?

    projs['results'].each do |proj|
      Puppet.debug "Data: #{proj}"
      proj_settings = Puppet::Provider::Mongodb_om.call_items("/api/public/v1.0/groups/#{proj['id']}/automationConfig")

      proj_settings['auth']['usersWanted'].each do |user|

        instances << new(
          ensure:                      :present,
          name:                        user['user'] + '@' + proj['id'],
          username:                    user['user'],
          project_id:                  proj['id'],
          authentication_restrictions: user['authenticationRestrictions'],
          db:                          user['db'],
          roles:                       user['roles'],
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
    raise ArgumentError, 'The `project_id` must exist' if resource[:project_id].nil?
    # make config
    new_user = {
      'user'                       => resource[:username],
      'authenticationRestrictions' => resource[:authentication_restrictions],
      'db'                         => resource[:db],
      'roles'                      => resource[:roles],
      'initPwd'                    => resource[:initial_passwd],
    }
    # current project data so we can merge
    current_config = Puppet::Provider::Mongodb_om.get("/api/public/v1.0/groups/#{resource[:project_id]}/automationConfig")
    # make the config for the project
    update_payload = JSON.parse(current_config.body)
    update_payload['auth']['usersWanted'] << new_user
    config_result = Puppet::Provider::Mongodb_om.put("/api/public/v1.0/groups/#{resource[:project_id]}/automationConfig", update_payload.to_json)
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    config_result
  end

  def flush
    if @property_hash != {}
      updated_user = {
        'authenticationRestrictions' => resource[:authentication_restrictions],
        'db'                         => resource[:db],
        'roles'                      => resource[:roles],
      }
      # current project data so we can merge
      current_config = Puppet::Provider::Mongodb_om.get("/api/public/v1.0/groups/#{resource[:project_id]}/automationConfig")
      # make the config for the project
      update_payload = JSON.parse(current_config.body)
      update_payload['auth']['usersWanted'].each_with_index do |value, index|
        if value['user'] == resource[:username]
          update_payload['auth']['usersWanted'][index].merge!(updated_user)
        end
      end
      config_result = Puppet::Provider::Mongodb_om.put("/api/public/v1.0/groups/#{resource[:project_id]}/automationConfig", update_payload.to_json)

      config_result
    end
  end

  def destroy
    # current project data so we can merge
    current_config = Puppet::Provider::Mongodb_om.get("/api/public/v1.0/groups/#{resource[:project_id]}/automationConfig")
    update_payload = JSON.parse(current_config.body)
    update_payload['auth']['usersWanted'] = update_payload['auth']['usersWanted'].delete_if { |user| user['name'] == resource[:username] }
    # need to get the ID of the Project before we can delete!
    result = Puppet::Provider::Mongodb_om.put("/api/public/v1.0/groups/#{resource[:project_id]}/automationConfig", update_payload.to_json)
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    result
  end

  mk_resource_methods
end
