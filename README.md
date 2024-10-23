#  Online Retailer Stream Processing Demo using Confluent for Apache Flink

This repository showcases a demo for an online retailer that leverages Confluent Cloud to process sales orders in real-time, compute sales trends, and pre-process data for advanced analytics in Amazon Athena and Snowflake. 

It shows harness the power of a Data Streaming Platform (DSP) to clean and govern data at the time it is created, and deliver fresh trustworthy data to your data warehouse and data lake to maximize the ROI of your Snowflake

We use Terraform to deploy all the necessary resources. The script deploys the following:

1. Confluent Cloud Infrastructure components:
   1. Environment
   2. Cluster
   3. Topics and Schemas
   4. RBAC role-bindings
   5. Debezium CDC Connector and Data Qaulity Rules.
2. AWS Infrastructure components:
   1. Amazon RDS for PostgreSQL Database - holds information about Product, Orders and Customers
   2. AWS KMS Semmetric key - used for Client Side Field Level Encryption
   3. Two Amazon ECS Services
      * DB Feeder to populate Postgres DB
      * Payments Java Application
3. Snowflake Infrastructure components:
   1. Database and Schema
   2. User with 2048 Public and Private key and the associated Role

```bash
├── assets                                <-- Directory that holds demo assests
│   ├── usecase1.png                      <-- Architecture Diagram for use case 1
│   ├── usecase2.png                      <-- Architecture Diagram for use case 2
│   ├── usecase3.png                      <-- Architecture Diagram for use case 3
└── Code                                  <-- Directory that holds demo code and dockerfile
│   ├── payments-app                      <-- Payments App code and dockerfile
│   ├── postgres-data-feeder              <-- DB Feeder code and dockerfile
└── terraform                             <-- Demo terraform script and artifacts
│   ├── aws.tf                            <-- Terraform for AWS resources
│   ├── confluent.tf                      <-- Terraform for Confluent resources
│   ├── snowflake.tf                      <-- Terraform for Snowflake resources
│   ├── apps.tf                           <-- Terraform for the 2 AWS ECS Services (payments and DB feeder) 
│   ├── outputs.tf                        <-- Terraform output file
│   ├── providors.tf                      <-- Terraform providors file
│   ├── variables.tf                      <-- Terraform variables file
│   ├── terraform.tfvars                  <-- UPDATE THIS FILE TO DEFINE YOUR VARIABLES
│   ├── schemas                           <-- Directory that holds payments topic avro schema
└── README.md
```

## Demo Video

This is a [video](https://www.confluent.io/resources/demo/shift-left-dsp-demo/) showcases how to run the demo. To deploy the demo follow this repo.


## General Requirements

* **Confluent Cloud API Keys** - [Cloud API Keys](https://docs.confluent.io/cloud/current/security/authenticate/workload-identities/service-accounts/api-keys/overview.html#resource-scopes) with Organisation Admin permissions are needed to deploy the necessary Confluent resources.
* **Terraform (v1.9.5+)** - The demo resources is automatically created using [Terraform](https://www.terraform.io). Besides having Terraform installed locally, will need to provide your cloud provider credentials so Terraform can create and manage the resources for you.
* **AWS account** - This demo runs on AWS
* **Snowflake Account** -  Sign-up to Snowflake [here](https://signup.snowflake.com/).
* **AWS CLI** - Terraform script uses AWS CLI to manage AWS resources
* **Docker** - Make sure is Docker installed locally. If not installed, follow [this](https://docs.docker.com/desktop/)
* **Unix machine** - The Terraform script requires a Unix environment. If you're using a Windows machine, consider deploying an EC2 instance with CentOS and run the deployment steps from there.

## Setup

> Estimated time: 25 mins

1. Clone the repo onto your local development machine using `git clone https://github.com/confluentinc/online-retailer-flink-demo`.
2. Change directory to demo repository and terraform directory.

```
cd online-retailer-flink-demo/terraform

```
3. Update the ```terraform.tfvars```:

4. Use Terraform CLI to deploy solution

```
terraform init

terraform plan

terraform apply --auto-approve

```

>Note: The terraform script will take around 20 minutes to deploy.

## Demo
> Estimated time 25 minutes
>

In this demo we will implement 3 use cases:
1. Use case 1 - [Low inventory stock alerts](#low-inventory-stock-alerts): Use Confluent Cloud for Apache Flink to compute low inventory stocks and use Snowflake Sink Connector to sink the data to Snowflake
2. Use case 2 - [Product Sales Aggregation](#product-sales-aggregation): Use Confluent Cloud for Apache Flink to clean and aggrgate Product Sales Data and sink the results to Snowflake
3. Use case 3 - [Daily Sales Trends](#daily-sales-trends): Use Confluent Cloud for Apache Flink for Payment Validation and compute daily sales trends. The results are stored in a topic that has Tableflow enabled - which materializes the topic as Iceberg data. We then use Amazon Athena for further Analysis.

### Low inventory stock alerts


![Architecture](./assets/usecase1.png)

1. We are using Confluent Cloud CDC Debezium connector to source data from the Postgres DB to Confluent Cloud. Navigate to [Connectors UI](https://confluent.cloud/go/connectors) in Confluent Cloud and select the demo environment and cluster. They both have the same prefix, by defualt they start with ```shiftleft```.
2. Click on the Connector then **Settings**. Under transforms you will find the SMT used to mask PII information before sending the data to Confluent Cloud. This SMT replaces to email field value with ```****```.
   ![Connector SMT](./assets/usecase1_smt.png)
3. Make sure that the SMT is working by showing the output events in the Customer Topic.
   
   ![Masked Message](./assets/usecase1_msg.png)

4. Navigate to [Flink UI](https://confluent.cloud/go/flink) in Confluent Cloud and select the demo environment
5. Click on **Open SQL Workspace**.
6. On the top right corner of your workspace select the cluster as your database.
7. You will use the code editor to query existing Flink tables (Kafka topics) and to write new queries.
8. In Confluent Cloud, every topic is accessible as an Apache Flink table and every Apache Flink table is available as a topic. Therefore we can start querying Apache Flink SQL. Run the below statement to show all tables in the cluster.
   ```
   SHOW TABLES;
   ```
9.  Create ```low_stock_alerts``` table.
   ```
   CREATE TABLE low_stock_alerts (
    productid INT,
    productname STRING,
    stock INT,
    alert_message STRING
   ); 
   ```
10. Run the Apache Flink SQL Statement below to find out low quantity stocks
   ```
    SELECT
        productid,
        productname,
        stock,
        'Low stock: Quantity below 50!' AS alert_message
    FROM
        `shiftleft.public.products`
    WHERE
        stock < 50;

   ```
11. The output will run continously run until terminated, to materialiaze the data into the output topic we need to use ``` INSERT INTO SELECT ```.
   ```
   INSERT INTO low_stock_alerts
    SELECT
        productid,
        productname,
        stock,
        'Low stock: Quantity below 50!' AS alert_message
    FROM
        `shiftleft.public.products`
    WHERE
        stock < 50;

   ```

12. The output table is a Kafka topic with an avro schema that holds stocks that are below 50 in the inventory. 
13. Now let's ingest data from ```low_stock_alerts``` topic to Snowflake using the Confluent Cloud Snowflake Sink Connector. In the [Connectors UI](https://confluent.cloud/go/connectors), add a new Snowflake Sink Connector.
14.  Choose ```low_stock_alerts``` topic and click **Continue**
15.  Enter Confluent Cluster credentials, you can use API Keys generated by Terraform
     1.   In CMD run ```terraform output resource-ids``` you will find the API Keys in a section that looks like this:
        ```
        Service Accounts and their Kafka API Keys (API Keys inherit the permissions granted to the owner):
            shiftleft-app-manager-d217a8e3:                     sa-*****
            shiftleft-app-manager-d217a8e3's Kafka API Key:     "SYAKE*****"
            shiftleft-app-manager-d217a8e3's Kafka API Secret:  "rn7Y392xM49c******"
        ```
16. Enter Snowflake details
    1.  **Connection URL**: Get it under Admin --> Accounts in (Snowflake Console)[https://app.snowflake.com/]. It should look like this: *https://<snowflake_locator>.<cloud_region>.aws.snowflakecomputing.com*
    2.  **Connection username**: ```confluent```
    3.  **Private Key**: In CMD run ```terraform output resource-ids``` and copy the PrivateKey from there.
    4.  **Database name**: ```PRODUCTION```
    5.  **Schema name**: ```PUBLIC```
    ![Masked Message](./assets/usecase1_sf.png)

17. Choose ```AVRO``` as **Input Kafka record value format** and ```SNOWPIPE``` as **Snowflake Connection**. Then follow the the wizard to create the connector.
    > Note: The connector will take less than a minute to run
18. 



### Product Sales Aggregation

![Architecture](./assets/usecase2.png)


### Daily Sales Trends

![Architecture](./assets/usecase3.png)




## Clean-up
Once you are finished with this demo, remember to destroy the resources you created, to avoid incurring in charges. You can always spin it up again anytime you want.

To destroy all the resources created run the command below from the ```terraform``` directory:

```
./demo-destroy.sh

```
> **Note: If you run terraform destroy instead of the provided shell script, the ECR repositories in AWS will not be deleted.**