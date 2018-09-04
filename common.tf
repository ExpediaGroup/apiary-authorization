locals {
  vault_path = "${ var.vault_path == "" ? format("secret/apiary-ranger-%s",var.aws_region) : var.vault_path }"
}

data "aws_vpc" "apiary_vpc" {
  id = "${var.vpc_id}"
}

data "aws_route53_zone" "ranger_zone" {
  name   = "${var.ranger_domain_name}"
  vpc_id = "${var.vpc_id}"
}
