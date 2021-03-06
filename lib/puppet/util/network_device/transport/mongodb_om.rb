require 'puppet/util/network_device'
require 'puppet/util/network_device/transport'
require 'puppet/util/network_device/transport/base'

class Puppet::Util::NetworkDevice::Transport::Mongodb_om < Puppet::Util::NetworkDevice::Transport::Base
  attr_reader :connection

  def initialize(config, _options = {})
    @config = config
    Puppet.debug "MongoDB Ops Manager URL: #{config[:url]}"
    Puppet.debug "MongoDB Ops Manager Username: #{config[:username]}"
    Puppet.debug "MongoDB Ops Manager CA Cert: #{config[:cacert]}"
    require 'httpclient'
    @connection = HTTPClient.new
    @connection.ssl_config.set_trust_ca(config[:cacert])
    @connection.set_auth(@config[:url], @config[:username], @config[:password])
  end

  def call(uri, args = {})
    result = connection.get(@config[:url] + uri, args)
    JSON.parse(result.body)
  rescue JSON::ParserError
    # This should be better at handling errors
    Puppet.err "There is a JSON error"
    return nil
  end

  def failure?(result, code_required)
    unless Array(code_required).include? result.status 
      raise "REST failure: HTTP status code #{result.status} detected.  Body of failure is: #{result.body}"
    end
  end

  def get(uri)
    result = connection.get(@config[:url] + uri, {'Content-Type' => 'application/json'})
    failure?(result, 200)
    result
  end

  def post(uri, json)
    if valid_json?(json)
      result = connection.post(@config[:url] + uri, json, {'Content-Type' => 'application/json'})
      failure?(result, 201)
      result
    else
      raise 'Invalid JSON detected.'
    end
  end

  def put(uri, json)
    if valid_json?(json)
      result = connection.put(@config[:url] + uri, json, {'Content-Type' => 'application/json'})
      failure?(result, 200)
      result
    else
      raise 'Invalid JSON detected.'
    end
  end

  def delete(uri)
    result = connection.delete(@config[:url] + uri)
    failure?(result, [200, 202, 404])
    result
  end

  def valid_json?(json)
    JSON.parse(json)
    true
  rescue
    false
  end
end