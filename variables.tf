#
# Variables for the VPC terraform module.
#
# Copyright 2016-2020, Frederico Martins
#   Author: Frederico Martins <http://github.com/fscm>
#
# SPDX-License-Identifier: MIT
#
# This program is free software. You can use it and/or modify it under the
# terms of the MIT License.
#

variable "cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
  type        = "string"
}

variable "domain_name" {
  description = "The domain name to use by default when resolving non Fully Qualified Domain Name of the VPC instance(s)."
  default     = ""
  type        = "string"
}

variable "domain_name_servers" {
  description = "List of name servers to configure in '/etc/resolv.conf'."
  default     = ["AmazonProvidedDNS"]
  type        = "list"
}

variable "enable_dns_hostnames" {
  description = "Should be true if you want to have custom DNS hostnames within the VPC."
  default     = true
  type        = "string"
}

variable "enable_dns_support" {
  description = "Should be true if you want to have DNS support whitin the VPC."
  default     = true
  type        = "string"
}

variable "enable_s3_endpoint" {
  description = "Should be true if you want to provision an S3 endpoint within the VPC."
  default     = false
  type        = "string"
}

variable "instance_tenancy" {
  description = "The tenancy option for instances launched into the VPC."
  default     = "default"
  type        = "string"

}

variable "name" {
  description = "The name for the VPC."
  default     = "default"
  type        = "string"
}

variable "prefix" {
  description = "A prefix to prepend to the VPC name."
  default     = ""
  type        = "string"
}

variable "private_subnets" {
  description = "List of private subnet CIDRs for the VPC (e.g.: ['10.0.0.128/25'])."
  default     = []
  type        = "list"
}

variable "private_subnets_amount" {
  description = "Number of private subnet to create (only if 'private_subnets' is empty)."
  default     = "1"
  type        = "string"
}

variable "public_subnets" {
  description = "List of public subnet CIDRs for this VPC (e.g.: ['10.0.0.0/25'])."
  default     = []
  type        = "list"
}

variable "public_subnets_amount" {
  description = "Number of public subnet to create (only if 'public_subnets' is empty)."
  default     = "1"
  type        = "string"
}

variable "single_nat_gateway" {
  description = "Should be true if you want to have only one NAT Gateway for all subnets, false if you want to have one NAT Gateway per subnet."
  default     = true
  type        = "string"
}
