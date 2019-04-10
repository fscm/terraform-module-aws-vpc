#
# Outputs for the VPC terraform module.
#
# Copyright 2016-2019, Frederico Martins
#   Author: Frederico Martins <http://github.com/fscm>
#
# SPDX-License-Identifier: MIT
#
# This program is free software. You can use it and/or modify it under the
# terms of the MIT License.
#

output "cidr" {
  description = "The CIDR block of the VPC."
  sensitive   = false
  value       = "${aws_vpc.main.cidr_block}"
}

output "default_network_acl_id" {
  description = "The ID of the network ACL created by default on VPC creation."
  sensitive   = false
  value       = "${aws_vpc.main.default_network_acl_id}"
}

output "default_route_table_id" {
  description = "The ID of the route table created by default on VPC creation."
  sensitive   = false
  value       = "${aws_vpc.main.default_route_table_id}"
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation."
  sensitive   = false
  value       = "${aws_default_security_group.default.id}"
}

output "dns_zone_id" {
  description = "The ID of the private DNS zone of the VPC."
  sensitive   = false
  value       = "${element(concat(aws_route53_zone.private.*.zone_id, list("")), 0)}"
}

output "dns_resolvers" {
  description = "List of the private resolvers of the VPC."
  sensitive   = false
  value       = ["${aws_route53_zone.private.*.name_servers}"]
}

output "domain_name" {
  description = "The suffix domain name to use by default when resolving non Fully Qualified Domain Names."
  sensitive   = false
  value       = "${element(concat(aws_vpc_dhcp_options.main.*.domain_name, list("")), 0)}"
}

output "id" {
  description = "The ID of the VPC."
  sensitive   = false
  value       = "${aws_vpc.main.id}"
}

output "igw_id" {
  description = "The ID of the Internet Gateway."
  sensitive   = false
  value       = "${element(concat(aws_internet_gateway.main.*.id, list("")), 0)}"
}

output "ipv6_association_id" {
  description = "The association ID for the IPv6 CIDR block."
  sensitive   = false
  value       = "${aws_vpc.main.ipv6_association_id}"
}

output "ipv6_cidr_block" {
  description = "The IPv6 CIDR block."
  sensitive   = false
  value       = "${aws_vpc.main.ipv6_cidr_block}"
}

output "main_route_table_id" {
  description = "The ID of the main route table associated with this VPC."
  sensitive   = false
  value       = "${aws_vpc.main.main_route_table_id}"

}

output "name" {
  description = "The VPC name."
  sensitive = false
  value     = "${var.name}"
}

output "nat_eip" {
  description = "List of the NATs public IP addresses."
  sensitive   = false
  value       = ["${aws_eip.nat.*.public_ip}"]
}

output "nat_gw_id" {
  description = "List of the NATs."
  sensitive   = false
  value       = ["${aws_nat_gateway.main.*.id}"]
}

output "prefix" {
  description = "The VPC prefix."
  sensitive   = false
  value       = "${var.prefix}"
}

output "private_route_table_id" {
  description = "List of the private routing table IDs."
  sensitive   = false
  value       = ["${aws_route_table.private.*.id}"]
}

output "private_subnets" {
  description = "List of the private subnet IDs."
  sensitive   = false
  value       = ["${aws_subnet.private.*.id}"]
}

output "public_route_table_id" {
  description = "List of the public routing table IDs."
  sensitive   = false
  value       = ["${aws_route_table.public.*.id}"]
}

output "public_subnets" {
  description = "List of the public subnet IDs."
  sensitive   = false
  value       = ["${aws_subnet.public.*.id}"]
}

output "s3_endpoint_id" {
  description = "The ID of the S3 endpoint."
  sensitive   = false
  value       = "${element(concat(aws_vpc_endpoint.s3.*.id, list("")), 0)}"
}

output "s3_endpoint_state" {
  description = "The state of the VPC endpoint."
  sensitive   = false
  value       = "${element(concat(aws_vpc_endpoint.s3.*.state, list("")), 0)}"
}
