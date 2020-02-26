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

  newparam(:id) do
    desc "The read-only ID of the Organisation"
    validate do |val|
      fail "id is read-only"
    end
  end 

end