#  Online Retailer Stream Processing Demo using Confluent for Apache Flink

This repository showcases a demo for an online retailer that leverages Confluent Cloud to process sales orders in real-time, compute sales trends, and pre-process data for advanced analytics in Amazon Athena and Snowflake.

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

## General Requirements

* **Confluent Cloud API Keys** - [Cloud API Keys](https://docs.confluent.io/cloud/current/security/authenticate/workload-identities/service-accounts/api-keys/overview.html#resource-scopes) with Organisation Admin permissions are needed to deploy the necessary Confluent resources.
* **Terraform (v1.9.5+)** - The demo resources is automatically created using [Terraform](https://www.terraform.io). Besides having Terraform installed locally, will need to provide your cloud provider credentials so Terraform can create and manage the resources for you.
* **AWS account** - This demo runs on AWS
* **Snowflake Account** -  Sign-up to Snowflake [here](https://signup.snowflake.com/).
* **AWS CLI** - Terraform script uses AWS CLI to manage AWS resources
* **Docker** - Make sure is Docker installed locally. If not installed, follow [this](https://docs.docker.com/desktop/)
* **Unix machine** - The Terraform script requires a Unix environment. If you're using a Windows machine, consider deploying an EC2 instance with CentOS and run the deployment steps from there.

## Deploy Demo

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

## Run the Demo
In this demo we will implement 3 use cases:
1. Use case 1 - [Low inventory stock alerts](#low-inventory-stock-alerts): Use Confluent Cloud for Apache Flink to compute low inventory stocks and use Snowflake Sink Connector to sink the data to Snowflake
2. Use case 2 - [Product Sales Aggregation](#product-sales-aggregation): Use Confluent Cloud for Apache Flink to clean and aggrgate Product Sales Data and sink the results to Snowflake
3. Use case 3 - [Daily Sales Trends](#daily-sales-trends): Use Confluent Cloud for Apache Flink for Payment Validation and compute daily sales trends. The results are stored in a topic that has Tableflow enabled - which materializes the topic as Iceberg data. We then use Amazon Athena for further Analysis.

### Low inventory stock alerts

![Architecture](./assets/usecase1.png)



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