Puppet::Type.newtype(:mongodb_om_db_user) do
  @doc = "Manages users for MongoDB databases managed by Ops Manager
   The title of the resource is the combination of the username and the Project ID (24 characters) joined by a `@` symbol, such as:

   mongodb_om_db_user { 'brett@5e439798e976cc5e50a7b165':
    ensure => present,
    ...
   }
  
   Alternatively any name can be provided as long as the `username` and `project_id` parameters are set.
  
  "

  apply_to_device
  ensurable

  newparam(:name) do
    desc 'The name of the User and Project ID separated by an `@`. e.g. `dba003@5e439798e976cc5e50a7b165'

    validate do |value|
      raise ArgumentError, "#{name} must be a String" unless value.is_a?(String)
      raise ArgumentError, "Format must be <USERNAME>@<PROJECT ID>, not #{value}. The Project ID is 24 characters long and only contains hexidemical characters (lowercase)." unless value.match(/[0-9a-f){24}]/)
      resource[:project_id] = value[/.*@([0-9a-f]{24}$)/, 1]
      resource[:username] = value[/^(.*)@.*/, 1]
    end

    isnamevar
  end

  newproperty(:username) do
    desc 'The User name, defaults to the first porition of the resource title. Set only once and cannot be modified'

    validate do |value|
      raise ArgumentError, "#{value} must be a String" unless value.is_a?(String)
    end
  end

  newproperty(:project_id) do
    desc 'The Projest ID that the User will belong to. Set only once and cannot be modified'

    validate do |value|
      raise ArgumentError, "#{value} must be a String" unless value.is_a?(String)
    end
  end

  newproperty(:authentication_restrictions, :array_matching => :all) do
    desc 'An array of authentication restrictions.'

    defaultto []
  end

  newproperty(:db) do
    desc 'The database to use for authentication. Default is `admin`.'

    validate do |value|
      raise ArgumentError, "The value for `db` must be a String, not a #{value.class}" unless value.is_a?(String)
    end

    defaultto 'admin'
  end

  newproperty(:roles, :array_matching => :all) do
    desc 'An array of roles to inherit from. Each role is a hash containing `db` and `role`.'

    validate do |value|
      raise ArgumentError, 'Each hash within the `roles` array must contain the key `db`' if value['db'].nil?
      raise ArgumentError, 'Each hash within the `roles` array must contain the key `role`' if value['role'].nil?
    end

    defaultto []
  end

  newproperty(:initial_passwd) do
    desc 'The initial cleartext password of the User'

    validate do |value|
      raise ArgumentError, "The value for `db` must be a String, not a #{value.class}" unless value.is_a?(String)
    end
  end
end
