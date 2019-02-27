
# Overview

For more information please refer to the main [Apiary](https://github.com/ExpediaInc/apiary) project page.

# Variables
| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| apiary_tags | Common tags that get put on all resources | map | - | yes |
| audit_solr_urls | ranger solr audit provider configuration,if not configured, defaults to db audit configuration | string | `` | no |
| aws_region | aws region | string | - | yes |
| db_audit_username | Ranger DB Audit user name. | string | `rangerlogger` | no |
| db_master_username | Aurora cluster MySQL master user name. | string | `ranger` | no |
| ldap_base | active directory ldap base dn | string | - | yes |
| ldap_ca_cert | Base64 encoded Certificate Authority bundle to validate LDAPS connections. | string | - | yes |
| ldap_domain | active directory ldap domain | string | `` | no |
| ldap_group_base | active directory ldap base dn to search for groups | string | - | yes |
| ldap_secret_name | Active directory LDAP bind DN SecretsManager secret name. | string | - | yes |
| ldap_sync_interval | ranger usersync interval | string | `120` | no |
| ldap_url | active directory ldap url to configure hadoop LDAP group mapping | string | - | yes |
| ldap_user_base | active directory ldap base dn to search for users | string | - | yes |
| private_subnets | ranger admin subnets | list | - | yes |
| ranger_admin_ingress_cidr | ranger admin ingress cidr list | list | - | yes |
| ranger_admin_instance_count | desired count of the ranger admin service | string | `2` | no |
| ranger_admin_ldap_groups | csv active directory groups to grant ROLE_SYS_ADMIN privileges | string | `` | no |
| ranger_admin_loglevel | ranger admin process loglevel,supports log4j values | string | `info` | no |
| ranger_admin_task_cpu | ranger admin container cpu value, valid values https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html | string | `1024` | no |
| ranger_admin_task_memory | ranger admin container memory value, valid values: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html. | string | `8192` | no |
| ranger_database_name | Database name to create in RDS for Apiary | string | `ranger` | no |
| ranger_db_additional_sg | Comma-seperated string for additional security groups to attach to RDS | list | `<list>` | no |
| ranger_db_backup_retention | The days to retain backups for, for the rds metastore. | string | `7` | no |
| ranger_db_backup_window | preferred backup window for rds metastore database in UTC. | string | `02:00-03:00` | no |
| ranger_db_ingress_cidr | ranger db ingress cidr list | list | - | yes |
| ranger_db_instance_class | instance type for the rds metastore | string | `db.t2.medium` | no |
| ranger_db_instance_count | desired count of database cluster instances | string | `2` | no |
| ranger_db_maintenance_window | preferred maintenance window for rds metastore database in UTC. | string | `wed:03:00-wed:04:00` | no |
| ranger_docker_image | docker image id for ranger | string | - | yes |
| ranger_docker_version | version of the docker image for ranger | string | - | yes |
| ranger_domain_name | Route 53 domain name to register ranger-admin cname | string | - | yes |
| ranger_usersync_loglevel | ranger usersync process loglevel,supports log4j values | string | `info` | no |
| ranger_usersync_task_cpu | ranger usersync container cpu value, valid values https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html | string | `512` | no |
| ranger_usersync_task_memory | ranger usersync container memory value, valid values: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html. | string | `4096` | no |
| vpc_id | VPC id | string | - | yes |

## Usage

Example module invocation:
```
module "apiary-authorization" {
  source            = "git::https://github.com/ExpediaInc/apiary-authorization.git?ref=master"
  aws_region        = "us-west-2"
  vpc_id            = "vpc-1"
  private_subnets   = ["subnet-1", "subnet-2"]

  tags = {
    Application = "Apiary-Authorization"
    Team = "Operations"
  }

  ranger_docker_image       = "docker_repo.mydomain.com/apiary-ranger"
  ranger_docker_version     = "latest"
  ranger_db_ingress_cidr    = ["10.0.0.0/8", "172.16.0.0/12"]
  ranger_admin_ingress_cidr = ["10.0.0.0/8", "172.16.0.0/12"]
  ranger_domain_name        = "mydomain.com"

  ldap_secret_name = "bind_credential"
  ldap_ca_cert     = "${base64encode(file("files/ldap_ca.crt"))}"
  ldap_url         = "ldaps://ldap_server.mydomain.com"
  ldap_base        = "dc=mydomain,dc=com"
  ldap_user_base   = "OU=All Users,DC=mydomain,DC=com"
  ldap_group_base  = "OU=Security Groups,DC=mydomain,DC=com"

}
```

# Notes

This module requires SSL certificate for ranger-admin in IAM,you can use following command to upload certificate.
```
aws iam upload-server-certificate --server-certificate-name ranger-admin.mydomain.com --certificate-body file://ranger-admin.mydomain.com.crt --private-key file://ranger-admin.mydomain.com.pem
```

# Contact

## Mailing List
If you would like to ask any questions about or discuss Apiary please join our mailing list at

  [https://groups.google.com/forum/#!forum/apiary-user](https://groups.google.com/forum/#!forum/apiary-user)

# Legal
This project is available under the [Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0.html).

Copyright 2018 Expedia Inc.
