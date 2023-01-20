# Use https://www.terraform.io/cloud for our State
terraform {
  cloud {
    organization = "fancycorp"

    workspaces {
      tags = ["webserver", "platform:aws"]
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    doormat = {
      source  = "doormat.hashicorp.services/hashicorp-security/doormat"
      version = "~> 0.0.3"
    }
  }
}

variable "aws-account-number" {
  type = string
}

variable "aws-region" {
  type    = string
  default = "eu-west-2"
}


# Internal Experimental HashiCorp Provider
# Essentially a wrapper around Vault dynamic AWS creds
provider "doormat" {}
data "doormat_aws_credentials" "creds" {
  role_arn = "arn:aws:iam::${var.aws-account-number}:role/strawb-tfc-fancycorp-${terraform.workspace}"
}

# We will be spinning up resources in AWS
# Define the AWS provider, and add tags that will propagate to all resources
#
# Credentials not defined here. Get them with Doormat:
#
provider "aws" {
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token

  default_tags {
    tags = {
      Name      = "StrawbTest - ${terraform.workspace}"
      Owner     = "lucy.davinhart@hashicorp.com"
      Purpose   = "Terraform TFC Demo Org (FancyCorp)"
      TTL       = "24h"
      Terraform = "true"
      Source    = "https://github.com/FancyCorp-Demo/tf-workspace-aws-webserver"
      Workspace = terraform.workspace
    }
  }
  region = var.aws-region
}

module "webserver" {
  source  = "app.terraform.io/fancycorp/webserver/aws"
  version = "<= 2.0.0"

  packer_bucket_name = var.packer_bucket_name
  packer_channel     = var.packer_channel

  instance_type = "t3.2xlarge"
}

