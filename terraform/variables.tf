variable "email" {
  description = "Your email to tag all AWS resources"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "shiftleft"
}

variable "cloud_region" {
  description = "AWS Cloud Region"
  type        = string
  default     = "us-east-1"
}

variable "db_username" {
  description = "Postgres DB username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Postgres DB password"
  type        = string
  default     = "Admin123456!!"
}


variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
}
