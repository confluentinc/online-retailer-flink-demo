
# Real-Time Stream Processing Workshop
### Build a Data Streaming Platform with Confluent Cloud & Apache Flink

### 🎉👋 Welcome to GKO 2026! 

In this hands-on workshop, you'll build a real-time analytics platform for an online retailer using Confluent Cloud and Apache Flink.

![Architecture](./assets/HLD.png)

## What You'll Build

By the end of this workshop, you'll have:

- ✅ **Real-time customer data** streaming from PostgreSQL to Confluent Cloud
- ✅ **Live product analytics** using Flink SQL joins and aggregations
- ✅ **Apache Iceberg tables** with Tableflow for instant data lake integration
- ✅ **Data governance** with schema validation and field-level encryption
- ✅ **Analytics-ready datasets** in your data warehouse (Redshift or Snowflake)

**Time commitment:** 90 minutes total (45 min setup + 45 min labs)

## Prerequisites

Before starting, make sure you have:

| Requirement | Check |
|-------------|-------|
| **Confluent Cloud account** with [API Keys](https://docs.confluent.io/cloud/current/security/authenticate/workload-identities/service-accounts/api-keys/overview.html#resource-scopes) (Org Admin permissions) | [Sign up here](https://www.confluent.io/get-started/) |
| **AWS account** with credentials configured | `aws configure` or env variables |
| **Docker Desktop** installed and running | Docker must be logged in |
| **Terraform** installed | `brew install terraform` or [download](https://www.terraform.io/downloads) |
| **Confluent CLI** installed | `brew install confluent-cli` |

<details>
<summary>📦 Quick Install Commands</summary>

**macOS:**
```bash
brew install git terraform confluent-cli docker
aws configure  # Set up AWS credentials
```

**Windows (PowerShell):**
```powershell
winget install -e --id Git.Git
winget install -e --id HashiCorp.Terraform
winget install -e --id Docker.DockerDesktop
winget install -e --id Confluentinc.CLI
winget install -e --id Amazon.AWSCLI
aws configure  # Set up AWS credentials
```
</details>

---

> **💡 Pro Tip:** Use Chrome's split-screen view to have the instructions on one side and Confluent Cloud on the other!
<video src="https://github.com/user-attachments/assets/68395ba4-c12c-4daa-b71b-168e7d14bf33" controls autoplay loop muted inline width="50%">
</video>

## Setup (Allow 30-45 minutes)

### Step 1: Clone and Navigate

```bash
git clone https://github.com/confluentinc/online-retailer-flink-demo.git
cd online-retailer-flink-demo/terraform
```


### Step 2: Deploy Infrastructure

```bash
terraform init
terraform apply --auto-approve
```

☕ **Grab a coffee!** This takes 15-20 minutes to provision:
- Confluent Cloud environment with Kafka + Flink
- AWS RDS PostgreSQL database
- S3 buckets for data lake
- Redshift warehouse
- Schema Registry and Stream Governance

---

## Workshop Labs

Once deployment completes, start the hands-on labs:

### [**LAB 1: Customer360 & Product Sales Analytics**](./LAB1/LAB1-README.md)
Learn to join streaming data with Flink SQL, mask PII data, and create enriched customer profiles.

### [**LAB 2: Payment Processing & Tableflow**](./LAB2/LAB2-README.md)
Validate payments in real-time, compute daily trends, and materialize Kafka topics as Iceberg tables.

### [**LAB 3: Snowflake Integration** *(Snowflake users only)*](./LAB3/LAB3-README.md)
Connect Snowflake to S3 using IAM roles and query Iceberg data via Glue Data Catalog.

---

## Clean Up (Important!)

**Don't skip this!** Avoid unexpected charges by cleaning up when you're done.

### Step 1: Delete Connectors

Connectors created during the labs are not managed by Terraform and must be deleted manually.

**Option A: Delete via UI (Easiest)**

1. Go to [Confluent Cloud](https://confluent.cloud)
2. Select your environment (starts with `shiftleft-environment-...`)
3. Click **Connectors** in the left sidebar
4. For each connector you created:
   - Click on the connector name
   - Click **Settings** > **Delete**
   - Confirm deletion

**Option B: Delete via CLI**

First, find your IDs:
```bash
# List all environments to find your ENVIRONMENT_ID
confluent environment list

# Set your environment (use the ID from above)
confluent environment use <ENVIRONMENT_ID>

# List clusters to find your CLUSTER_ID
confluent kafka cluster list

# List all connectors to find CONNECTOR_IDs
confluent connect cluster list --cluster <CLUSTER_ID>
```

Then delete each connector:
```bash
confluent connect cluster delete <CONNECTOR_ID> \
  --cluster <CLUSTER_ID> \
  --environment <ENVIRONMENT_ID> \
  --force
```

### Step 2: Destroy Infrastructure

```bash
# From the terraform/ directory
./demo-destroy.sh        # macOS/Linux
demo-destroy.bat         # Windows
```

---

## Need Help?

- **Running into issues?** Check the [**Troubleshooting Guide**](./TROUBLESHOOTING.md) for common problems and solutions
- **During the workshop:** Raise your hand or ask in Slack
- **After the workshop:** Check the [video walkthrough](https://www.confluent.io/resources/demo/shift-left-dsp-demo/)
- **Issues or feedback:** [Open a GitHub issue](https://github.com/confluentinc/online-retailer-flink-demo/issues)

---

## Ready to Start?

👉 **[Begin LAB 1: Customer360 & Product Sales Analytics](./LAB1/LAB1-README.md)**

Let's build something awesome! 🚀
