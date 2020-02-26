require File.join(File.dirname(__FILE__), '../util/network_device/mongodb_om')
require File.join(File.dirname(__FILE__), '../util/network_device/transport/mongodb_om')
require 'json'

class Puppet::Provider::Mongodb_om < Puppet::Provider
  def self.device(url)
    Puppet::Util::NetworkDevice::Mongodb_om::Device.new(url)
  end

  def self.transport
    if Puppet::Util::NetworkDevice.current
      #we are in `puppet device`
      Puppet::Util::NetworkDevice.current.transport
    else
      #we are in `puppet resource`
      # fix this!!
      Puppet::Util::NetworkDevice::Transport::Mongodb_om.new(config)
    end
  end

  def self.connection
    transport.connection
  end

  def self.call(url,args={})
    transport.call(url,args)
  end

  def self.call_items(url,args={'expandSubcollections'=>'true'})
    if call = transport.call(url,args)
      call['items']
    else
      nil
    end
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

  def self.find_availability(string)
    transport.find_availability(string)
  end

  def self.find_monitors(string)
    transport.find_monitors(string)
  end

  def self.integer?(str)
    !!Integer(str)
  rescue ArgumentError, TypeError
    false
  end

  # This allows us to simply rename keys from the puppet representation
  # to the MongoDB representation.
  def rename_keys(keys_to_rename, rename_hash)
    keys_to_rename.each do |k, v|
      next unless rename_hash[k]
      value = rename_hash[k]
      rename_hash.delete(k)
      rename_hash[v] = value
    end
    return rename_hash
  end

  def string_to_integer(hash)
    # Apply transformations
    hash.each do |k, v|
      hash[k] = Integer(v) if self.class.integer?(v)
    end
  end

  # From https://stackoverflow.com/a/11788082/4918
  def self.deep_symbolize(obj)
    return obj.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = deep_symbolize(v); } if obj.is_a? Hash
    return obj.each_with_object([]) { |v, memo| memo << deep_symbolize(v); } if obj.is_a? Array
    obj
  end
end