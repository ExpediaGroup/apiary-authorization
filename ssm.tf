/**
 * Copyright (C) 2018-2019 Expedia Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

data "template_file" "ranger_admin_playbook" {
  template = "${file("${path.module}/templates/ranger_playbook.yml")}"

  vars = {
    ranger_container_mode = "admin"
    aws_region = "${var.aws_region}"
    aws_loggroup = "ranger"
    heapsize = "${var.ranger_admin_task_memory}"
    loglevel = "${var.ranger_admin_loglevel}"
    db_host = "${aws_rds_cluster.ranger_cluster.endpoint}"
    db_name = "${aws_rds_cluster.ranger_cluster.database_name}"
    db_master_user_arn = "${aws_secretsmanager_secret.db_master_user.arn}"
    db_audit_user_arn = "${aws_secretsmanager_secret.db_audit_user.arn}"
    ranger_admin_arn = "${aws_secretsmanager_secret.ranger_admin.arn}"
    ldap_user_arn = "${data.aws_secretsmanager_secret.ldap_user.arn}"
    xa_ldap_ad_url = "${replace(var.ldap_url,"/","\\\\/")}"
    audit_solr_urls = "${replace(var.audit_solr_urls,"/","\\\\/")}"
    xa_ldap_ad_base_dn = "${var.ldap_base}"
    xa_ldap_ad_domain = "${var.ldap_domain}"
    ldap_ca_cert = "${var.ldap_ca_cert}"
    docker_registry_url = "apiary-docker-internal-local.artylab.expedia.biz"
    docker_image_name = "${var.ranger_docker_image}"
    docker_image_version = "${var.ranger_docker_version}"
    docker_registry_username = "${data.external.docker_registry_credential.result["username"]}"
    docker_registry_password = "${data.external.docker_registry_credential.result["password"]}"
  }
}

data "template_file" "ranger_usersync_playbook" {
  template = "${file("${path.module}/templates/ranger_playbook.yml")}"

  vars = {
    ranger_container_mode = "usersync"
    aws_region = "${var.aws_region}"
    aws_loggroup = "ranger"
    heapsize = "${var.ranger_usersync_task_memory}"
    loglevel = "${var.ranger_usersync_loglevel}"
    db_host = ""
    db_name = ""
    db_master_user_arn = ""
    db_audit_user_arn = ""
    xa_ldap_ad_url = ""
    audit_solr_urls = ""
    xa_ldap_ad_base_dn = ""
    xa_ldap_ad_domain = ""
    ranger_admin_arn = "${aws_secretsmanager_secret.ranger_admin.arn}"
    ldap_user_arn = "${data.aws_secretsmanager_secret.ldap_user.arn}"
    policy_mgr_url = "http:\\/\\/${aws_lb.ranger_admin_lb.dns_name}:6080"
    sync_ldap_url = "${replace(var.ldap_url,"/","\\\\/")}"
    sync_ldap_search_base = "${var.ldap_base}"
    sync_ldap_user_search_base = "${var.ldap_user_base}"
    sync_group_search_base = "${var.ldap_group_base}"
    sync_ldap_user_name_attribute = "sAMAccountName"
    sync_group_name_attribute = "sAMAccountName"
    sync_paged_results_size = "1000"
    sync_interval = "${var.ldap_sync_interval}"
    group_based_role_assignment_rules = "${ var.ranger_admin_ldap_groups == "" ? "" : "\\\\&ROLE_SYS_ADMIN:g:${var.ranger_admin_ldap_groups}" }"
    ldap_ca_cert = "${var.ldap_ca_cert}"
    docker_registry_url = "apiary-docker-internal-local.artylab.expedia.biz"
    docker_image_name = "${var.ranger_docker_image}"
    docker_image_version = "${var.ranger_docker_version}"
    docker_registry_username = "${data.external.docker_registry_credential.result["username"]}"
    docker_registry_password = "${data.external.docker_registry_credential.result["password"]}"
  }
}

#to delay ssm assiociation till ansible is installed
resource "null_resource" "ranger_admin_delay" {
  count = "${var.ranger_instance_type == "ecs" ? 0 : 1}"

  triggers = {
    apiary_instance_ids = "${join(",", aws_instance.ranger_admin.*.id)}"
  }

  provisioner "local-exec" {
    command = "sleep 90"
  }
}

resource "null_resource" "ranger_usersync_delay" {
  count = "${var.ranger_instance_type == "ecs" ? 0 : 1}"

  triggers = {
    apiary_instance_ids = "${join(",", aws_instance.ranger_usersync.*.id)}"
  }

  provisioner "local-exec" {
    command = "sleep 90"
  }
}

resource "aws_ssm_association" "ranger_admin_playbook" {
  count            = "${var.ranger_instance_type == "ecs" ? 0 : 1}"
  name             = "AWS-RunAnsiblePlaybook"
  association_name = "ranger-admin-playbook"

  schedule_expression = "rate(30 minutes)"

  targets {
    key    = "InstanceIds"
    values = "${aws_instance.ranger_admin.*.id}"
  }

  parameters = {
    playbook = "${data.template_file.ranger_admin_playbook.rendered}"
  }

  depends_on = ["null_resource.ranger_admin_delay"]
}

resource "aws_ssm_association" "ranger_usersync_playbook" {
  count            = "${var.ranger_instance_type == "ecs" ? 0 : 1}"
  name             = "AWS-RunAnsiblePlaybook"
  association_name = "ranger-usersync-playbook"

  schedule_expression = "rate(30 minutes)"

  targets {
    key    = "InstanceIds"
    values = "${aws_instance.ranger_usersync.*.id}"
  }

  parameters = {
    playbook = "${data.template_file.ranger_usersync_playbook.rendered}"
  }

  depends_on = ["null_resource.ranger_usersync_delay"]
}
