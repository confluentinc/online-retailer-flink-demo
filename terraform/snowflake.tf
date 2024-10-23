resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
}

# Define local variables to strip PEM headers and footers
locals {
  # Remove the PEM headers and footers for the private key
  private_key_no_headers = replace(replace(tls_private_key.rsa_key.private_key_pem, "-----BEGIN RSA PRIVATE KEY-----", ""), "-----END RSA PRIVATE KEY-----", "")
  
  # Remove the PEM headers and footers for the public key
  public_key_no_headers = replace(replace(tls_private_key.rsa_key.public_key_pem, "-----BEGIN PUBLIC KEY-----", ""), "-----END PUBLIC KEY-----", "")
}

# Create the Kafka connector role
resource "snowflake_account_role" "kafka_connector_role" {
  name = "kafka_connector_role"
}


resource "snowflake_user" "confluent_connector_user" {
  name                 = "confluent"
  default_role         =  snowflake_account_role.kafka_connector_role.name
  rsa_public_key       = local.public_key_no_headers
}

# Create the database
resource "snowflake_database" "production_db" {
  name = "PRODUCTION"
}

# Create the schema
resource "snowflake_schema" "production_schema" {
  database = snowflake_database.production_db.name
  name     = "PUBLIC"
}

# list of privileges
resource "snowflake_grant_privileges_to_account_role" "schema_permissions" {
  privileges        = ["USAGE", "CREATE TABLE", "CREATE STAGE", "CREATE PIPE"]
  account_role_name = snowflake_account_role.kafka_connector_role.name
  on_schema {
    schema_name = snowflake_schema.production_schema.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "db_permissions" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.kafka_connector_role.name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.production_db.name
  }
}

# Grant the kafka_connector_role to the user
resource "snowflake_grant_account_role" "grant_role_to_user" {
  role_name = snowflake_account_role.kafka_connector_role.name
  user_name     = snowflake_user.confluent_connector_user.name
}

resource "snowflake_grant_account_role" "g" {
  role_name        = snowflake_account_role.kafka_connector_role.name
  parent_role_name = "ACCOUNTADMIN"
}