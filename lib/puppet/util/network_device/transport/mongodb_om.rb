require 'puppet/util/network_device'
require 'puppet/util/network_device/transport'
require 'puppet/util/network_device/transport/base'
require File.join(File.dirname(__FILE__), 'digest_auth.rb')

class Puppet::Util::NetworkDevice::Transport::Mongodb_om < Puppet::Util::NetworkDevice::Transport::Base
  attr_reader :connection

  def initialize(url, _options = {})
    Puppet.info url
    Puppet.info username
    Puppet.info 
    require 'httpclient'
    clnt = HTTPClient.new
    clnt.ssl_config.set_trust_ca('ca.pem')
    clnt.set_auth('https://mongod0.mongodb.local:8443', user, password)
    clnt.get('https://mongod0.mongodb.local:8443/api/public/v1.0').status
  end

  def call(url, args={})
    result = connection.get(url, args)
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