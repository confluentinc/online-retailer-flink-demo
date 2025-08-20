email="jber@confluent.io"
confluent_cloud_api_key    = "AP5RNHOSYODFDDDA"
confluent_cloud_api_secret = "HpIGWcGnIObrotXiXrc6aXhC6rnoNSKNnJCTxQMB4neHvY62STupvJXBSlhsCsC+"

data_warehouse = "snowflake" #The value has to be snowflake or redshift


# The follwoing three variables are only needed if data_warehouse is set to "snowflake"
snowflake_account="confluentpartner1-jber_snowflake" #GET THIS FROM SNOWFLAKE Home Page --> Admin --> Accounts --> Copy the first part of the URL before .snowflake, it should look like this <organization_id-account_name>
snowflake_username="jber"
snowflake_password="2025 Snowflake Password"