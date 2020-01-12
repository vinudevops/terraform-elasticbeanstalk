variable "aws_region" {}
variable "aws_profile" {}
variable "sb_cidr" {}
variable "sb_sbn_public_cidr" {}
variable "sb_sbn_public2_cidr" {}
variable "sb_sbn_private_cidr" {}

variable "sb_sbn_private2_cidr" {}

variable "eb_solution_stack_name" {
  type    = "string"
  default = "64bit Amazon Linux 2018.03 v4.11.0 running Node.js"
  description = "The Elastic Beanstalk solution stack name"
}
variable "SSH_PUBLIC_KEY" {}
variable "rds2_cidr" {}
variable "rds1_cidr" {}
