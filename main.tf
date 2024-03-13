terraform {

  /*
  cloud {
    organization = "fancycorp"

    workspaces {
      name = "demo-webserver"
    }
  }
*/

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      Name      = "StrawbTest - ${terraform.workspace}"
      Owner     = "lucy.davinhart@hashicorp.com"
      Purpose   = "Terraform Demo"
      TTL       = "24h"
      Terraform = "true"
      Source    = "https://github.com/FancyCorp-Demo/tf-workspace-aws-webserver/tree/local-dev/"
      Workspace = terraform.workspace
    }
  }
  region = var.aws-region
}




# As this is now a TF module, we can't assume eu-west-2
# So get AZs and region dynamically
data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_region" "current" {}

# Create a VPC
# While we could define each of the required resources manually...
# no need to re-invent the wheel when a really good module exists already

module "vpc" {
  # https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest 
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = var.vpc_name
  cidr = "10.0.0.0/16"

  azs            = data.aws_availability_zones.available.names[*]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# Allow us to easily connect to the EC2 instance with AWS EC2 Connect

data "aws_ip_ranges" "ec2_instance_connect" {
  regions  = [data.aws_region.current.name]
  services = ["ec2_instance_connect"]
}

resource "aws_security_group" "ec2_instance_connect" {
  name        = "ec2_instance_connect"
  description = "Allow EC2 Instance Connect to access this host"

  vpc_id = module.vpc.vpc_id

  ingress {
    from_port        = "22"
    to_port          = "22"
    protocol         = "tcp"
    cidr_blocks      = data.aws_ip_ranges.ec2_instance_connect.cidr_blocks
    ipv6_cidr_blocks = data.aws_ip_ranges.ec2_instance_connect.ipv6_cidr_blocks
  }

  tags = {
    CreateDate = data.aws_ip_ranges.ec2_instance_connect.create_date
    SyncToken  = data.aws_ip_ranges.ec2_instance_connect.sync_token
  }
}

# Allow inbound HTTP access on standard port
# In Production, you'd want to configure SSL etc.
# potentially run behind a load balancer of some kind.
# you know, usual production stuff.
#
# But for this demo, this works fine.
resource "aws_security_group" "inbound_http" {
  name        = "inbound_http"
  description = "Allow inbound HTTP access"

  vpc_id = module.vpc.vpc_id

  ingress {
    from_port        = "80"
    to_port          = "80"
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}



# Now create the EC2 instance
resource "aws_instance" "web" {
  ami = var.ami

  associate_public_ip_address = true


  instance_type = var.instance_type
  vpc_security_group_ids = [
    aws_security_group.ec2_instance_connect.id,
    aws_security_group.inbound_http.id,
  ]

  subnet_id = module.vpc.public_subnets[0]

  lifecycle {
    create_before_destroy = true
  }
}



# And a Route53 Record
data "aws_route53_zone" "zone" {
  name = var.route53_zone
}
resource "aws_route53_record" "webserver" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = aws_instance.web.id
  type    = "A"
  ttl     = 300
  records = [aws_instance.web.public_ip]
}
