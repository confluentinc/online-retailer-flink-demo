

variable "confluent_cloud_api_key"{
    description = "Confluent Cloud API Key"
    type        = string
}

variable "confluent_cloud_api_secret"{
    description = "Confluent Cloud API Secret"
    type        = string     
}

variable "confluent_cloud_environment_id"{
    description = "Confluent Environment ID of the demo"
    type        = string     
}

variable "confluent_cloud_cluster_id"{
    description = "Confluent cluster ID of the demo"
    type        = string     
}

variable "demo_compute_pool_id"{
    description = "Confluent Flink compute pool ID of the demo"
    type        = string     
}

variable "confluent_cloud_service_account_id"{
    description = "Confluent service account ID of the demo"
    type        = string     
}

variable "cloud_region"{
  description = "AWS Cloud Region"
  type        = string
  default     = "us-west-2"    
}

variable "flink_management_api_key"{
  description = "Flink management API Key"
  type        = string
}

variable "flink_management_api_key_secret"{
  description = "Flink management secret"
  type        = string
}

variable "flink_statement_stopped"{
  description = "The boolean flag to control whether the running Flink Statement should be stopped."
  type        = bool
}


