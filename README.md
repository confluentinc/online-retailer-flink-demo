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
├── Code                                  <-- Directory that holds demo code and dockerfile
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
│   ├── demo-destroy.sh                   <-- Shell script to destroy demo infrastructure
│   ├── demo-provision.sh                 <-- Shell script to provision demo infrastructure
├── Usecase 1                             <-- Directory that holds usecase 1 instructions and screenshots
├── Usecase 2                             <-- Directory that holds usecase 2 instructions and screenshots
├── Usecase 3                             <-- Directory that holds usecase 3 instructions and screenshots
└── README.md
```

## Demo Video

This is a [video](https://www.confluent.io/resources/demo/shift-left-dsp-demo/) showcases how to run the demo. To deploy the demo follow this repo.


## General Requirements

* **Confluent Cloud API Keys** - [Cloud resource management API Keys](https://docs.confluent.io/cloud/current/security/authenticate/workload-identities/service-accounts/api-keys/overview.html#resource-scopes) with Organisation Admin permissions are needed by Terraform to deploy the necessary Confluent resources.
* **Terraform (v1.9.5+)** - The demo resources is automatically created using [Terraform](https://www.terraform.io). Besides having Terraform installed locally, will need to provide your cloud provider credentials so Terraform can create and manage the resources for you.
* **AWS account** - This demo runs on AWS
* **Snowflake Account** -  Sign-up to Snowflake [here](https://signup.snowflake.com/).
* **AWS CLI** - Terraform script uses AWS CLI to manage AWS resources
* **Docker** - Make sure is Docker installed locally. If not installed, follow [this](https://docs.docker.com/desktop/)
* **PSQL** - Make sure is psql is installed locally.
* **Unix machine** - The Terraform script requires a Unix environment. If you're using a Windows machine, consider deploying an EC2 instance with CentOS and run the deployment steps from there.

## Setup

> Estimated time: 25 mins

1. Clone the repo onto your local development machine using `git clone https://github.com/confluentinc/online-retailer-flink-demo`.
2. Change directory to demo repository and terraform directory.

```
cd online-retailer-flink-demo/terraform

```
3. Update the ```terraform.tfvars```:

4. Run the following script to provision demo infrastructure

```
chmod +x ./demo-provision.sh
./demo-provision.sh
```

>Note: The terraform script will take around 20 minutes to deploy.

## Demo
> Estimated time: 20 minutes


In this demo we will implement 3 use cases:
1. [Usecase 1 - Low inventory stock alerts](./Usecase1/USECASE1-README.md): Use Confluent Cloud for Apache Flink to compute low inventory stocks and use Snowflake Sink Connector to sink the data to Snowflake
2. [Usecase 2 - Product Sales Aggregation](./Usecase2/USECASE2-README.md): Use Confluent Cloud for Apache Flink to clean and aggrgate Product Sales Data and sink the results to Snowflake
3. [Usecase 3 - Daily Sales Trends](./Usecase3/USECASE3-README.md): Use Confluent Cloud for Apache Flink for Payment Validation and compute daily sales trends. The results are stored in a topic that has Tableflow enabled - which materializes the topic as Iceberg data. We then use Amazon Athena for further Analysis.

## Next

[Usecase 1: Low inventory stock alerts](./Usecase1/USECASE1-README.md)

## Clean-up
Once you are finished with this demo, remember to destroy the resources you created, to avoid incurring in charges. You can always spin it up again anytime you want.

First delete the Snowflake connector as it was created outside Terraform:

```
confluent connect cluster delete <CONNECTOR_ID> --cluster <CLUSTER_ID> --environment <ENVIRONMENT_ID> --force
```

To destroy all the resources created run the command below from the ```terraform``` directory:

```
chmod +x ./demo-destroy.sh
./demo-destroy.sh

```
> **Note: If you run terraform destroy instead of the provided shell script, the ECR repositories in AWS will not be deleted.**

