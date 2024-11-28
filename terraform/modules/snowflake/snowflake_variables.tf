variable "snowflake_account" {
  description = "Snowflake account identifier"
  type        = string
  default     = null
}

variable "snowflake_username" {
  description = "Snowflake username"
  type        = string
  default     = null
}

variable "snowflake_password" {
  description = "Snowflake password"
  type        = string
  default     = null
}

variable "public_key_no_headers" {
  description = "Public Key"
  type        = string
}
