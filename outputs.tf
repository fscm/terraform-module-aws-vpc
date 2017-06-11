#
# Outputs for the VPC terraform module.
#
# Copyright 2016-2017, Frederico Martins
#   Author: Frederico Martins <http://github.com/fscm>
#
# SPDX-License-Identifier: MIT
#
# This program is free software. You can use it and/or modify it under the
# terms of the MIT License.
#

output "cidr" {
  sensitive = false
  value     = "${aws_vpc.main.cidr_block}"
}

output "default_security_group_id" {
  sensitive = false
  value     = "${aws_default_security_group.default.id}"
}

output "domain" {
  sensitive = false
  value     = "${var.domain}"
}

output "igw_id" {
  sensitive = false
  value     = "${aws_internet_gateway.main.id}"
}

output "nat_eip" {
  sensitive = false
  value     = "${aws_eip.nat.public_ip}"
}

output "nat_gw_id" {
  sensitive = false
  value     = "${aws_nat_gateway.main.id}"
}

output "prefix" {
  sensitive = false
  value     = "${var.prefix}"
}

output "private_route_table_id" {
  sensitive = false
  value     = "${aws_route_table.private.id}"
}

output "private_subnets" {
  sensitive = false
  value     = ["${aws_subnet.private.*.id}"]
}

output "public_route_table_id" {
  sensitive = false
  value     = "${aws_route_table.public.id}"
}

output "public_subnets" {
  sensitive = false
  value     = ["${aws_subnet.public.*.id}"]
}

output "vpc_id" {
  sensitive = false
  value     = "${aws_vpc.main.id}"
}

output "dns_zone_id" {
  sensitive = false
  value = "${aws_route53_zone.private.zone_id}"
}

output "dns_resolvers" {
  sensitive = false
  value = "${aws_route53_zone.private.name_servers}"
}
