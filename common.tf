data "aws_vpc" "apiary_vpc" {
  id = "${var.vpc_id}"
}

data "aws_route53_zone" "ranger_zone" {
  name   = "${var.ranger_domain_name}"
  vpc_id = "${var.vpc_id}"
}

data "aws_secretsmanager_secret" "docker_registry" {
  count = "${ var.docker_registry_auth_secret_name == "" ? 0 : 1 }"
  name  = "${ var.docker_registry_auth_secret_name }"
}
