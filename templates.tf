/**
 * Copyright (C) 2018 Expedia Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

locals {
  docker_auth = "${ var.docker_registry_auth_secret_name == "" ? "" : format("\"repositoryCredentials\" :{\n \"credentialsParameter\":\"%s\"\n},",join("\",\"",concat(data.aws_secretsmanager_secret.docker_registry.*.arn)))}"
}

data "template_file" "ranger_admin" {
  template = <<EOF
[
  {
    "name": "ranger-admin",
    "image": "${var.ranger_docker_image}:${var.ranger_docker_version}",
    "${local.docker_auth}"
    "command": [ "/start-ranger-admin.sh" ],
    "essential": true,
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.ranger.name}",
            "awslogs-region": "${var.aws_region}",
            "awslogs-stream-prefix": "/"
        }
    },
    "portMappings": [
      {
        "containerPort": 6080,
        "hostPort": 6080
      }
    ],
    "environment":[
     {
        "name": "HEAPSIZE",
        "value": "${var.ranger_admin_task_memory}"
     },
     {
        "name": "AWS_REGION",
        "value": "${var.aws_region}"
     },
     {
        "name": "db_host",
        "value": "${aws_rds_cluster.ranger_cluster.endpoint}"
     },
     {
        "name": "db_name",
        "value": "${aws_rds_cluster.ranger_cluster.database_name}"
     },
     {
        "name": "db_master_user_arn",
        "value": "${aws_secretsmanager_secret.db_master_user.arn}"
     },
     {
        "name": "db_audit_user_arn",
        "value": "${aws_secretsmanager_secret.db_audit_user.arn}"
     },
     {
        "name": "ranger_admin_arn",
        "value": "${aws_secretsmanager_secret.ranger_admin.arn}"
     },
     {
        "name": "ldap_user_arn",
        "value": "${data.aws_secretsmanager_secret.ldap_user.arn}"
     },
     {
        "name": "xa_ldap_ad_url",
        "value": "${replace(var.ldap_url,"/","\\\\/")}"
     },
     {
        "name": "audit_solr_urls",
        "value": "${replace(var.audit_solr_urls,"/","\\\\/")}"
     },
     {
        "name": "xa_ldap_ad_base_dn",
        "value": "${var.ldap_base}"
     },
     {
        "name": "xa_ldap_ad_domain",
        "value": "${var.ldap_domain}"
     },
     {
        "name": "ldap_ca_cert",
        "value": "${var.ldap_ca_cert}"
     },
     {
        "name": "LOGLEVEL",
        "value": "${var.ranger_admin_loglevel}"
     }
    ]
  }
]
EOF
}

data "template_file" "ranger_usersync" {
  template = <<EOF
[
  {
    "name": "ranger-usersync",
    "image": "${var.ranger_docker_image}:${var.ranger_docker_version}",
    "${local.docker_auth}"
    "command": [ "/start-ranger-usersync.sh" ],
    "essential": true,
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.ranger.name}",
            "awslogs-region": "${var.aws_region}",
            "awslogs-stream-prefix": "/"
        }
    },
    "environment":[
     {
        "name": "HEAPSIZE",
        "value": "${var.ranger_usersync_task_memory}"
     },
     {
        "name": "AWS_REGION",
        "value": "${var.aws_region}"
     },
     {
        "name": "ranger_admin_arn",
        "value": "${aws_secretsmanager_secret.ranger_admin.arn}"
     },
     {
        "name": "ldap_user_arn",
        "value": "${data.aws_secretsmanager_secret.ldap_user.arn}"
     },
     {
        "name": "POLICY_MGR_URL",
        "value": "http:\\/\\/${aws_lb.ranger_admin_lb.dns_name}:6080"
     },
     {
        "name": "SYNC_LDAP_URL",
        "value": "${replace(var.ldap_url,"/","\\\\/")}"

     },
     {
        "name": "SYNC_LDAP_SEARCH_BASE",
        "value": "${var.ldap_base}"
     },
     {
        "name": "SYNC_LDAP_USER_SEARCH_BASE",
        "value": "${var.ldap_user_base}"
     },
     {
        "name": "SYNC_GROUP_SEARCH_BASE",
        "value": "${var.ldap_group_base}"
     },
     {
        "name": "SYNC_LDAP_USER_NAME_ATTRIBUTE",
        "value": "sAMAccountName"
     },
     {
        "name": "SYNC_GROUP_NAME_ATTRIBUTE",
        "value": "sAMAccountName"
     },
     {
        "name": "SYNC_PAGED_RESULTS_SIZE",
        "value": "1000"
     },
     {
        "name": "SYNC_INTERVAL",
        "value": "${var.ldap_sync_interval}"
     },
     {
        "name": "GROUP_BASED_ROLE_ASSIGNMENT_RULES",
        "value": "${ var.ranger_admin_ldap_groups == "" ? "" : "\\\\&ROLE_SYS_ADMIN:g:${var.ranger_admin_ldap_groups}" }"
     },
     {
        "name": "ldap_ca_cert",
        "value": "${var.ldap_ca_cert}"
     },
     {
        "name": "LOGLEVEL",
        "value": "${var.ranger_usersync_loglevel}"
     }
    ]
  }
]
EOF
}
