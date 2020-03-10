require File.join(File.dirname(__FILE__), '../util/network_device/mongodb_om')
require File.join(File.dirname(__FILE__), '../util/network_device/transport/mongodb_om')
require 'json'

class Puppet::Provider::Mongodb_om < Puppet::Provider
  def self.device(url)
    Puppet::Util::NetworkDevice::Mongodb_om::Device.new(url)
  end

  def self.transport
    if Puppet::Util::NetworkDevice.current
      # we are in `puppet device`
      Puppet::Util::NetworkDevice.current.transport
    else
      # we are in `puppet resource`
      raise 'Please use `puppet device --target <TARGET_NAME> --resourse <RESOURCE_TYPE>`'
    end
  end

  def self.connection
    transport.connection
  end

  def self.call(url, args = {})
    transport.call(url, args)
  end

  def self.call_items(url, args = { 'expandSubcollections' => 'true' })
    if call = transport.call(url, args)
      call
    else
      nil
    end
  end

  def self.get(url)
    transport.get(url)
  end

  def self.post(url, message)
    transport.post(url, message)
  end

  def self.put(url, message)
    transport.put(url, message)
  end

  def self.delete(url)
    transport.delete(url)
  end
end
