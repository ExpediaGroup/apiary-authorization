/**
 * Copyright (C) 2018 Expedia Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

resource "aws_iam_role" "ranger_task_exec" {
  name = "ranger-ecs-task-exec-${var.aws_region}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = "${var.apiary_tags}"
}

resource "aws_iam_role_policy_attachment" "ranger_task_exec_policy" {
  role       = "${aws_iam_role.ranger_task_exec.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "secretsmanager_for_ecs_task_exec" {
  count = "${var.docker_registry_auth_secret_name == "" ? 0 : 1}"
  name  = "secretsmanager-ranger-exec"
  role  = "${aws_iam_role.ranger_task_exec.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": "secretsmanager:GetSecretValue",
        "Resource": [ "${join("\",\"",concat(data.aws_secretsmanager_secret.docker_registry.*.arn))}" ]
    }
}
EOF
}

resource "aws_iam_role" "ranger_task" {
  name = "ranger-ecs-task-${var.aws_region}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = "${var.apiary_tags}"
}

resource "aws_iam_role_policy" "secretsmanager_for_ranger_task" {
  name = "secretsmanager"
  role = "${aws_iam_role.ranger_task.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": "secretsmanager:GetSecretValue",
        "Resource": [ "${join("\",\"",concat(aws_secretsmanager_secret.db_master_user.*.arn,aws_secretsmanager_secret.db_audit_user.*.arn,aws_secretsmanager_secret.ranger_admin.*.arn,data.aws_secretsmanager_secret.ldap_user.*.arn))}" ]
    }
}
EOF
}
