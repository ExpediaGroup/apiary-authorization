/**
 * Copyright (C) 2018-2019 Expedia Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

data "aws_caller_identity" "current" {}

locals {
  cw_arn = "arn:aws:swf:${var.aws_region}:${data.aws_caller_identity.current.account_id}:action/actions/AWS_EC2.InstanceId.Reboot/1.0"
}

data "aws_ami" "amzn" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-ebs"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "ranger_userdata" {
  template = "${file("${path.module}/templates/ranger_userdata.sh")}"
}

resource "aws_instance" "ranger_admin" {
  count         = "${var.ranger_instance_type == "ecs" ? 0 : length(var.private_subnets)}"
  ami           = "${var.ami_id == "" ? data.aws_ami.amzn.id : var.ami_id}"
  instance_type = "${var.ec2_instance_type}"
  key_name      = "${var.key_name}"
  ebs_optimized = true

  subnet_id              = "${var.private_subnets[count.index]}"
  iam_instance_profile   = "${aws_iam_instance_profile.ranger_ec2.id}"
  vpc_security_group_ids = ["${aws_security_group.ranger_admin.id}"]

  user_data_base64 = "${base64encode(data.template_file.ranger_userdata.rendered)}"

  root_block_device {
    volume_type = "${var.root_vol_type}"
    volume_size = "${var.root_vol_size}"
  }

  tags = "${merge(map("Name", "ranger-admin-${count.index + 1}"), "${var.apiary_tags}")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "ranger_usersync" {
  count         = "${var.ranger_instance_type == "ecs" ? 0 : 1}"
  ami           = "${var.ami_id == "" ? data.aws_ami.amzn.id : var.ami_id}"
  instance_type = "${var.ec2_instance_type}"
  key_name      = "${var.key_name}"
  ebs_optimized = true

  subnet_id              = "${var.private_subnets[count.index]}"
  iam_instance_profile   = "${aws_iam_instance_profile.ranger_ec2.id}"
  vpc_security_group_ids = ["${aws_security_group.ranger_usersync.id}"]

  user_data_base64 = "${base64encode(data.template_file.ranger_userdata.rendered)}"

  root_block_device {
    volume_type = "${var.root_vol_type}"
    volume_size = "${var.root_vol_size}"
  }

  tags = "${merge(map("Name", "ranger-usersync-${count.index + 1}"), "${var.apiary_tags}")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "ranger_admin" {
  count = "${var.ranger_instance_type == "ecs" ? 0 : length(var.private_subnets)}"

  alarm_name = "Auto Reboot - ${aws_instance.ranger_admin.*.id[count.index]}"

  dimensions = {
    InstanceId = "${aws_instance.ranger_admin.*.id[count.index]}"
  }

  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"

  alarm_description = "This will restart ranger-admin-${count.index + 1} if the status check fails"

  alarm_actions = ["${local.cw_arn}"]

  tags = "${merge(map("Name", "Auto Reboot - ${aws_instance.ranger_admin.*.id[count.index]}"), "${var.apiary_tags}")}"
}

resource "aws_cloudwatch_metric_alarm" "ranger_usersync" {
  count         = "${var.ranger_instance_type == "ecs" ? 0 : 1}"

  alarm_name = "Auto Reboot - ${aws_instance.ranger_usersync.*.id[count.index]}"

  dimensions {
    InstanceId = "${aws_instance.ranger_usersync.*.id[count.index]}"
  }

  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"

  alarm_description = "This will restart ranger-usersync-${count.index + 1} if the status check fails"

  alarm_actions = ["${local.cw_arn}"]

  tags = "${merge(map("Name", "Auto Reboot - ${aws_instance.ranger_usersync.*.id[count.index]}"), "${var.apiary_tags}")}"
}
