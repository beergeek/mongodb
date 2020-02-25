Puppet::Type.newtype(:mongodb_om_db_user) do
  @doc = 'Manages users for MongoDB databases managed by Ops Manager'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)

  newproperty(:description, :parent => Puppet::Property::F5Description)

  newproperty(:configsync_ip) do
    desc "configsync_ip"
  end

  newproperty(:mirror_ip) do
    desc "mirror_ip"
  end

end