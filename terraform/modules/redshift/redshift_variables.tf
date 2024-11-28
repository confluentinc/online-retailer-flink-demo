variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "shiftleft"
}

variable "vpc_id" {
  description = "VPC ID for the Redshift cluster"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the Redshift cluster"
  type        = string
}

variable "random_id" {
  description = "Random id suffix"
  type        = string
}

