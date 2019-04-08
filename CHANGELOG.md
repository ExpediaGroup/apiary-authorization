# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## [2.1.0] - 2019-04-03

### Added
- Support for Docker private registry - see [#10](https://github.com/ExpediaGroup/apiary-authorization/issues/10).

## [2.0.1] - 2019-03-12

### Added
- Pin module to use `terraform-aws-provider v1.60.0`

## [2.0.0] - 2019-02-27

### Added
- Migrate from Vault to AWS Secrets Manager - see [#6](https://github.com/ExpediaGroup/apiary-authorization/issues/6).  
This is a backwards incompatible change, adds new variables `ldap_ca_cert`, `ldap_secret_name`, please refer to the [README.md](README.md) for usage.

## [1.0.1] - 2019-02-22

### Added
- Tag resources that were not yet applying tags - see [#4](https://github.com/ExpediaGroup/apiary-authorization/issues/4).

## [1.0.0] - 2018-10-31
### Added
- initial terraform: See [#1](https://github.com/ExpediaGroup/apiary-authorization/issues/1)
- Aurora database for storing ranger configs and audit logs
- ranger admin service HA configuration with sticky sessions.
- ranger usersync service to sync ldap users and groups from Active Directory
- read database master password from vault
- route53 dns entries for ranger admin & database
- solr based auditing is not included in intial commit.
