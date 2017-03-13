#
# Terraform module to create a VPC.
#
# Copyright 2016-2017, Frederico Martins
#   Author: Frederico Martins <http://github.com/fscm>
#
# SPDX-License-Identifier: MIT
#
# This program is free software. You can use it and/or modify it under the
# terms of the MIT License.
#

#
# VPC for the infrastructure.
#
resource "aws_vpc" "main" {
  cidr_block           = "${var.cidr}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support   = "${var.enable_dns_support}"
  tags {
    Name = "${var.prefix}${var.name}"
  }
}

#
# Gateway and NAT for outside world access (internet access).
#
resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name = "${var.prefix}${var.name}"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "main" {
  depends_on    = ["aws_internet_gateway.main"]
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${element(aws_subnet.public.*.id, 0)}"
  lifecycle {
    create_before_destroy = true
  }
}

#
# DHCP configurations.
#
resource "aws_vpc_dhcp_options" "main" {
  domain_name         = "${var.domain}"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags {
    Name = "${var.prefix}${var.name}"
  }
}

resource "aws_vpc_dhcp_options_association" "main" {
  dhcp_options_id = "${aws_vpc_dhcp_options.main.id}"
  vpc_id          = "${aws_vpc.main.id}"
}

#
# Base VPC network routing.
#
resource "aws_route_table" "private" {
  depends_on = ["aws_nat_gateway.main"]
  vpc_id     = "${aws_vpc.main.id}"
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.main.id}"
  }
  tags {
    Name = "${var.prefix}${var.name}-private"
  }
}

resource "aws_route_table" "public" {
  depends_on = ["aws_internet_gateway.main"]
  vpc_id     = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
  tags {
    Name = "${var.prefix}${var.name}-public"
  }
}

#
# Availability Zones.
#
data "aws_availability_zones" "available" {
  state = "available"
}

#
# Base VPC subnets and respective routing associations.
#
resource "aws_subnet" "private" {
  count                   = "${length(var.private_subnets)}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block              = "${element(var.private_subnets, count.index)}"
  vpc_id                  = "${aws_vpc.main.id}"
  map_public_ip_on_launch = false
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name = "${var.prefix}${var.name}-private-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

resource "aws_subnet" "public" {
  count                   = "${length(var.public_subnets)}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block              = "${element(var.public_subnets, count.index)}"
  vpc_id                  = "${aws_vpc.main.id}"
  map_public_ip_on_launch = false
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name = "${var.prefix}${var.name}-public-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

resource "aws_route_table_association" "private" {
  count          = "${length(var.private_subnets)}"
  route_table_id = "${aws_route_table.private.id}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets)}"
  route_table_id = "${aws_route_table.public.id}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  lifecycle {
    create_before_destroy = true
  }
}

#
# Default VPC Security Group (allows traffic between instances).
#
resource "aws_security_group" "default" {
  name   = "${var.prefix}${var.name}"
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
  tags {
    Name = "${var.prefix}${var.name}"
  }
}
