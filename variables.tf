variable "cidr_block" {
  description = "VPC CIDR Block"
  type        = string
  default     = "172.16.0.0/16"
}

variable "region" {
  description = "VPC Region"
  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "Instance Type"
  type        = string
  default     = "t2.micro"
}