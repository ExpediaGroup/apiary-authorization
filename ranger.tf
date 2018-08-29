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

data "template_file" "ranger_admin" {
  template = <<EOF
[
  {
    "name": "ranger-admin",
    "image": "${var.ranger_docker_image}:${var.ranger_docker_version}",
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
        "name": "VAULT_ADDR",
        "value": "${var.vault_internal_addr}"
     },
     {
        "name": "vault_path",
        "value": "${local.vault_path}"
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
        "name": "LOGLEVEL",
        "value": "${var.ranger_admin_loglevel}"
     }
    ]
  }
]
EOF
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
  depends_on = [ "aws_lb_target_group.ranger_admin_tg", "aws_rds_cluster_instance.ranger_cluster_instance" ]
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
    type = "lb_cookie"
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
  depends_on  = ["aws_lb.ranger_admin_lb"]
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

data "template_file" "ranger_usersync" {
  template = <<EOF
[
  {
    "name": "ranger-usersync",
    "image": "${var.ranger_docker_image}:${var.ranger_docker_version}",
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
        "name": "VAULT_ADDR",
        "value": "${var.vault_internal_addr}"
     },
     {
        "name": "vault_path",
        "value": "${local.vault_path}"
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
        "name": "LOGLEVEL",
        "value": "${var.ranger_usersync_loglevel}"
     }
    ]
  }
]
EOF
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
  depends_on = [ "aws_ecs_service.ranger_service" ]
}
