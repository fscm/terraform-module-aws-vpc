#
# Terraform module to create or impersonate a VPC.
#
# Copyright 2016-2020, Frederico Martins
#   Author: Frederico Martins <http://github.com/fscm>
#
# SPDX-License-Identifier: MIT
#
# This program is free software. You can use it and/or modify it under the
# terms of the MIT License.
#

#
# Requirements.
#
terraform {
  required_version = ">= 0.10.3" # Local Values
}

#
# Local Values.
#
locals {
  _max_gateways         = "${var.single_nat_gateway ? 1 : (max(length(var.private_subnets), length(var.public_subnets)) > 0 ? length(var.private_subnets) : var.private_subnets_amount)}"
  _newbits              = "${ceil(log(var.private_subnets_amount + var.public_subnets_amount, 2))}"
  _newbits_alt          = "${ceil(log(length(var.private_subnets) + length(var.public_subnets), 2))}"
}

#
# VPC for the infrastructure.
#
resource "aws_vpc" "main" {
  assign_generated_ipv6_cidr_block = true
  cidr_block                       = "${var.cidr}"
  enable_dns_hostnames             = "${var.enable_dns_hostnames}"
  enable_dns_support               = "${var.enable_dns_support}"
  instance_tenancy                 = "${var.instance_tenancy}"
  tags {
    Name = "${var.prefix}${var.name}"
  }
}

#
# Gateway and NAT for outside world access (internet access).
#
resource "aws_internet_gateway" "main" {
  count  = "${max(length(var.private_subnets), length(var.public_subnets)) > 0 ? signum(length(var.public_subnets)) : signum(var.public_subnets_amount)}"
  vpc_id = "${aws_vpc.main.id}"
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name = "${var.prefix}${var.name}"
  }
}

resource "aws_eip" "nat" {
  count = "${local._max_gateways}"
  vpc   = true
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name = "${var.prefix}${var.name}${format("-%02d", count.index + 1)}"
  }
}

resource "aws_nat_gateway" "main" {
  depends_on    = ["aws_internet_gateway.main"]
  count         = "${local._max_gateways}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name = "${var.prefix}${var.name}${format("-%02d", count.index + 1)}"
  }
}

#
# DHCP configurations.
#
resource "aws_vpc_dhcp_options" "main" {
  count               = "${var.domain_name != "" ? 1 : 0}"
  domain_name         = "${var.domain_name}"
  domain_name_servers = "${var.domain_name_servers}"
  tags {
    Name = "${var.prefix}${var.name}"
  }
}

resource "aws_vpc_dhcp_options_association" "main" {
  count           = "${var.domain_name != "" ? 1 : 0}"
  dhcp_options_id = "${aws_vpc_dhcp_options.main.id}"
  vpc_id          = "${aws_vpc.main.id}"
}

#
# DNS Zone configurations.
#
resource "aws_route53_zone" "private" {
  count   = "${var.domain_name != "" ? 1 : 0}"
  comment = "${var.prefix}${var.name} private DNS"
  name    = "${var.domain_name}"
  vpc {
    vpc_id  = "${aws_vpc.main.id}"
  }
  tags {
    Name = "${var.prefix}${var.name}"
  }
}

#
# Base VPC network routing.
#
resource "aws_route_table" "private" {
  #depends_on = ["aws_nat_gateway.main"]
  count      = "${local._max_gateways}"
  vpc_id     = "${aws_vpc.main.id}"
  lifecycle {
    ignore_changes = ["propagating_vgws"]
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.main.*.id, count.index)}"
  }
  route {
    ipv6_cidr_block = "::/0"
    nat_gateway_id  = "${element(aws_nat_gateway.main.*.id, count.index)}"
  }
  tags {
    Name = "${var.prefix}${var.name}-private${format("-%02d", count.index + 1)}"
  }
}

resource "aws_route_table" "public" {
  #depends_on = ["aws_internet_gateway.main"]
  count      = "${max(length(var.private_subnets), length(var.public_subnets)) > 0 ? signum(length(var.public_subnets)) : signum(var.public_subnets_amount)}"
  vpc_id     = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = "${aws_internet_gateway.main.id}"
  }
  tags {
    Name = "${var.prefix}${var.name}-public${format("-%02d", count.index + 1)}"
  }
}

#
# Availability Zones.
#
data "aws_availability_zones" "available" {
  #state = "available"
}

#
# Base VPC subnets and respective routing associations.
#
resource "aws_subnet" "private" {
  count                           = "${max(length(var.private_subnets), length(var.public_subnets)) > 0 ? length(var.private_subnets) : var.private_subnets_amount}"
  availability_zone               = "${element(data.aws_availability_zones.available.names, count.index)}"
  assign_ipv6_address_on_creation = true
  #cidr_block                      = "${max(length(var.private_subnets), length(var.public_subnets)) > 0 ? element(concat(var.private_subnets, list("")), count.index) : cidrsubnet(aws_vpc.main.cidr_block, local._newbits, count.index)}"
  cidr_block                      = "${max(length(var.private_subnets), length(var.public_subnets)) > 0 ? element(concat(var.private_subnets, list("")), count.index) : cidrsubnet(aws_vpc.main.cidr_block, (max(length(var.private_subnets), length(var.public_subnets)) > 0 ? local._newbits_alt : local._newbits), count.index)}"
  ipv6_cidr_block                 = "${cidrsubnet(aws_vpc.main.ipv6_cidr_block, (max(length(var.private_subnets), length(var.public_subnets)) > 0 ? local._newbits_alt : local._newbits), count.index)}"
  vpc_id                          = "${aws_vpc.main.id}"
  map_public_ip_on_launch         = false
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name = "${var.prefix}${var.name}-private${format("-%02d", count.index + 1)}-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

resource "aws_subnet" "public" {
  count                           = "${max(length(var.private_subnets), length(var.public_subnets)) > 0 ? length(var.public_subnets) : var.public_subnets_amount}"
  availability_zone               = "${element(data.aws_availability_zones.available.names, count.index)}"
  assign_ipv6_address_on_creation = true
  #cidr_block                      = "${max(length(var.private_subnets), length(var.public_subnets)) > 0 ? element(concat(var.public_subnets, list("")), count.index) : cidrsubnet(aws_vpc.main.cidr_block, local._newbits, count.index + var.private_subnets_amount)}"
  cidr_block                      = "${max(length(var.private_subnets), length(var.public_subnets)) > 0 ? element(concat(var.public_subnets, list("")), count.index) : cidrsubnet(aws_vpc.main.cidr_block, (max(length(var.private_subnets), length(var.public_subnets)) > 0 ? local._newbits_alt : local._newbits), count.index + var.private_subnets_amount)}"
  ipv6_cidr_block                 = "${cidrsubnet(aws_vpc.main.ipv6_cidr_block, (max(length(var.private_subnets), length(var.public_subnets)) > 0 ? local._newbits_alt : local._newbits), count.index + var.private_subnets_amount)}"
  vpc_id                          = "${aws_vpc.main.id}"
  map_public_ip_on_launch         = false
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name = "${var.prefix}${var.name}-public${format("-%02d", count.index + 1)}-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

resource "aws_route_table_association" "private" {
  #depends_on = ["aws_subnet.private"]
  count          = "${max(length(var.private_subnets), length(var.public_subnets)) > 0 ? length(var.private_subnets) : var.private_subnets_amount}"
  route_table_id = "${element(aws_route_table.private.*.id, (var.single_nat_gateway ? 0 : count.index))}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public" {
  #depends_on = ["aws_subnet.public"]
  count          = "${max(length(var.private_subnets), length(var.public_subnets)) > 0 ? length(var.public_subnets) : var.public_subnets_amount}"
  route_table_id = "${aws_route_table.public.id}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  lifecycle {
    create_before_destroy = true
  }
}

#
# Default VPC Security Group (allows traffic between instances).
#
resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.main.id}"
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = "0"
    to_port          = "0"
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
  tags {
    Name = "${var.prefix}${var.name}-default"
  }
}

#
# S3 endpoint service.
#
data "aws_vpc_endpoint_service" "s3" {
  service = "s3"
}

#
# S3 endpoint.
#
resource "aws_vpc_endpoint" "s3" {
  count             = "${var.enable_s3_endpoint ? 1 : 0}"
  vpc_endpoint_type = "Gateway"
  vpc_id            = "${aws_vpc.main.id}"
  service_name      = "${data.aws_vpc_endpoint_service.s3.service_name}"
}

#
# S3 network routing association.
#
resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  #depends_on      = ["aws_vpc_endpoint.s3"]
  count           = "${var.enable_s3_endpoint ? local._max_gateways : 0}"
  route_table_id  = "${element(aws_route_table.private.*.id, count.index)}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  #depends_on      = ["aws_vpc_endpoint.s3"]
  count           = "${var.enable_s3_endpoint ? (max(length(var.private_subnets), length(var.public_subnets)) > 0 ? signum(length(var.public_subnets)) : signum(var.public_subnets_amount)) : 0}"
  route_table_id  = "${element(aws_route_table.public.id, count.index)}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}
