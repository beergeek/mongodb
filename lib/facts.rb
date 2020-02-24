class Puppet::Util::NetworkDevice::Mongodb_om::Facts

  attr_reader :transport

  def initialize(transport)
    @transport = transport
  end

  def retrieve
    facts = {}
    facts.merge(parse_device_facts)
  end

  def parse_device_facts
    facts = {
      'operatingsystem' => 'mongodb_om'
    }

    if response = @transport.call('/api/public/v1.0') and items = response['items']
      result = items.first
    else
      Puppet.warning("Did not receive device details. REST requires token access and whitelisting.")
      return facts
    end

    facts['app_name']               = result['appName']
    return facts
  end
end