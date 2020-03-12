Puppet::Type.newtype(:mongodb_om_db_role) do
  @doc = 'Manages roles for database deployments within an Ops Manager Project'

  apply_to_device
  ensurable

  newparam(:name) do
    desc 'The name of the Project'

    validate do |value|
      raise ArgumentError, "#{name} must be a String" unless value.is_a?(String)
    end

    isnamevar
  end

  newproperty(:project_id) do
    desc 'The Projest ID that the Role will belong to. Set only once and cannot be modified'

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

  newproperty(:passwd) do
    desc 'The password of the User.'

    validate do |value|
      raise ArgumentError, "The value for `db` must be a String, not a #{value.class}" unless value.is_a?(String)
    end
  end

  newproperty(:privileges, :array_matching => :all) do
    desc 'An array of hashes containing `actions` and `resource`. `actions` is an array.'

    validate do |value|
      raise ArgumentError, 'Each hash within the `privileges` array must contain the key `resource`' if value['resource'].nil?
      raise ArgumentError, 'Each hash within the `privileges` array must contain the key `actions`' if value['actions'].nil?
    end
  end

  newproperty(:roles, :array_matching => :all) do
    desc 'An array of roles to inherit from. Each role is a hash containing `db` and `role`.'

    validate do |value|
      raise ArgumentError, 'Each hash within the `roles` array must contain the key `db`' if value['db'].nil?
      raise ArgumentError, 'Each hash within the `roles` array must contain the key `role`' if value['role'].nil?
    end

    defaultto []
  end
end
