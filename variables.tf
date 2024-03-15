variable "ami" {
  type        = string
  description = "Which AMI should we use?"
}

variable "instance_type" {
  type    = string
  default = "t3a.2xlarge"

  // to fail, use
  // default     = "t3a.2xlarge"

  description = "How big of an instance should we create?"
}

variable "aws-region" {
  type    = string
  default = "eu-west-2"
}

variable "vpc_name" {
  type    = string
  default = "demo"
}

variable "route53_zone" {
  type    = string
  default = "lucy-davinhart.sbx.hashidemos.io"
}
