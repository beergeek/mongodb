class Puppet::Util::NetworkDevice::Mongodb_om::Facts

  attr_reader :transport

  def initialize(transport)
    @transport = transport
  end

  def retrieve
    facts = {
      'operatingsystem' => 'mongodb_om'
    }

    if response = @transport.call('/api/public/v1.0')
      Puppet.debug "MongoDB Ops Manager Facts: #{response}"
      result = response
      if result.has_key?('error')
        Puppet.err result
      end
    else
      Puppet.warning("Did not receive device details. REST requires token access and whitelisting.")
      return nil
    end

    facts['app_name'] = result['appName']
    return facts
  end
end