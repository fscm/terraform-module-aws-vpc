# VPC Terraform Module

A terraform module to create a VPC in AWS.

## Prerequisites

Terraform and AWS Command Line Interface tools need to be installed on your
local computer.

### Terraform

Terraform version 0.10.3 or higher is required.

Terraform installation instructions can be found
[here](https://www.terraform.io/intro/getting-started/install.html).

### AWS Command Line Interface

AWS Command Line Interface installation instructions can be found [here](http://docs.aws.amazon.com/cli/latest/userguide/installing.html).

## Module Input Variables

- `cidr` - The CIDR block for the VPC. *[default value: '10.0.0.0/16']*
- `domain_name` - The domain name to use by default when resolving non Fully Qualified Domain Name of the VPC instance(s). If set to anything other than an empty string it will create a private DNS zone for that domain. *[default value: '']*
- `domain_name_servers` - List of name servers to be added to the '/etc/resolv.conf' file of the VPC instance(s). *[default value: '["AmazonProvidedDNS"]']*
- `enable_dns_hostnames` - Should be true if you want to have custom DNS hostnames within the VPC. *[default value: true]*
- `enable_dns_support` - Should be true if you want to have DNS support within the VPC. *[default value: true]*
- `enable_s3_endpoint` - Should be true if you want to provision an S3 endpoint within the VPC. *[default value: false]*
- `instance_tenancy` - The tenancy option for instances launched into the VPC. *[default value: 'default']*
- `name` - The name for the VPC. *[default value: 'default']*
- `prefix` - A prefix to prepend to the VPC name. *[default value: '']*
- `private_subnets` - List of private subnet CIDRs for the VPC (e.g.: ['10.0.0.128/25']). *[default value: []]*
- `public_subnets` - List of public subnet CIDRs for this VPC (e.g.: ['10.0.0.0/25']). *[default value: []]*
- `private_subnets_amount` - Number of private subnet to create (only if `private_subnets` and `public_subnets` are both empty). *[default value: '1']*
- `public_subnets_amount` - Number of public subnet to create (only if `private_subnets` and `public_subnets` are both empty. *[default value: '1']*
- `single_nat_gateway` - Should be true if you want to have only one NAT Gateway for all subnets, false if you want to have one NAT Gateway per subnet. *[default value: true]*

## Usage

Example with custom defined subnets:

```hcl
module "my_vpc" {
  source          = "github.com/fscm/terraform-module-aws-vpc"
  cidr            = "10.0.0.0/16"
  domain          = "mydomain.tld"
  name            = "vpc"
  prefix          = "mycompany-"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}
```

Example with automatically generated subnets:

```hcl
module "my_vpc" {
  source                 = "github.com/fscm/terraform-module-aws-vpc"
  cidr                   = "10.0.0.0/16"
  domain                 = "mydomain.tld"
  name                   = "vpc"
  prefix                 = "mycompany-"
  private_subnets_amount = "3"
  public_subnets_amount  = "3"
}
```

## Outputs

- `cidr` - **[type: string]** The CIDR block of the VPC.
- `default_network_acl_id` - **[type: string]** The ID of the network ACL created by default on VPC creation.
- `default_route_table_id` - **[type: string]** The ID of the route table created by default on VPC creation.
- `default_security_group_id` - **[type: string]** The ID of the security group created by default on VPC creation.
- `dns_zone_id` - **[type: string]** The ID of the private DNS zone of the VPC.
- `dns_resolvers` - **[type: list]** List of the private resolvers of the VPC.
- `domain_name` - **[type: string]** The suffix domain name to use by default when resolving non Fully Qualified Domain Names.
- `id` - **[type: string]** The ID of the VPC.
- `igw_id` - **[type: string]** The ID of the Internet Gateway.
- `ipv6_association_id` - **[type: string]** The association ID for the IPv6 CIDR block.
- `ipv6_cidr_block` - **[type: string]** The IPv6 CIDR block.
- `main_route_table_id` - **[type: string]** The ID of the main route table associated with this VPC.
- `name` - **[type: string]** The VPC name.
- `nat_eip` - **[type: list]** List of the NATs public IP addresses.
- `nat_gw_id`- **[type: list]** List of the NATs.
- `prefix` - **[type: string]** The VPC prefix.
- `private_route_table_id` - **[type: list]** List of the private routing table IDs.
- `private_subnets` - **[type: list]** List of the private subnet IDs.
- `public_route_table_id` - **[type: list]** List of the public routing table IDs.
- `public_subnets` - **[type: list]** List of the public subnet IDs.
- `s3_endpoint_id` - **[type: string]** The ID of the S3 endpoint.
- `s3_endpoint_state` - **[type: string]** The state of the VPC endpoint.

## VPC Access

This modules provides a security group that will allow access between the VPC
instances on all ports and protocols.

To obtain the ID of that group use the value of the output variable
`default_security_group_id`.

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request

Please read the [CONTRIBUTING.md](CONTRIBUTING.md) file for more details on how
to contribute to this project.

## Versioning

This project uses [SemVer](http://semver.org/) for versioning. For the versions
available, see the [tags on this repository](https://github.com/fscm/terraform-module-aws-vpc/tags).

## Authors

* **Frederico Martins** - [fscm](https://github.com/fscm)

See also the list of [contributors](https://github.com/fscm/terraform-module-aws-vpc/contributors)
who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE)
file for details
