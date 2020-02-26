Puppet::Type.newtype(:mongodb_om_org) do
  @doc = 'Manages users for MongoDB databases managed by Ops Manager'

  apply_to_device
  ensurable

  newparam(:name) do
    desc "The name of the Organisation"

    validate do |value|
      fail ArgumentError, "#{name} must be a String" unless value.is_a?(String)
    end

    isnamevar

  end

  newproperty(:id) do
    desc "The read-only ID of the Organisation"
    validate do |val|
      fail "id is read-only"
    end
  end 

  newproperty(:ldap_owner_group, :array_matching => :all) do
    desc "This is the LDAP group that will be owner of the Organisation"

    validate do |value|
      fail ArgumentError, "#{ldap_owner_group} must be a String" unless value.is_a?(String)
    end
  end 

  newproperty(:ldap_member_group, :array_matching => :all) do
    desc "This is the LDAP group that will be member of the Organisation"

    validate do |value|
      fail ArgumentError, "#{ldap_member_group} must be a String" unless value.is_a?(String)
    end
  end 

  newproperty(:ldap_read_only, :array_matching => :all) do
    desc "This is the LDAP group that will be read only group of the Organisation"

    validate do |value|
      fail ArgumentError, "#{ldap_read_only} must be a String" unless value.is_a?(String)
    end
  end 

end