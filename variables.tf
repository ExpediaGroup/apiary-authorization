/**
 * Copyright (C) 2018 Expedia Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

variable "apiary_tags" {
  description = "Common tags that get put on all resources"
  type        = "map"
}

variable "ranger_domain_name" {
  description = "Route 53 domain name to register ranger-admin CNAME"
  type        = "string"
}

variable "ranger_database_host" {
  description = "Route 53 host name for Ranger database CNAME - defaults to 'ranger-database'"
  type        = "string"
  default     = "ranger-database"
}

variable "ranger_admin_host" {
  description = "Route 53 host name for Ranger admin UI CNAME - defaults to 'ranger-admin'"
  type        = "string"
  default     = "ranger-admin"
}


variable "vpc_id" {
  description = "VPC id"
  type        = "string"
}

variable "private_subnets" {
  description = "ranger admin subnets"
  type        = "list"
}

variable "aws_region" {
  description = "aws region"
  type        = "string"
}

variable "ranger_database_name" {
  description = "Database name to create in RDS for Apiary"
  type        = "string"
  default     = "ranger"
}

variable "db_master_username" {
  description = "Aurora cluster MySQL master user name."
  type        = "string"
  default     = "ranger"
}

variable "db_audit_username" {
  description = "Ranger DB Audit user name."
  type        = "string"
  default     = "rangerlogger"
}

variable "ldap_secret_name" {
  description = "Active directory LDAP bind DN SecretsManager secret name."
  type        = "string"
}

variable "ldap_ca_cert" {
  description = "Base64 encoded Certificate Authority bundle to validate LDAPS connections."
  type        = "string"
}

variable "ranger_db_additional_sg" {
  description = "Comma-seperated string for additional security groups to attach to RDS"
  type        = "list"
  default     = []
}

variable "ranger_db_instance_class" {
  description = "instance type for the rds metastore"
  type        = "string"
  default     = "db.t2.medium"
}

variable "ranger_db_instance_count" {
  description = "desired count of database cluster instances"
  type        = "string"
  default     = "2"
}

variable "ranger_db_backup_retention" {
  description = "The days to retain backups for, for the rds metastore."
  type        = "string"
  default     = "7"
}

variable "ranger_db_backup_window" {
  description = "preferred backup window for rds metastore database in UTC."
  type        = "string"
  default     = "02:00-03:00"
}

variable "ranger_db_maintenance_window" {
  description = "preferred maintenance window for rds metastore database in UTC."
  type        = "string"
  default     = "wed:03:00-wed:04:00"
}

variable "ranger_db_ingress_cidr" {
  description = "ranger db ingress cidr list"
  type        = "list"
}

variable "ranger_admin_ingress_cidr" {
  description = "ranger admin ingress cidr list"
  type        = "list"
}

variable "ranger_admin_instance_count" {
  description = "desired count of the ranger admin service"
  type        = "string"
  default     = "2"
}

variable "ranger_admin_task_memory" {
  description = "ranger admin container memory value, valid values: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html."
  type        = "string"
  default     = "8192"
}

variable "ranger_admin_task_cpu" {
  description = "ranger admin container cpu value, valid values https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html"
  type        = "string"
  default     = "1024"
}

variable "ranger_admin_loglevel" {
  description = "ranger admin process loglevel,supports log4j values"
  type        = "string"
  default     = "info"
}

variable "audit_solr_urls" {
  description = "ranger solr audit provider configuration,if not configured, defaults to db audit configuration"
  type        = "string"
  default     = ""
}

variable "ranger_usersync_task_memory" {
  description = "ranger usersync container memory value, valid values: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html."
  type        = "string"
  default     = "4096"
}

variable "ranger_usersync_task_cpu" {
  description = "ranger usersync container cpu value, valid values https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html"
  type        = "string"
  default     = "512"
}

variable "ranger_usersync_loglevel" {
  description = "ranger usersync process loglevel,supports log4j values"
  type        = "string"
  default     = "info"
}

variable "ranger_docker_image" {
  description = "docker image id for ranger"
  type        = "string"
}

variable "ranger_docker_version" {
  description = "version of the docker image for ranger"
  type        = "string"
}

variable "ldap_url" {
  description = "active directory ldap url to configure hadoop LDAP group mapping"
  type        = "string"
}

variable "ldap_base" {
  description = "active directory ldap base dn"
  type        = "string"
}

variable "ldap_domain" {
  description = "active directory ldap domain"
  type        = "string"
  default     = ""
}

variable "ldap_user_base" {
  description = "active directory ldap base dn to search for users"
  type        = "string"
}

variable "ldap_group_base" {
  description = "active directory ldap base dn to search for groups"
  type        = "string"
}

variable "ldap_sync_interval" {
  description = "ranger usersync interval"
  type        = "string"
  default     = "120"
}

variable "ranger_admin_ldap_groups" {
  description = "csv active directory groups to grant ROLE_SYS_ADMIN privileges"
  type        = "string"
  default     = ""
}

variable "docker_registry_auth_secret_name" {
  description = "Docker Registry authentication SecretManager secret name."
  type        = "string"
  default     = ""
}

variable "rds_family" {
  description = "RDS family"
  type        = "string"
  default     = "aurora-mysql5.7"
}

variable "rds_engine" {
  description = "RDS engine version"
  type        = "string"
  default     = "aurora-mysql"
}

variable "rds_max_allowed_packet" {
  description = "RDS/MySQL setting for parameter 'max_allowed_packet' in bytes. Default is 128MB (Note that MySQL default is 4MB)."
  type        = "string"
  default     = "134217728"
}
