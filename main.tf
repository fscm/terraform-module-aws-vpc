#
# Terraform module to create a VPC.
#
# Copyright 2016-2019, Frederico Martins
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
  instance_tenancy     = "${var.instance_tenancy}"
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
  count = "${var.single_nat_gateway ? 1 : length(var.private_subnets) > 0 && length(var.public_subnets) > 0 ? length(var.private_subnets) + length(var.public_subnets) : var.private_subnets_amount + var.public_subnets_amount}"
  vpc   = true
  tags {
    Name = "${var.prefix}${var.name}${format("-%02d", count.index + 1)}"
  }
}

resource "aws_nat_gateway" "main" {
  depends_on    = ["aws_internet_gateway.main"]
  count         = "${var.single_nat_gateway ? 1 : length(var.private_subnets) > 0 && length(var.public_subnets) > 0 ? length(var.private_subnets) + length(var.public_subnets) : var.private_subnets_amount + var.public_subnets_amount}"
  allocation_id = "${element(aws_eip.nat.*.id, (var.single_nat_gateway ? 0 : count.index))}"
  subnet_id     = "${element(aws_subnet.public.*.id, 0)}"
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
  depends_on = ["aws_nat_gateway.main"]
  count      = "${var.single_nat_gateway ? 1 : length(var.private_subnets) > 0 && length(var.public_subnets) > 0 ? length(var.private_subnets) : var.private_subnets_amount}"
  vpc_id     = "${aws_vpc.main.id}"
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.main.*.id, count.index)}"
  }
  tags {
    Name = "${var.prefix}${var.name}-private${format("-%02d", count.index + 1)}"
  }
}

resource "aws_route_table" "public" {
  depends_on = ["aws_internet_gateway.main"]
  count      = "${var.single_nat_gateway ? 1 : length(var.private_subnets) > 0 && length(var.public_subnets) > 0 ? length(var.public_subnets) : var.public_subnets_amount}"
  vpc_id     = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.main.*.id, count.index + var.private_subnets_amount)}"
  }
  tags {
    Name = "${var.prefix}${var.name}-public${format("-%02d", count.index + 1)}"
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
  count                   = "${length(var.private_subnets) > 0 && length(var.public_subnets) > 0 ? length(var.private_subnets) : var.private_subnets_amount}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block              = "${length(var.private_subnets) > 0 && length(var.public_subnets) > 0 ? element(concat(var.private_subnets, list("")), count.index) : cidrsubnet(aws_vpc.main.cidr_block, ceil(log(var.private_subnets_amount + var.public_subnets_amount, 2)), length(var.private_subnets) > 0 ? 0 : count.index)}"
  vpc_id                  = "${aws_vpc.main.id}"
  map_public_ip_on_launch = false
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name = "${var.prefix}${var.name}-private${format("-%02d", count.index + 1)}-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

resource "aws_subnet" "public" {
  count                   = "${length(var.private_subnets) > 0 && length(var.public_subnets) > 0 ? length(var.public_subnets) : var.public_subnets_amount}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block              = "${length(var.private_subnets) > 0 && length(var.public_subnets) > 0 ? element(concat(var.public_subnets, list("")), count.index) : cidrsubnet(aws_vpc.main.cidr_block, ceil(log(var.private_subnets_amount + var.public_subnets_amount, 2)), length(var.private_subnets) > 0 ? 0 : count.index + var.private_subnets_amount)}"
  vpc_id                  = "${aws_vpc.main.id}"
  map_public_ip_on_launch = false
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name = "${var.prefix}${var.name}-public${format("-%02d", count.index + 1)}-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

resource "aws_route_table_association" "private" {
  depends_on = ["aws_subnet.private"]
  count          = "${length(var.private_subnets) > 0 && length(var.public_subnets) > 0 ? length(var.private_subnets) : var.private_subnets_amount}"
  route_table_id = "${element(aws_route_table.private.*.id, (var.single_nat_gateway ? 0 : count.index))}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public" {
  depends_on = ["aws_subnet.public"]
  count          = "${length(var.private_subnets) > 0 && length(var.public_subnets) > 0 ? length(var.public_subnets) : var.public_subnets_amount}"
  route_table_id = "${element(aws_route_table.private.*.id, (var.single_nat_gateway ? 0 : count.index + var.private_subnets_amount))}"
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
  tags {
    Name = "${var.prefix}${var.name}-default"
  }
}
