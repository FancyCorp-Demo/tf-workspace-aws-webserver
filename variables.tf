variable "ami" {
  type        = string
  description = "Which AMI should we use?"
}

variable "instance_type" {
  type        = string
  default     = "t3a.nano"
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
