
# NOTE

This module uses in-module Hiera for parameter values.

# mongodb (WIP)

This module is to setup MongoDB Replica Sets, Ops Manager and MMS Automation Agent. This module uses both Puppet and Bolt to manage attributes.

My recommendation is to use Puppet to manage the configuration of the operating system attributes that MongoDB [recommends](https://docs.mongodb.com/manual/administration/production-notes/) for database loads. Puppet should be used to install the backing databases for Ops Manager (Bolt can be used for this too). Puppet should also be used for installing and basic configuration of the automation agent and Ops Manager. Ops Manager will then take over the management of the automation agent and Ops Manager itself. Currently MongoDB recommend that the backing databases are not managed by Ops Manager.

The reasoning for using Puppet is that the operating system configuration should be checked regularly and Ops Manager cannot do this, but Ops Manager can manage the Replica Sets and Automation Agents after initial installation and configuration (the backing databases should not be managed by Ops Manager).

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with mongodb](#setup)
    * [What mongodb affects](#what-mongodb-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with mongodb](#beginning-with-mongodb)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

This module uses both Puppet and Bolt to manage:

* MongoDB Replcia Set (for use as backing databases for Ops Manager),
* Install and configure Ops Manager (initial configuration mainly),
* Install and initial configuration of Automation Agent.

For all installations and configurations SSL/TLS certificates can also be managed.

For MongoDB replica set installations the [recommended](https://docs.mongodb.com/manual/administration/production-notes/) operating system configuration can also be managed.

## Setup

### What mongodb affects

This module can affect the following:

* Operating System:
  * Transparent Huge Page settings
  * NUMA
  * Readahead
* SSL/TLS Certificates
* Creation, ownership and permissions of directories for MongoDB replica sets.
* Replica Sets:
  * Replica Set name
  * Cluster Authentication
  * SSL mode
  * Authentication
  * Log path
  * DB path
  * Service file configuration
  * WiredTiger Cache Size
  * Binding and ports
  * Certificates (managing and configuration in conf file)

### Setup Requirements

Hiera is recommended, utilising Sensitive type where required, to manage certificates, settings and options.

### Beginning with mongodb

To manage an automation agent instance the MMS Group andAPI ID must be known in advance, which means having Ops Manager installed and operational. The credentials for Ops Manager backing databases can be created via the `credentialstool` with Op Manager.

## Usage

The following is a basic Profile to use for nodes that will be managed by Ops Manager:

```puppet
#
# Remember '/etc/krb5.conf'!
class profile::database_services::mongodb_nodb (
  Array[String[1]]               $firewall_ports,
  Boolean                        $enable_firewall,
  Enum['http','https']           $url_svc_type,
  Optional[Sensitive[String[1]]] $aa_pem_file_content,
  Optional[Sensitive[String[1]]] $cluster_auth_pem_content,
  Optional[Sensitive[String[1]]] $keyfile_content,
  Optional[Sensitive[String[1]]] $pem_file_content,
  Optional[Sensitive[String[1]]] $server_keytab_content,
  Optional[Stdlib::Absolutepath] $aa_ca_file_path,
  Optional[Stdlib::Absolutepath] $aa_pem_file_path,
  Optional[Stdlib::Absolutepath] $ca_file_path,
  Optional[Stdlib::Absolutepath] $cluster_auth_file_path,
  Optional[Stdlib::Absolutepath] $pem_file_path,
  Optional[Stdlib::Absolutepath] $pki_path,
  Optional[Stdlib::Absolutepath] $server_keytab_path,
  Optional[String[1]]            $ca_cert_pem_content,
  Sensitive[String[1]]           $mms_api_key,
  Stdlib::Absolutepath           $base_path,
  Stdlib::Absolutepath           $db_base_path,
  Stdlib::Absolutepath           $log_path,
  String[1]                      $mms_group_id,
  String[1]                      $ops_manager_fqdn,
  String[1]                      $svc_user,
  Optional[String[1]]            $aa_ca_cert_content    = $ca_cert_pem_content,
) {
  require mongodb::os
  require mongodb::user

  if $enable_firewall {
    $firewall_ports.each |String $_port| {
    # firewall rules
      firewall { "101 allow mongodb ${_port} access":
        dport  => [$_port],
        proto  => tcp,
        action => accept,
      }
    }
  }

  if $server_keytab_path {
    require profile::kerberos
  }

  # manage directories, certs, keyfiles, keytabs as required.
  class { 'mongodb::supporting':
    ca_cert_pem_content      => $ca_cert_pem_content,
    ca_file_path             => $ca_file_path,
    cluster_auth_file_path   => $cluster_auth_file_path,
    cluster_auth_pem_content => $cluster_auth_pem_content,
    keyfile_content          => $keyfile_content,
    pem_file_content         => $pem_file_content,
    pem_file_path            => $pem_file_path,
    pki_dir                  => $pki_dir,
    server_keytab_content    => $server_keytab_content,
    server_keytab_path       => $server_keytab_path,
    svc_user                 => $svc_user,
    before                   => Class['mongodb::automation_agent'],
  }

  # install and manage the MongoDB automation agent
  class { 'mongodb::automation_agent':
    base_data_path   => $base_data_path,
    pki_path         => $pki_path,
    log_path         => $log_path,
    base_path        => $base_path,
    ops_manager_fqdn => $ops_manager_fqdn,
    url_svc_type     => $url_svc_type,
    mms_group_id     => $mms_group_id,
    mms_api_key      => $mms_api_key,
    enable_ssl       => $enable_ssl,
    ca_file_path     => $aa_ca_file_path,
    pem_file_path    => $aa_pem_file_path,
    pem_file_content => $aa_pem_file_content,
    ca_file_content  => $aa_ca_cert_content,
  }
}
```

## Reference

## Table of Contents

**Classes**

_Public Classes_

* [`mongodb::automation_agent`](#mongodbautomation_agent): A class to install, configure, and run the Ops Manager Automation Agent on nodes
* [`mongodb::bi_connecter`](#mongodbbi_connecter): A class to manage `mongosqld`/Business Intelligence
Connector instance.
* [`mongodb::install`](#mongodbinstall): Class to manage the installation of MongoDB.
* [`mongodb::ops_manager`](#mongodbops_manager): Class to manage the ancillary supporting resources for an
instance of mongodb.
* [`mongodb::os`](#mongodbos): Modifies kernel parameters for database work loads
* [`mongodb::repos`](#mongodbrepos): A class to manage the MongoDB YUM repo.
* [`mongodb::supporting`](#mongodbsupporting): Class that manage ancillary resources, such as certs and keytab files.

_Private Classes_

* `mongodb::automation_agent::config`: Class to configure the automation agent
* `mongodb::automation_agent::install`: A class to install the Ops Manager Automation Agent on nodes
* `mongodb::automation_agent::service`: Class to manage automation agent service

**Defined types**

* [`mongodb::config`](#mongodbconfig): Manages the configuration of a mongod instance
* [`mongodb::service`](#mongodbservice): Defined type to manage mongod service.

**Tasks**

* [`check_el`](#check_el): Check if OS is EL flavour
* [`deploy_instance`](#deploy_instance): A short description of this task
* [`make_project`](#make_project): Create a new Project within Ops Mananger for a specific Organisation
* [`mongo_repos_linux`](#mongo_repos_linux): A task to perform a yum update
* [`mongo_server_install`](#mongo_server_install): A task to install the mongodb enterprise server, tools and shell
* [`mongod`](#mongod): A task to implement mongod in a replica set
* [`mongod_admin_user`](#mongod_admin_user): Create the root user for the replica set
* [`mongod_rs_initiate`](#mongod_rs_initiate): A task to initiate a replica set.
* [`mongod_server_config`](#mongod_server_config): A task to configure mongodb instance.
* [`mongod_server_service`](#mongod_server_service): A task to start the mongod service
* [`mongodb_linux_user`](#mongodb_linux_user): A task to create the mongod service user.

**Plans**

* [`mongodb::mongo_check`](#mongodbmongo_check): Performs a check to determine if Production Notes have been applied to a Linux node.
* [`mongodb::mongo_cluster_linux`](#mongodbmongo_cluster_linux): Plan to build a MongoDB replica set.
* [`mongodb::mongod_linux`](#mongodbmongod_linux): A plan to instance and configure mongo server on Linux.
* [`mongodb::new_deployment`](#mongodbnew_deployment): A plan to deploy instances of MongoDB via Ops Manager API.
* [`mongodb::setup_linux`](#mongodbsetup_linux): A Plan to setup various OS-level features and security for `mongod` and `mongos`.

## Classes

### mongodb::automation_agent

A class to install, configure, and run the Ops Manager Automation Agent on nodes

#### Examples

#####

```puppet
class { 'mongodb::automation_agent':
  mms_api_key      => Sensitive('ertcvybuinkljnicusdyTRGYV GH456'),
  mms_group_id     => 'xretRTCTVYTCHVBUYIU2345678',
  ops_manager_fqdn => 'ops-manager.mongodb.local',
  enable_ssl       => false,
}
```

#### Parameters

The following parameters are available in the `mongodb::automation_agent` class.

##### `ops_manager_fqdn`

Data type: `String`

The fully qualified domain name of the Ops Manager.
Used to construct the URL to download the automation agent.

##### `mms_api_key`

Data type: `Sensitive[String[1]]`

The API key for the agent.

##### `mms_group_id`

Data type: `String`

The Project ID for the agent.

##### `url_svc_type`

Data type: `Enum['http','https']`

If the Ops Manager is `HTTP` or `HTTPS`. Values can be `http` or `https`.

##### `svc_user`

Data type: `String`

The user that automation agent will run as.

##### `ca_file_path`

Data type: `Optional[Stdlib::Absolutepath]`

The absolute path for the CA file.

##### `pem_file_path`

Data type: `Optional[Stdlib::Absolutepath]`

The absolute path for the SSL PEM file.

##### `ca_file_content`

Data type: `Optional[String[1]]`

The content of the CA file, if it will be managed.

##### `pem_file_content`

Data type: `Optional[Sensitive[String[1]]]`

The content of the SSL PEM file, if it will be managed.

##### `enable_ssl`

Data type: `Boolean`

Boolean to determine if SSL enabled for the automation agent communications.

##### `keytab_file_path`

Data type: `Optional[Stdlib::Absolutepath]`

Absolute path to the keytab file, if required.

##### `keytab_file_content`

Data type: `Optional[Sensitive[String[1]]]`

The content of the keytab file, if Puppet will manage the content.

### mongodb::bi_connecter

A class to manage `mongosqld`/Business Intelligence
  Connector instance.

#### Examples

#####

```puppet
mongodb::bi_connecter { 'namevar': }
```

#### Parameters

The following parameters are available in the `mongodb::bi_connecter` class.

##### `bic_schema_user_kerberos`

Data type: `Boolean`



##### `bic_svc_kerberos`

Data type: `Boolean`



##### `ssl_weak_certs`

Data type: `Boolean`



##### `ssl_client_weak_certs`

Data type: `Boolean`



##### `bic_ssl_mode`

Data type: `Enum['none','allowSSL','requireSSL']`



##### `bic_client_ssl_mode`

Data type: `Enum['none','allowSSL','requireSSL']`



##### `bic_schema_user_keytab_content`

Data type: `Optional[Sensitive[String[1]]]`



##### `bic_schema_user_passwd`

Data type: `Optional[Sensitive[String[1]]]`



##### `bic_svc_keytab_content`

Data type: `Optional[Sensitive[String[1]]]`



##### `bic_schema_user_keytab_path`

Data type: `Optional[Stdlib::Absolutepath]`



##### `bic_svc_keytab_path`

Data type: `Optional[Stdlib::Absolutepath]`



##### `ca_path`

Data type: `Optional[Stdlib::Absolutepath]`



##### `pem_path`

Data type: `Optional[Stdlib::Absolutepath]`



##### `pem_password`

Data type: `Optional[Sensitive[String[1]]]`



##### `bic_svc_user_home`

Data type: `Stdlib::Absolutepath`



##### `log_path`

Data type: `Stdlib::Absolutepath`



##### `bic_sample_database`

Data type: `String[1]`



##### `bic_schema_user`

Data type: `String[1]`



##### `bic_source_url`

Data type: `String[1]`



##### `bic_svc_user`

Data type: `String[1]`



##### `mongodb_connection_string`

Data type: `String[1]`



##### `port`

Data type: `String[1]`



##### `client_pem_password`

Data type: `Optional[Sensitive[String[1]]]`



Default value: $pem_password

##### `client_ca_path`

Data type: `Optional[Stdlib::Absolutepath]`



Default value: $ca_path

##### `client_pem_path`

Data type: `Optional[Stdlib::Absolutepath]`



Default value: $pem_path

### mongodb::install

Class to manage the installation of MongoDB.

#### Examples

#####

```puppet
include mongodb::install
```

#### Parameters

The following parameters are available in the `mongodb::install` class.

##### `mongodb_version`

Data type: `String[1]`

Version of MongoDB to install.

##### `install_shell`

Data type: `Boolean`

Boolean to determine if shell is installed.

Default value: `true`

##### `install_tools`

Data type: `Boolean`

Boolean to determine if tools are installed.

Default value: `true`

##### `disable_default_svc`

Data type: `Boolean`

Boolean to determine if default service is stopped and disabled.

Default value: `true`

##### `win_file_source`

Data type: `Stdlib::Filesource`

URL of source for Windows installer.

Default value: "https://downloads.mongodb.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${mongodb_version}-signed.msi"

### mongodb::ops_manager

Class to manage the ancillary supporting resources for an instance of mongodb.

#### Examples

#####

```puppet
include mongodb::ops_manager
```

#### Parameters

The following parameters are available in the `mongodb::ops_manager` class.

##### `gen_key_file_content`

Data type: `Stdlib::Base64`

Content of the `keyFile` for encryption-at-rest.

##### `appsdb_uri`

Data type: `String[1]`

Connection string for the application backing database for
Ops Manager.

##### `central_url`

Data type: `String`

URL that will be used by agents to connect to Ops Manager.
This overrides the value in the UI/Database!

##### `email_hostname`

Data type: `Stdlib::Host`

The hostname of the email server.

##### `admin_email_addr`

Data type: `String[1]`

The email address used for the admin user.

##### `from_email_addr`

Data type: `String[1]`

The email address to use as the 'from' address.

##### `reply_email_addr`

Data type: `String[1]`

The email address to use as the 'reply' address.

##### `email_transport`

Data type: `Enum['smtp','smtps']`

Email transport mechanism. Optionals are `smtp` or `smtps`.

##### `email_type`

Data type: `Enum['com.xgen.svc.core.dao.email.AwsEmailDao',
      'com.xgen.svc.core.dao.email.JavaEmailDao']`

Type of email system to use. Options are `com.xgen.svc.core.dao.email.AwsEmailDao` or
`com.xgen.svc.core.dao.email.JavaEmailDao`. Use `com.xgen.svc.core.dao.email.JavaEmailDao` for SMTP.

##### `email_port`

Data type: `String[1]`

Port number for the email server.

##### `manage_group`

Data type: `Boolean`

Boolean to determine if the service group is managed.

##### `manage_user`

Data type: `Boolean`

Boolean to determine if the service user is managed.

##### `ops_manager_ssl`

Data type: `Boolean`

Boolean to determine if SSL is used for communications.

##### `config_file_path`

Data type: `Stdlib::Absolutepath`

The absolute path for the configuration file.

##### `gen_key_file_path`

Data type: `Stdlib::Absolutepath`

The absolute path for the 'gen.key'.

##### `mms_source`

Data type: `Stdlib::Filesource`

URL or source of Ops Manager install package, does not include the Ops Manager package name.

##### `group`

Data type: `String[1]`

Service group name.

##### `mms_package_name`

Data type: `String[1]`

Name of the Ops Manager installer package.

##### `user`

Data type: `String[1]`

Name of the service user.

##### `pem_file_passwd`

Data type: `Optional[Sensitive[String[1]]]`

Password for the PEM file, if needed.

##### `manage_ca`

Data type: `Boolean`

Boolean to determine if the CA cert file is managed.

##### `manage_pem`

Data type: `Boolean`

Boolean to determine if the SSL PEM file is managed.

##### `client_cert_mode`

Data type: `Enum['none','agents_only','required']`

Mode that SSL is in for clients. Options are `none`, `agents_only`, or `required`.

##### `ca_cert_path`

Data type: `Optional[Stdlib::Absolutepath]`

The absolute path for the CA file.

##### `pem_file_path`

Data type: `Optional[Stdlib::Absolutepath]`

The absolute path for the SSL PEM file.

##### `ca_cert_content`

Data type: `Optional[String[1]]`

The content of the CA file used for mongod communication, if to managed.

##### `pem_file_content`

Data type: `Sensitive[Optional[String[1]]]`

The content of the SSL PEM file used for mongod communication, if to managed.

##### `https_ca_cert_path`

Data type: `Optional[Stdlib::Absolutepath]`

The absolute path for the CA cert for the HTTPS service.

Default value: $ca_cert_path

##### `https_pem_file_path`

Data type: `Optional[Stdlib::Absolutepath]`

The absolute path for the PEM file for the HTTPS service.

Default value: $pem_file_path

##### `https_ca_cert_content`

Data type: `Optional[String[1]]`

The content of the CA cert for the HTTPS service, if managed.

Default value: $ca_cert_content

##### `https_pem_file_content`

Data type: `Sensitive[Optional[String[1]]]`

The content of the PEM file for the HTTPS service, if managed.

Default value: $pem_file_content

##### `installer_source`

Data type: `Enum['direct','host']`

Where the agents will get the install packages from. Use `direct` for MongoDB or `host` for
Ops Manager.

##### `binary_source`

Data type: `Enum['internet','local']`

Where Ops Manager will get the binaries for the various products.

##### `enable_http_service`

Data type: `Boolean`

Boolean to determine if the Ops Manager service is running and enabled

##### `enable_backup_daemon`

Data type: `Boolean`

Boolean to determine if the Ops Manager Backup Daemon is running as a separate
process. Only valid if `enable_http_service` is `false`.

### mongodb::os

Modifies kernel parameters for database work loads

#### Examples

#####

```puppet
include mongodb::os
```

### mongodb::repos

A class to manage the MongoDB YUM repo.

#### Examples

#####

```puppet
include mongodb::repos
```

#### Parameters

The following parameters are available in the `mongodb::repos` class.

##### `gpgcheck`

Data type: `Boolean`

Boolean to determine if GPG check is performed.

##### `baseurl`

Data type: `Stdlib::Filesource`

The base URL for the repo.

##### `gpgkey`

Data type: `Stdlib::Filesource`

The absolute path or source of the GPG key.

### mongodb::supporting

Class that manage ancillary resources, such as certs and keytab files.

#### Examples

#####

```puppet
include mongodb::supporting
```

#### Parameters

The following parameters are available in the `mongodb::supporting` class.

##### `cluster_auth_pem_content`

Data type: `Optional[Sensitive[String[1]]]`

Content of the cluster auth file, if management is desired.

##### `keyfile_content`

Data type: `Optional[Sensitive[String[1]]]`

Content of the encryption-at-rest keyfile, if management is desired.

##### `pem_file_content`

Data type: `Optional[Sensitive[String[1]]]`

Content of the x509 PEM file, if management is desired.

##### `server_keytab_content`

Data type: `Optional[Sensitive[String[1]]]`

Content of Kerberos keytab, if management is desired.

##### `ca_file_path`

Data type: `Optional[Stdlib::Absolutepath]`

Absolute path of the CA file, required if managing CA file.

##### `cluster_auth_file_path`

Data type: `Optional[Stdlib::Absolutepath]`

Absolute path of the cluster auth file, required if managing cluster auth file.

##### `keyfile_path`

Data type: `Optional[Stdlib::Absolutepath]`

Absolute path of the encryption-at-rest keyfile, required if managing keyfile.

##### `pem_file_path`

Data type: `Optional[Stdlib::Absolutepath]`

Absolute path of the PEM file, required if managing the PEM file.

##### `server_keytab_path`

Data type: `Optional[Stdlib::Absolutepath]`

Absolute path of the keytab file, required if managing keytab file.

##### `ca_cert_pem_content`

Data type: `Optional[String[1]]`

Content of the CA cert file, if management is desired.

##### `base_path`

Data type: `Stdlib::Absolutepath`

Absolute path of the base directory where database, logs and PKI reside.

##### `db_base_path`

Data type: `Stdlib::Absolutepath`

The absolute path where the database will reside.
SELinux will be modified on Linux to accommodate this directory.

##### `log_path`

Data type: `Stdlib::Absolutepath`

The absolute path where the logs will reside.
SELinux will be modified on Linux to accommodate this directory.

##### `pki_path`

Data type: `Stdlib::Absolutepath`

The absolute oath where the PKI, keyfiles and keytab will reside.
SELinux will be modified on Linux to accommodate this directory.

##### `svc_user`

Data type: `String[1]`

The name of the user and group to create and manage.

##### `home_dir`

Data type: `Stdlib::Absolutepath`

The absolute path of the home directory for the serivce user.

## Defined types

### mongodb::config

Manages the configuration of a mongod instance

* **Note** As this is a defined type we are not using in-module Hiera for defaults (although we
do use a `lookup` for some per operating system defaults).

#### Parameters

The following parameters are available in the `mongodb::config` defined type.

##### `enable_kerberos`

Data type: `Boolean`

Boolean to determine if Kerberos is enabled.

Default value: `false`

##### `keytab_file_path`

Data type: `Optional[Stdlib::Absolutepath]`

The absolute path of the Kerberos keytab file.

Default value: `undef`

##### `keyfile`

Data type: `Optional[Stdlib::Absolutepath]`

The absolute path of the member authentication keyfile, if using keyfile for cluster authentication.

Default value: `undef`

##### `wiredtiger_cache_gb`

Data type: `Optional[String]`

The size of the WiredTiger Cache in Gigabytes.

Default value: `undef`

##### `member_auth`

Data type: `Enum['x509', 'keyFile', 'none']`

What, if any, cluster authentication is selected. Possible options: `x509`, `keyfile`, or `none`.

Default value: 'x509'

##### `repsetname`

Data type: `String[1]`

Name of the replica set. Defaults to `$title` of resource.

Default value: $title

##### `svc_user`

Data type: `String[1]`

The name of the user the mongod instance will run as. Used to modify the
unit file for the service if using SystemD.

Default value: 'mongod'

##### `conf_file`

Data type: `Stdlib::Absolutepath`

Absolute path where the mongod instance config file should be created.

Default value: "${lookup('mongodb::config::conf_path')}/mongod_${title}.conf"

##### `bindip`

Data type: `String[1]`

The FQDN to use in addition to use with localhost for the service to listen.

Default value: $facts['networking']['fqdn']

##### `port`

Data type: `String[1]`

The port number for the service.

Default value: '27017'

##### `log_filename`

Data type: `String[1]`

Name of the log file.

Default value: "${title}.log"

##### `auth_list`

Data type: `String[1]`

The authentication mechanisms. If `enable_kerberos` is true 'GSSAPI' will also be applied.

Default value: 'SCRAM-SHA-1,SCRAM-SHA-256'

##### `base_path`

Data type: `Stdlib::Absolutepath`

The base path of where database, logs and certs will be stored.
These can be changed individually if desired.

Default value: lookup('mongodb::config::base_path')

##### `db_base_path`

Data type: `Stdlib::Absolutepath`

Absolute path of where database directory will be located.

Default value: "${base_path}/db"

##### `db_data_path`

Data type: `Stdlib::Absolutepath`

The absolute path for the database files.

Default value: "${db_base_path}/${title}"

##### `log_path`

Data type: `Stdlib::Absolutepath`

The absolute path of the where log files will be stored.

Default value: "${base_path}/logs"

##### `pid_file`

Data type: `Stdlib::Absolutepath`

The absolute path of the PID file. Changes in the service and config files.

Default value: "${lookup('mongodb::config::pid_path')}/${title}.pid"

##### `pki_path`

Data type: `Stdlib::Absolutepath`

The absolute path of the where SSL certs, keytabs and keyfiles will be stored.

Default value: "${base_path}/pki"

##### `pem_file`

Data type: `Optional[Stdlib::Absolutepath]`

The absolute path of the SSL/TLS PEM file.

Default value: `undef`

##### `member_auth`

The cluster auth type. Options are `none`, keyFile`, or `x509`.

Default value: 'x509'

##### `ssl_mode`

Data type: `Enum['requireSSL','preferSSL','none']`

The SSL mode. Options are `requireSSL`, `preferSSL`, or `none`.

Default value: 'requireSSL'

##### `cluster_pem_file`

Data type: `Optional[Stdlib::Absolutepath]`

The absolute path of the cluster auth file, if different to PEM file.

Default value: `undef`

##### `ca_file`

Data type: `Stdlib::Absolutepath`

The absolute path for the CA cert file.

Default value: "${pki_path}/ca.cert"

### mongodb::service

Defined type to manage mongod service

#### Examples

#####

```puppet
include mongodb::service
```

#### Parameters

The following parameters are available in the `mongodb::service` defined type.

##### `ensure`

Data type: `Enum['stopped','running']`

What state to have the service in. `running` or `stopped`.

Default value: 'running'

##### `service_name`

Data type: `String[1]`

Name of the service to manage.

Default value: "mongod_${title}"

## Tasks

### check_el

Check if OS is EL flavour

**Supports noop?** false


### deploy_instance

A task to deploy a mongodb instance via Ops Manager API

**Supports noop?** false

#### Parameters

##### `ops_manager_url`

Data type: `String[1]`

URL, including port, of the Ops Manager applciation server

##### `project_id`

Data type: `String[1]`

The ID of the Project to build the instance within

##### `curl_ca_cert_path`

Data type: `Optional[String[1]]`

The absolute path on the node performing the API call for the CA cert, if required

##### `json_payload`

Data type: `String[1]`

The JSON payload for the build

##### `curl_username`

Data type: `String[1]`

The username for the API call

##### `curl_token`

Data type: `String[1]`

The token for the API user

### make_project

Create a new Project within Ops Mananger for a specific Organisation

**Supports noop?** false

#### Parameters

##### `ops_manager_url`

Data type: `String[1]`

The URL, including port number, for the Ops Manager. Do not include the end point.

##### `project_name`

Data type: `String[1]`

Name of the project to create

##### `org_id`

Data type: `String[24]`

The ID of the Organisation (Retrieve from Ops Manager)

##### `curl_username`

Data type: `String[1]`

The username for API call

##### `curl_token`

Data type: `String[1]`

Token associated with username for API call

##### `curl_ca_cert_path`

Data type: `Optional[String[1]]`

The path to the CA file if using SSL

### mongo_repos_linux

A task to perform a yum update

**Supports noop?** false

### mongo_server_install

A task to install the mongodb enterprise server, tools and shell

**Supports noop?** false

### mongod

A task to implement mongod in a replica set

**Supports noop?** false

#### Parameters

##### `primary`

Data type: `String[1]`

Which node is primary

##### `username`

Data type: `String[1]`

Operating system user to create, if it does not exist

##### `password`

Data type: `String[1]`

Operating system user password to set

### mongod_admin_user

Create the root user for the replica set

**Supports noop?** false

#### Parameters

##### `user`

Data type: `String[1]`

Admin user for the replication set

##### `passwd`

Data type: `String[1]`

Password for Admin user

##### `port`

Data type: `String[1]`

Port to bind to

##### `x509_path`

Data type: `Optional[String[1]]`

Path and name of x509 PEM file

##### `ca_path`

Data type: `Optional[String[1]]`

Path and name of CA PEM file

### mongod_rs_initiate

A task to initiate a replica set.

**Supports noop?** false

#### Parameters

##### `rs_nodes`

Data type: `String[1]`

Nodes in replica set, in order, as a single string

##### `repset`

Data type: `String[1]`

Name for replication set

##### `port`

Data type: `String[1]`

Port to bind to

##### `x509_path`

Data type: `Optional[String[1]]`

Path and name of x509 PEM file

##### `ca_path`

Data type: `Optional[String[1]]`

Path and name of CA PEM file

### mongod_server_config

A task to configure mongodb instance.

**Supports noop?** false

#### Parameters

##### `mongodb_service_user`

Data type: `String[1]`

User that the mongodb service will run as

##### `config_file`

Data type: `String[1]`

config file path and name

##### `db_path`

Data type: `String[1]`

Path to DB files

##### `log_file`

Data type: `String[1]`

Path and file name to log file

##### `base_path`

Data type: `String[1]`

Base path to MongoDB

##### `repset`

Data type: `String[1]`

Name for replication set

##### `x509_path`

Data type: `Optional[String[1]]`

Path and name of x509 PEM file

##### `ca_path`

Data type: `Optional[String[1]]`

Path and name of CA PEM file

##### `keyfile_path`

Data type: `Optional[String[1]]`

File path and name to keyfile

##### `bindnic`

Data type: `Optional[String[1]]`

NIC for listening

##### `port`

Data type: `String[1]`

Port to bind to

##### `use_keyfile`

Data type: `Boolean`

Boolean to determine if keyfile is used for auth. Overriden by `use_x509` parameter

##### `use_x509`

Data type: `Boolean`

Boolean to determine if x509 certs are used for auth. Overrides `use_keyfile` parameter

##### `extra_config`

Data type: `Optional[String[1]]`

Extra config required

### mongod_server_service

A task to start the mongod service

**Supports noop?** false

#### Parameters

##### `config_file`

Data type: `String[1]`

config file path and name

##### `run_as_service`

Data type: `Boolean`

If to use service or run as command

### mongodb_linux_user

A task to create the mongod service user.

**Supports noop?** false

#### Parameters

##### `username`

Data type: `String[1]`

Operating system user to create, if it does not exist

## Plans

### mongodb::mongo_check

Performs a check to determine if Production Notes have been applied to a Linux node.

#### Examples

#####

```puppet
puppet plan run mongodb::mongo_check drive=/dev/sda2 --nodes 1.2.3.4,5.6.7.8
```

#### Parameters

The following parameters are available in the `mongodb::mongo_check` plan.

##### `nodes`

Data type: `TargetSpec`

Array of nodes to check, IP addresses or hostnames.

##### `drive`

Data type: `String`

The disk to check for NUMA, e.g. `/dev/sda2`.

### mongodb::mongo_cluster_linux

Plan to build a MongoDB replica set.

#### Parameters

The following parameters are available in the `mongodb::mongo_cluster_linux` plan.

##### `mongos_nodes`

An array of hostnames or IP address for the mongos instances.

##### `mongod_replica_sets`

A Hash of mongod replica sets with associated data.

##### `mongod_replica_sets_hash`

Data type: `Hash`



##### `nodes`

An array of hostnames or IP addresses used to SSH to the nodes. The first node is used
to perform `rs.initiate()`.

##### `local_certs_dir`

Data type: `Optional[String[1]]`

The absolute path of the local directory containing all the x509 certificates.

##### `repo_file_path`

Data type: `String[1]`

The local absolute path of the repo file to upload.

##### `replicaset_name`

Data type: `String[1]`

The name of the replica set to create.

##### `tuned_config_file`

Data type: `String[1]`

The local absolute path of a tuned configuration file.

##### `use_keyfile`

Data type: `Boolean`

Boolean to determine if keyfile is used for clusterAuth.

Default value: `false`

##### `use_x509`

Data type: `Boolean`

Boolean to determine if x509 is used for clusterAuth.

Default value: `true`

##### `ca_path`

Data type: `Optional[String[1]]`

The local absolute path to the CA cert.

Default value: '/var/mongodb/pki/ca.pem'

##### `ca_filename`

Data type: `Optional[String[1]]`

The name for the CA cert.

Default value: `undef`

##### `x509_path`

Data type: `Optional[String[1]]`

The path where to store x509 certificates on the node.

Default value: `undef`

##### `host_file`

Data type: `Optional[String[1]]`

The local absolute path to a hosts file, if required (e.g. use DNS!).

Default value: `undef`

### mongodb::mongod_linux

A plan to instance and configure mongo server on Linux.

* **Note** REQUIRES Bolt 1.8.0

#### Parameters

The following parameters are available in the `mongodb::mongod_linux` plan.

##### `admin_password`

Data type: `String[1]`

Password for the first user (admin user).

##### `admin_user`

Data type: `String[1]`

Name of the first user (admin user).

##### `base_path`

Data type: `String[1]`

The absolute path of where all the database, log and PKI directories will reside.

##### `config_file`

Data type: `String[1]`

The absolute path of the configuration file to manage.

##### `db_path`

Data type: `String[1]`

The absolute path to where the database will be stored (should include the `base_path`).

##### `log_file`

Data type: `String[1]`

The absolute path of the log file (should include the `base_path`).

##### `port`

Data type: `String[1]`

Port number of the service.

##### `repo_file_path`

Data type: `String[1]`

Absolute path of the repo config file to manage.

##### `repset`

Data type: `String[1]`

Name of the replica set to create.

##### `rs_nodes`

Data type: `String[1]`

A comma-separated list of hostnames of the replica set members.

##### `nodes`

Data type: `TargetSpec`

A comma-separated list of nodes to configure. Can be IP or hostnames.

##### `db_install`

Data type: `Boolean`

Boolean to determine if server package is installed.

Default value: `true`

##### `run_as_service`

Data type: `Boolean`

Boolean to determine if mongod is run as service or just command.

Default value: `true`

##### `update_os`

Data type: `Boolean`

Boolean to determine if the operating system is updated before installing MongoDB.

Default value: `true`

##### `use_keyfile`

Data type: `Boolean`

Boolean to determine if keyfile is used for clusterAuth.

Default value: `false`

##### `use_x509`

Data type: `Boolean`

Boolean to determine if x509 is used for clusterAuth.

Default value: `true`

##### `bindnic`

Data type: `Optional[String[1]]`

If set to a NIC name will use IP address for `bind` statement. If not set
will use hostname.

Default value: `undef`

##### `ca_path`

Data type: `Optional[String[1]]`

Absolute path for the CA certificate on the remote node.

Default value: `undef`

##### `extra_config`

Data type: `Optional[String[1]]`

Any extra parameters to include in the config file.

Default value: `undef`

##### `keyfile_path`

Data type: `Optional[String[1]]`

Absolute path for the keyfile on the remote node, if required.

Default value: `undef`

##### `x509_path`

Data type: `Optional[String[1]]`

Absolute path for the x509 certificate, if required.

Default value: `undef`

##### `mongodb_service_user`

Data type: `String[1]`

Name of the service user.

Default value: 'mongod'

### mongodb::new_deployment

A plan to deploy instances of MongoDB via Ops Manager API.

* **Note** REQUIRES Bolt 1.8.0

#### Parameters

The following parameters are available in the `mongodb::new_deployment` plan.

##### `replica_set_members`

Data type: `Hash`

A hash of hashes describing the members of the replica set.
The root level keys are the FQDNs of the replica set members.
The sub-hash must contain the `id` of the host for the replica set.
The following are the defaults for each sub-hash:
{
  'arbitor'       => false,
  'build_indexes' => true,
  'hidden'        => false,
  'port'          => 27017,
  'priority'      => 1,
  'slave_delay'   => 0,
  'vote'          => 1,
}
Optional keys of each sub-hash:
* 'pem_file_path' absolute path to PEM file

##### `curl_token`

Data type: `String[1]`

The token to be used with cURL to authenticate with Ops Manager API.

##### `curl_username`

Data type: `String[1]`

The username to be used with cURL to authenticate with Ops Manager API.

##### `ops_manager_url`

Data type: `String[1]`

The URL for the Ops Manager, including the port number. The end point
is not required.

##### `project_id`

Data type: `String[24]`

The Project ID to where to create the new replica set.

##### `replica_set_name`

Data type: `String[1]`

The name of the new replica set.

##### `node`

Data type: `Targetspec`

The hostname or IP address of the nodes to run the API calls from.

##### `enable_encryption`

Data type: `Boolean`

A boolean to determine if encryption-at-rest is enabled or not.

Default value: `true`

##### `enable_kerberos`

Data type: `Boolean`

A boolean to determine if Kerberos authentication is enabled.

Default value: `true`

##### `ssl_mode`

Data type: `Enum['none','preferSSL','requireSSL']`

The mode that will be used for SSL/TLS.

Default value: 'preferSSL'

##### `cluster_auth_type`

Data type: `Enum['none','x509','keyFile']`

The type of cluster authentication to use between members of the replica set.

Default value: 'x509'

##### `aa_pem_file_path`

Data type: `Optional[String[1]]`

The absolute path for the PEM file for the automation agent, if SSL/TLS is required.

Default value: `undef`

##### `ca_file_path`

Data type: `Optional[String[1]]`

The absolute path for the CA certificate file for SSL/TLS, if required.

Default value: `undef`

##### `curl_ca_cert_path`

Data type: `Optional[String[1]]`

The absolute path of the CA certificate on the node that will execute the cURL command.
Only required if the Ops Manager server is using SSL/TLS.

Default value: `undef`

##### `client_cert_weak_mode`

Data type: `Enum['REQUIRED','OPTIONAL']`



Default value: 'OPTIONAL'

##### `encryption_keyfile_path`

Data type: `Optional[String[1]]`



Default value: `undef`

##### `keytab_file_path`

Data type: `Optional[String[1]]`



Default value: `undef`

##### `db_path`

Data type: `String[1]`



Default value: '/data/db'

##### `inital_auto_agent_pwd`

Data type: `String[1]`



Default value: generate('/bin/openssl rand -base64 32')

##### `inital_backup_agent_pwd`

Data type: `String[1]`



Default value: generate('/bin/openssl rand -base64 32')

##### `inital_monitoring_agent_pwd`

Data type: `String[1]`



Default value: generate('/bin/openssl rand -base64 32')

##### `log_file_path`

Data type: `String[1]`



Default value: '/data/logs/mongodb.log'

##### `mongodb_version`

Data type: `String[1]`



Default value: '4.0.9-ent'

##### `mongodb_compat_version`

Data type: `String[1]`



Default value: '4.0'

### mongodb::setup_linux

Plan to setup initial config for installation and operation of MongoDB on RHEL 7

#### Parameters

The following parameters are available in the `mongodb::setup_linux` plan.

##### `nodes`

Data type: `Array[String[1]]`

An Array of the IP addresses or hostnames of the nodes to configure

##### `replicaset_name`

Data type: `String[1]`

The name of the application the server certificate will be used for. The certificate
will be rename to `${replicaset_name}.pem` under the '/var/mongodb/pki' directory.

##### `ca_path`

Data type: `Optional[String[1]]`

Full path and file name of the CA cert on the remote node for x509 auth.

Default value: '/data/pki/ca.pem'

##### `ca_filename`

Data type: `Optional[String[1]]`

File name of CA cert on local node within the the `$certs_dir`.

Default value: `undef`

##### `certs_dir`

Full path of the directory where all the x509 certificates reside for the nodes.
Certs are placed in '/var/mongodb/pki'.

##### `node_common_name`

Data type: `String[1]`

The common name for each node that a number will be appended to, e.g. 'server'
will become server0, server1... etc etc

Default value: 'mongod'

##### `node_domain_node`

Data type: `String[1]`

The domain for each server, e.g. 'mongodb.local'.

##### `use_keyfile`

Data type: `Boolean`

Boolean to determine if keyfile is used. Is overriden by `use_x509`.
The keyfile is common to all nodes and in the format `${certs_dir}/${node_common_name}.key`.

Default value: `false`

##### `use_x509`

Data type: `Boolean`

Boolean to determine if x509 certs are used. Overrides `use_keyfile`.
Format of certificate path and name is `${certs_dir}/${node_common_name}${index}.pem`.

Default value: `true`

##### `host_file`

Data type: `Optional[String[1]]`

Optional file path of the host file to uploaed.

Default value: `undef`

##### `mongodb_service_user`

Data type: `String[1]`

Name of the system user to create, with home directory, for the `mongod` or mongos` service.

Default value: 'mongod'

##### `tuned_config_file`

Data type: `String[1]`



##### `server_count_offset`

Data type: `Integer`



Default value: 0

##### `node_certs_dir`

Data type: `String[1]`



Default value: '/certs'

##### `local_certs_dir`

Data type: `String[1]`



Default value: '/data/pki'

## Limitations

In the Limitations section, list any incompatibilities, known issues, or other warnings.

Mainly tested on RHEL7 at the moment.

## Development

In the Development section, tell other users the ground rules for contributing to your project and how they should submit their work.

## Release Notes/Contributors/Etc.

Contributors:
* Me!
