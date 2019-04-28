
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

The very basic steps needed for a user to get the module up and running. This can include setup steps, if necessary, or it can be an example of the most basic use of the module.

## Usage

Include usage examples for common use cases in the **Usage** section. Show your users how to use your module to solve problems, and be sure to include code examples. Include three to five examples of the most important or common tasks a user can accomplish with your module. Show users how to accomplish more complex tasks that involve different types, classes, and functions working in tandem.

## Reference

This section is deprecated. Instead, add reference information to your code as Puppet Strings comments, and then use Strings to generate a REFERENCE.md in your module. For details on how to add code comments and generate documentation with Strings, see the Puppet Strings [documentation](https://puppet.com/docs/puppet/latest/puppet_strings.html) and [style guide](https://puppet.com/docs/puppet/latest/puppet_strings_style.html)

If you aren't ready to use Strings yet, manually create a REFERENCE.md in the root of your module directory and list out each of your module's classes, defined types, facts, functions, Puppet tasks, task plans, and resource types and providers, along with the parameters for each.

For each element (class, defined type, function, and so on), list:

  * The data type, if applicable.
  * A description of what the element does.
  * Valid values, if the data type doesn't make it obvious.
  * Default value, if any.

For example:

```
### `pet::cat`

#### Parameters

##### `meow`

Enables vocalization in your cat. Valid options: 'string'.

Default: 'medium-loud'.
```

## Limitations

In the Limitations section, list any incompatibilities, known issues, or other warnings.

## Development

In the Development section, tell other users the ground rules for contributing to your project and how they should submit their work.

## Release Notes/Contributors/Etc. **Optional**

If you aren't using changelog, put your release notes here (though you should consider using changelog). You can also add any additional sections you feel are necessary or important to include here. Please use the `## ` header.
