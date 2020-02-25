require 'puppet/util/network_device'
require 'puppet/util/network_device/transport'
require 'puppet/util/network_device/transport/base'

class Puppet::Util::NetworkDevice::Transport::Mongodb_om < Puppet::Util::NetworkDevice::Transport::Base
  attr_reader :connection

  def initialize(@config, _options = {})
    Puppet.info config[:url]
    Puppet.info config[:username]
    Puppet.info config[:cacert]
    require 'httpclient'
    @connection = HTTPClient.new
    @connection.ssl_config.set_trust_ca(config[:cacert])
    @connection.set_auth(@config[:url], @config[:username], @config[:password])
  end

  def call(url, args={})
    result = connection.get(@config[:url] + '/' + uri, args)
    JSON.parse(result.body)
  rescue JSON::ParserError
    # This should be better at handling errors
    return nil
  end

  def failure?(result)
    unless result.status == 200
      fail("REST failure: HTTP status code #{result.status} detected.  Body of failure is: #{result.body}")
    end
  end

  def post(url, json)
    if valid_json?(json)
      result = connection.post do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.body = json
      end
      failure?(result)
      return result
    else
      fail('Invalid JSON detected.')
    end
  end

  def put(url, json)
    if valid_json?(json)
      result = connection.put do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.body = json
      end
      failure?(result)
      return result
    else
      fail('Invalid JSON detected.')
    end
  end

  def delete(url)
    result = connection.delete(url)
    failure?(result)
    return result
  end

  def valid_json?(json)
    JSON.parse(json)
    return true
  rescue
    return false
  end
end