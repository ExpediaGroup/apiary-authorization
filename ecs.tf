/**
 * Copyright (C) 2018-2019 Expedia Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

resource "aws_ecs_cluster" "ranger" {
  count = "${var.ranger_instance_type == "ecs" ? 1 : 0}"
  name = "ranger"
  tags = "${var.apiary_tags}"
}


resource "aws_ecs_task_definition" "ranger_admin" {
  count = "${var.ranger_instance_type == "ecs" ? 1 : 0}"
  family                   = "ranger-admin"
  task_role_arn            = "${aws_iam_role.ranger_task.arn}"
  execution_role_arn       = "${aws_iam_role.ranger_task_exec.arn}"
  network_mode             = "awsvpc"
  memory                   = "${var.ranger_admin_task_memory}"
  cpu                      = "${var.ranger_admin_task_cpu}"
  requires_compatibilities = ["EC2", "FARGATE"]
  container_definitions    = "${data.template_file.ranger_admin.rendered}"
  tags                     = "${var.apiary_tags}"
}

resource "aws_ecs_service" "ranger_service" {
  count = "${var.ranger_instance_type == "ecs" ? 1 : 0}"
  name            = "ranger-admin-service"
  launch_type     = "FARGATE"
  cluster         = "${aws_ecs_cluster.ranger.id}"
  task_definition = "${aws_ecs_task_definition.ranger_admin.arn}"
  desired_count   = "${var.ranger_admin_instance_count}"

  network_configuration {
    security_groups = ["${aws_security_group.ranger_admin.id}"]
    subnets         = ["${var.private_subnets}"]
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.ranger_admin_tg.arn}"
    container_name   = "ranger-admin"
    container_port   = 6080
  }

  depends_on = ["aws_lb_target_group.ranger_admin_tg", "aws_rds_cluster_instance.ranger_cluster_instance"]
}

resource "aws_ecs_task_definition" "ranger_usersync" {
  count = "${var.ranger_instance_type == "ecs" ? 1 : 0}"
  family                   = "ranger-usersync"
  task_role_arn            = "${aws_iam_role.ranger_task.arn}"
  execution_role_arn       = "${aws_iam_role.ranger_task_exec.arn}"
  network_mode             = "awsvpc"
  memory                   = "${var.ranger_usersync_task_memory}"
  cpu                      = "${var.ranger_usersync_task_cpu}"
  requires_compatibilities = ["EC2", "FARGATE"]
  container_definitions    = "${data.template_file.ranger_usersync.rendered}"
  tags                     = "${var.apiary_tags}"
}

resource "aws_ecs_service" "ranger_usersync" {
  count = "${var.ranger_instance_type == "ecs" ? 1 : 0}"
  name            = "ranger-usersync"
  launch_type     = "FARGATE"
  cluster         = "${aws_ecs_cluster.ranger.id}"
  task_definition = "${aws_ecs_task_definition.ranger_usersync.arn}"
  desired_count   = "1"

  network_configuration {
    security_groups = ["${aws_security_group.ranger_usersync.id}"]
    subnets         = ["${var.private_subnets}"]
  }

  depends_on = ["aws_ecs_service.ranger_service"]
}