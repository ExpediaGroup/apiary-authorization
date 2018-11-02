/**
 * Copyright (C) 2018 Expedia Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

resource "aws_ecs_cluster" "ranger" {
  name = "ranger"
}

resource "aws_cloudwatch_log_group" "ranger" {
  name = "ranger"
  tags = "${var.apiary_tags}"
}

data "vault_generic_secret" "ranger_admin" {
  path = "${local.vault_path}/ranger_admin"
}

resource "aws_ecs_task_definition" "ranger_admin" {
  family                   = "ranger-admin"
  task_role_arn            = "${aws_iam_role.ranger_task.arn}"
  execution_role_arn       = "${aws_iam_role.ranger_task_exec.arn}"
  network_mode             = "awsvpc"
  memory                   = "${var.ranger_admin_task_memory}"
  cpu                      = "${var.ranger_admin_task_cpu}"
  requires_compatibilities = ["EC2", "FARGATE"]
  container_definitions    = "${data.template_file.ranger_admin.rendered}"
}

resource "aws_security_group" "ranger_admin" {
  name   = "ranger-admin"
  vpc_id = "${var.vpc_id}"
  tags   = "${var.apiary_tags}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.ranger_admin_ingress_cidr}"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.ranger_admin_ingress_cidr}"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.aws_vpc.apiary_vpc.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ranger_usersync" {
  name   = "ranger-usersync"
  vpc_id = "${var.vpc_id}"
  tags   = "${var.apiary_tags}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.aws_vpc.apiary_vpc.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "ranger_service" {
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

resource "aws_lb" "ranger_admin_lb" {
  name               = "ranger-admin-lb"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ranger_admin.id}"]
  subnets            = ["${var.private_subnets}"]
  internal           = true
  tags               = "${var.apiary_tags}"
}

resource "aws_route53_record" "ranger_admin" {
  zone_id = "${data.aws_route53_zone.ranger_zone.zone_id}"
  name    = "ranger-admin"
  type    = "A"

  alias {
    name                   = "${aws_lb.ranger_admin_lb.dns_name}"
    zone_id                = "${aws_lb.ranger_admin_lb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_lb_target_group" "ranger_admin_tg" {
  name        = "ranger-admin-tg"
  port        = 6080
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"
  slow_start  = 900

  stickiness {
    type    = "lb_cookie"
    enabled = true
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 10
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    matcher             = 200
    path                = "/login.jsp"
  }

  depends_on = ["aws_lb.ranger_admin_lb"]
}

data "vault_generic_secret" "ranger_admin_cert" {
  path = "${local.vault_path}/${aws_route53_record.ranger_admin.fqdn}"
}

resource "aws_iam_server_certificate" "ranger_admin" {
  name             = "ranger-admin"
  certificate_body = "${data.vault_generic_secret.ranger_admin_cert.data["crt"]}"
  private_key      = "${data.vault_generic_secret.ranger_admin_cert.data["pem"]}"
}

resource "aws_lb_listener" "ranger_http_listener" {
  load_balancer_arn = "${aws_lb.ranger_admin_lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "ranger_https_listener" {
  load_balancer_arn = "${aws_lb.ranger_admin_lb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${aws_iam_server_certificate.ranger_admin.arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.ranger_admin_tg.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "ranger_listener" {
  load_balancer_arn = "${aws_lb.ranger_admin_lb.arn}"
  port              = "6080"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.ranger_admin_tg.arn}"
    type             = "forward"
  }
}

resource "aws_ecs_task_definition" "ranger_usersync" {
  family                   = "ranger-usersync"
  task_role_arn            = "${aws_iam_role.ranger_task.arn}"
  execution_role_arn       = "${aws_iam_role.ranger_task_exec.arn}"
  network_mode             = "awsvpc"
  memory                   = "${var.ranger_usersync_task_memory}"
  cpu                      = "${var.ranger_usersync_task_cpu}"
  requires_compatibilities = ["EC2", "FARGATE"]
  container_definitions    = "${data.template_file.ranger_usersync.rendered}"
}

resource "aws_ecs_service" "ranger_usersync" {
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
