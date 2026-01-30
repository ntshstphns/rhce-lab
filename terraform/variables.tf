# variables.tf

variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name tag prefix"
  type        = string
  default     = "rhce-lab"
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH into the environment (your home IP)"
  type        = string
  # No default - expected from TFC variable
}

variable "AWS_SSH_KEY" {
  description = "The NAME of the existing AWS Key Pair to use for instances"
  type        = string
  # No default - expected from TFC variable
}