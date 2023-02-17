/**
 * Copyright (C) 2018 Expedia Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

resource "aws_db_subnet_group" "ranger" {
  name        = "ranger-dbsg"
  subnet_ids  = ["${var.private_subnets}"]
  description = "Apiary Ranger DB Subnet Group"
  tags        = "${var.apiary_tags}"
}

resource "aws_security_group" "ranger_db" {
  name   = "ranger-db"
  vpc_id = "${var.vpc_id}"
  tags   = "${var.apiary_tags}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.aws_vpc.apiary_vpc.cidr_block}"]
    self        = true
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = "${var.ranger_db_ingress_cidr}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
}

resource "aws_rds_cluster_parameter_group" "ranger_rds_param_group" {
  name        = "ranger-cluster-param-group"
  family      = "${var.rds_family}" # Needs to be kept in sync with aws_rds_cluster.apiary_cluster.engine and version
  description = "Ranger-specific Aurora parameters"
  tags        = "${merge(map("Name", "ranger-cluster-param-group"), "${var.apiary_tags}")}"

  parameter {
    name  = "max_allowed_packet"
    value = "${var.rds_max_allowed_packet}"
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "random_id" "snapshot_id" {
  byte_length = 8
}

resource "random_string" "db_master_password" {
  length  = 16
  special = false
}

resource "aws_rds_cluster" "ranger_cluster" {
  cluster_identifier                  = "ranger-cluster"
  engine                              = "${var.rds_engine}"
  database_name                       = "${var.ranger_database_name}"
  master_username                     = "${var.db_master_username}"
  master_password                     = "${random_string.db_master_password.result}"
  backup_retention_period             = "${var.ranger_db_backup_retention}"
  preferred_backup_window             = "${var.ranger_db_backup_window}"
  preferred_maintenance_window        = "${var.ranger_db_maintenance_window}"
  db_subnet_group_name                = "${aws_db_subnet_group.ranger.name}"
  vpc_security_group_ids              = ["${compact(concat(list(aws_security_group.ranger_db.id), var.ranger_db_additional_sg))}"]
  tags                                = "${var.apiary_tags}"
  final_snapshot_identifier           = "ranger-cluster-final-${random_id.snapshot_id.hex}"
  iam_database_authentication_enabled = true
  apply_immediately                   = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_instance" "ranger_cluster_instance" {
  count                = "${var.ranger_db_instance_count}"
  identifier           = "ranger-instance-${count.index}"
  cluster_identifier   = "${aws_rds_cluster.ranger_cluster.id}"
  engine               = "${var.rds_engine}"
  instance_class       = "${var.ranger_db_instance_class}"
  db_subnet_group_name = "${aws_db_subnet_group.ranger.name}"
  publicly_accessible  = false
  tags                 = "${var.apiary_tags}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "ranger_database" {
  zone_id = "${data.aws_route53_zone.ranger_zone.zone_id}"
  name    = "${var.ranger_database_host}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_rds_cluster.ranger_cluster.endpoint}"]
}
