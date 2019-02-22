/**
 * Copyright (C) 2018 Expedia Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

resource "aws_secretsmanager_secret" "db_master_user" {
  name = "ranger-db-master-user"
}

resource "aws_secretsmanager_secret_version" "db_master_user" {
  secret_id     = "${aws_secretsmanager_secret.db_master_user.id}"
  secret_string = "${jsonencode(map("username",var.db_master_username,"password",random_string.db_master_password.result))}"
}

resource "random_string" "db_audit_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_audit_user" {
  name = "ranger-db-audit-user"
}

resource "aws_secretsmanager_secret_version" "db_audit_user_user" {
  secret_id     = "${aws_secretsmanager_secret.db_audit_user.id}"
  secret_string = "${jsonencode(map("username",var.db_audit_username,"password",random_string.db_audit_password.result))}"
}

resource "random_string" "ranger_admin_password" {
  length  = 16
  special = false
}

resource "random_string" "ranger_tagsync_password" {
  length  = 16
  special = false
}

resource "random_string" "ranger_usersync_password" {
  length  = 16
  special = false
}

resource "random_string" "keyadmin_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "ranger_admin" {
  name = "ranger-admin"
}

resource "aws_secretsmanager_secret_version" "ranger_admin" {
  secret_id     = "${aws_secretsmanager_secret.ranger_admin.id}"
  secret_string = "${jsonencode(map("rangerAdmin_password",random_string.ranger_admin_password.result,"rangerTagsync_password",random_string.ranger_tagsync_password.result,"rangerUsersync_password",random_string.ranger_usersync_password.result,"keyadmin_password",random_string.keyadmin_password.result))}"
}

data "aws_secretsmanager_secret" "ldap_user" {
  name = "${var.ldap_secret_name}"
}
