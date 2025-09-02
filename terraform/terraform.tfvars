email                      = "<YOUR_EMAIL>"
confluent_cloud_api_key    = "<CONFLUENT_CLOUD_API_KEY>"
confluent_cloud_api_secret = "<CONFLUENT_CLOUD_API_SECRET>"

data_warehouse = "<redshift or snowflake>" #The value has to be snowflake or redshift
cloud_region   = "us-east-2"

# The follwoing three variables are only needed if data_warehouse is set to "snowflake"
snowflake_account  = "<SNOWFLAKE_ACCOUNT_NUMBER>" #GET THIS FROM SNOWFLAKE Home Page --> Admin --> Accounts --> Copy the first part of the URL before .snowflake, it should look like this <organization_id-account_name>
snowflake_username = "<SNOWFLAKE_USERNAME>"
snowflake_password = "<SNOWFLAKE_PASSWORD>"
