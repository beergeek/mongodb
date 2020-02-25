require 'puppet/util/network_device/base'
require File.join(File.dirname(__FILE__), '../mongodb_om')
require File.join(File.dirname(__FILE__), '../mongodb_om/facts')
require File.join(File.dirname(__FILE__), '../transport/mongodb_om')

class Puppet::Util::NetworkDevice::Mongodb_om::Device
  attr_reader :connection
  attr_accessor :url, :transport

  def initialize(url, options = {})
    Puppet.info url
    if url.is_a? String
      url_data = URI.parse(url)
      raise "Unexpected url '#{url}' found. Only file:/// URLs for configuration supported at the moment." unless url_data.scheme == 'file'
      raise "Trying to load config from '#{url_data.path}, but file does not exist." if url_data && !File.exist?(url_data.path)
      config = self.class.deep_symbolize(Hocon.load(url_data.path, syntax: Hocon::ConfigSyntax::HOCON) || {})
    end
    username = File.open(config[:username])
    Puppet.info username
    @autoloader = Puppet::Util::Autoload.new(
      self,
      "puppet/util/network_device/transport"
    )
    autoloader_params = ['mongodb_om']
    # As of Puppet 6.0, environment is a required autoloader parameter: (PUP-8696)
    if Gem::Version.new(Puppet.version) >= Gem::Version.new('6.0.0')
      autoloader_params << Puppet.lookup(:current_environment)
    end
    if @autoloader.load(*autoloader_params)
      @transport = Puppet::Util::NetworkDevice::Transport::Mongodb_om.new(url,options[:debug])
    end
  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::Mongodb_om::Facts.new(@transport)

    return @facts.retrieve
  end

end