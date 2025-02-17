variable "email" {
  description = "Your email to tag all AWS resources"
  type        = string
}


variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "shiftleft"
}

variable "cloud_region"{
  description = "AWS Cloud Region"
  type        = string
  default     = "us-west-2"    
}

variable "db_username"{
  description = "Postgres DB username"
  type        = string
  default     = "postgres"  
}

variable "db_password"{
  description = "Postgres DB password"
  type        = string
  default     = "Admin123456!!"  
}


variable "confluent_cloud_api_key"{
    description = "Confluent Cloud API Key"
    type        = string
}

variable "confluent_cloud_api_secret"{
    description = "Confluent Cloud API Secret"
    type        = string     
}

variable "data_warehouse" {
  description = "Type of data warehouse to use (either 'redshift' or 'snowflake')"
  type        = string
  default     = "redshift"
  validation {
    condition     = contains(["redshift", "snowflake"], var.data_warehouse)
    error_message = "The data_warehouse variable must be either 'redshift' or 'snowflake'."
  }
}

variable "snowflake_account" {
  description = "Snowflake account identifier"
  type        = string
  default     = "redshift_selected"
}

variable "snowflake_username" {
  description = "Snowflake username"
  type        = string
  default     = ""
}

variable "snowflake_password" {
  description = "Snowflake password"
  type        = string
  default     = ""
}

variable "local_architecture" {
  description = "The architecture of the local machine"
  type        = string
}

