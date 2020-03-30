Puppet::Type.newtype(:mongodb_om_proj) do
  @doc = "Manages Projects within Ops Manager.
  The title of the resource is the combination of the project name and the Organisation ID (24 characters) joined by a `@` symbol, such as:

  mongodb_om_db_role { 'development@5e439798e976cc5e50a7b165':
   ensure => present,
   ...
  }
 
  Alternatively any name can be provided as long as the `rolename` and `project_id` parameters are set.
 "

  apply_to_device
  ensurable

  newparam(:name) do
    desc 'The name of the Project and Organisation ID separated by an `@`. e.g. `dev@5e439798e976cc5e50a7b165'

    validate do |value|
      raise ArgumentError, "#{name} must be a String" unless value.is_a?(String)
      raise ArgumentError, "Format must be <PROJECTNAME>@<PROJECT ID>, not #{value}. The Organisation ID is 24 characters long and only contains hexidemical characters (lowercase)." unless value.match(/[0-9a-f){24}]/)
      resource[:org_id] = value[/.*@([0-9a-f]{24}$)/, 1]
      resource[:projname] = value[/^(.*)@.*/, 1]
    end

    isnamevar
  end

  newproperty(:projname) do
    desc 'The Project name, defaults to the first porition of the resource title. Set only once and cannot be modified'

    validate do |value|
      raise ArgumentError, "#{value} must be a String" unless value.is_a?(String)
    end
  end

  newproperty(:org_id) do
    desc 'The Organisation ID that the Project will belong to. Set only once and cannot be modified'

    validate do |value|
      raise ArgumentError, "#{org_id} must be a String" unless value.is_a?(String)
    end
  end

  newproperty(:id) do
    desc 'The read-only ID of the Project'
    validate do |value|
      raise "id is read-only, and cannot be set to #{value}"
    end
  end

  newproperty(:ldap_owner_group, :array_matching => :all) do
    desc 'This is the LDAP group that will be owner of the Project'

    validate do |value|
      raise ArgumentError, "#{value} must be a String" unless value.is_a?(String)
      raise ArgumentError, "#{value} must a proper x500 Distinguished Name" unless value =~ /^(?:(?<cn>CN=(?<name>[^,]*)),)?(?:(?<path>(?:(?:CN|OU)=[^,]+,?)+),)?(?<domain>(?:DC=[^,]+,?)+)$/
    end
  end

  newproperty(:ldap_member_group, :array_matching => :all) do
    desc 'This is the LDAP group that will be member of the Project'

    validate do |value|
      raise ArgumentError, "#{value} must be a String" unless value.is_a?(String)
      raise ArgumentError, "#{value} must a proper x500 Distinguished Name" unless value =~ /^(?:(?<cn>CN=(?<name>[^,]*)),)?(?:(?<path>(?:(?:CN|OU)=[^,]+,?)+),)?(?<domain>(?:DC=[^,]+,?)+)$/
    end
  end

  newproperty(:ldap_read_only, :array_matching => :all) do
    desc 'This is the LDAP group that will be read only group of the Project'

    validate do |value|
      raise ArgumentError, "#{value} must be a String" unless value.is_a?(String)
      raise ArgumentError, "#{value} must a proper x500 Distinguished Name" unless value =~ /^(?:(?<cn>CN=(?<name>[^,]*)),)?(?:(?<path>(?:(?:CN|OU)=[^,]+,?)+),)?(?<domain>(?:DC=[^,]+,?)+)$/
    end
  end

  newproperty(:aa_auth_mech) do
    desc 'The default authentication mechanism for the automation agent to the database instances'

    validate do |value|
      raise ArgumentError, 'The Automation Agent authentication mechanism must be one of `MONGODB-CR`, `SCRAM-SHA-256`, or `GSSAPI`' unless ['MONGODB-CR', 'SCRAM-SHA-256', 'GSSAPI'].include? value
    end

    defaultto 'SCRAM-SHA-256'
  end

  newproperty(:aa_auth_mechs, :array_matching => :all) do
    desc 'The default authentication mechanism for the automation agent to the database instances'

    validate do |value|
      raise ArgumentError, 'The Automation Agent authentication mechanisms must be an array containing one more or of MONGODB-CR`, `SCRAM-SHA-256`, or `GSSAPI`' unless ['MONGODB-CR', 'SCRAM-SHA-256', 'GSSAPI'].include? value
    end

    defaultto ['SCRAM-SHA-256']
  end

  newproperty(:deployment_auth_mechs, :array_matching => :all) do
    desc 'The authentication mechanism for database deployments'

    validate do |value|
      raise ArgumentError, 'The authentication mechanisms for MongoDB database deployments must be an array containing one more or of MONGODB-CR`, `SCRAM-SHA-256`, `PLAIN`, or `GSSAPI`' unless ['MONGODB-CR', 'SCRAM-SHA-256', 'PLAIN', 'GSSAPI'].include? value
    end

    defaultto ['SCRAM-SHA-256']
  end

  newproperty(:krb5_svc_name) do
    desc 'The Kerberos service name for the MongoDB database service'

    validate do |value|
      raise ArgumentError, "#{krb5_svc_name} must be a String" unless value.is_a?(String)
    end

    defaultto 'mongodb' #have to do this because it is the name of the module I think, e.g. cannot use :mongodb
  end

  newproperty(:tls_ca_cert_path) do
    desc 'The absolute path to the CA certificate file'

    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        raise Puppet::Error, "File paths must be fully qualified, not '#{value}'"
      end
    end
  end

  newproperty(:aa_pem_path) do
    desc 'The absolute path to PEM encoded certificate file for the automation agent'

    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        raise Puppet::Error, "File paths must be fully qualified, not '#{value}'"
      end
    end
  end

  newparam(:tls_enabled) do
    desc 'Boolean to determine if TLS is enabled within the Project'

    newvalues(:true, :false)

    validate do |value|
      if value == true
        raise ArgumentError, '`tls_ca_cert_path` must be provided if `tls_enabled` is true' if @resource[:tls_ca_cert_path].nil?
        raise ArgumentError, '`aa_pem_path` must be provided if `tls_enabled` is true' if @resource[:tls_ca_cert_path].nil?
      end
    end

    defaultto :false
  end

  newproperty(:tls_client_cert_mode) do
    desc 'The client certificate validation mode for TLS'
    defaultto :OPTIONAL
    newvalues(:OPTIONAL,:REQUIRE)
  end
end