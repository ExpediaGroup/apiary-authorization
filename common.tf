data "aws_vpc" "apiary_vpc" {
  id = "${var.vpc_id}"
}

data "aws_route53_zone" "ranger_zone" {
  name   = "${var.ranger_domain_name}"
  private_zone = true
}

data "aws_secretsmanager_secret" "docker_registry" {
  count = "${ var.docker_registry_auth_secret_name == "" ? 0 : 1 }"
  name  = "${ var.docker_registry_auth_secret_name }"
}

data "aws_secretsmanager_secret_version" "docker_registry" {
  count = "${ var.docker_registry_auth_secret_name == "" ? 0 : 1 }"
  secret_id = "${data.aws_secretsmanager_secret.docker_registry.id}"
}

data "external" "docker_registry_credential" {
  count = "${ var.docker_registry_auth_secret_name == "" ? 0 : 1 }"
  program = ["echo", "${data.aws_secretsmanager_secret_version.docker_registry.secret_string}"]
}