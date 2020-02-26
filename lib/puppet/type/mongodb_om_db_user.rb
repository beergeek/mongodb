Puppet::Type.newtype(:mongodb_om_db_user) do
  @doc = 'Manages users for MongoDB databases managed by Ops Manager'

  apply_to_device
  ensurable

  newproperty(:name) do
    desc "name"
  end

  newproperty(:mobile) do
    desc "mobile"
  end

end