# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2018-10-31
### Added
- initial terraform: See [#1](https://github.com/ExpediaInc/apiary-authorization/issues/1)
- Aurora database for storing ranger configs and audit logs
- ranger admin service HA configuration with sticky sessions.
- ranger usersync service to sync ldap users and groups from Active Directory
- read database master password from vault
- route53 dns entries for ranger admin & database
- solr based auditing is not included in intial commit.
