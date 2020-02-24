require 'puppet/util/feature'
require File.join(File.dirname(__FILE__), '../util/network_device/transport/mongodb_om')
require File.join(File.dirname(__FILE__), '../util/network_device/mongodb_om/facts')

Puppet.features.add(:mongodb_om) do
  begin
    transport = nil
    if Puppet::Util::NetworkDevice.current
      #we are in `puppet device`
      transport = Puppet::Util::NetworkDevice.current.transport
    else
      #we are in `puppet resource`
      transport = Puppet::Util::NetworkDevice::Transport::Mongodb_om.new(Facter.value(:url))
    end
    facts     = Puppet::Util::NetworkDevice::Mongodb_om::Facts.new(transport).retrieve
    if facts and facts[:operatingsystem] == :Mongodb_om
      true
    else
      false
    end
  rescue
    false
  end
end