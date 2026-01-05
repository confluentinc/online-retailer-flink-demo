
## Payment Validation and Tableflow Deep Dive

In this lab, we'll use Confluent Cloud and Apache Flink to validate payments, create completed orders, and then explore Tableflow's capabilities for making streaming data analytics-ready. You'll learn how Tableflow converts Kafka topics into Apache Iceberg tables with zero code, enabling seamless querying from multiple analytics engines.

[Tableflow](https://www.confluent.io/product/tableflow/) eliminates the need for complex ETL pipelines by automatically converting topics into Iceberg tables. It handles schema mapping, evolution, compaction, and optimization—all managed by Confluent's infrastructure.

![Architecture](./assets/LAB2.png)

---

## Part 1: Payment Processing with Flink

### Payment Deduplication

Before joining payment and order streams, we need to ensure there are no duplicate payments.

1. Check for duplicates in the `payments` table:
   ```sql
   SELECT * FROM
   ( SELECT order_id, amount, count(*) total
    FROM `payments`
    GROUP BY order_id, amount )
   WHERE total > 1;
   ```
   If this query returns results, duplicates exist.

2. Create a deduplicated payments table:
   ```sql
   SET 'client.statement-name' = 'unique-payments-maintenance';
   SET 'sql.state-ttl' = '1 hour';

   CREATE TABLE unique_payments (
   order_id INT NOT NULL,
   product_id INT,
   customer_id INT,
   confirmation_code STRING,
   cc_number STRING,
   expiration STRING,
   amount DOUBLE,
   ts TIMESTAMP_LTZ(3),
   WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
   )
   AS SELECT
   COALESCE(order_id, 0) AS order_id,
   product_id,
   customer_id,
   confirmation_code,
   cc_number,
   expiration,
   amount,
   ts
   FROM (
   SELECT *,
            ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY ts ASC) AS rownum
   FROM payments
   )
   WHERE rownum = 1;
   ```

3. Update watermarks for both payment tables:
   ```sql
   ALTER TABLE payments
   MODIFY WATERMARK FOR ts AS ts;
   ```
   ```sql
   ALTER TABLE unique_payments
   MODIFY WATERMARK FOR ts AS ts;
   ```

4. Validate deduplication worked:
   ```sql
   SELECT order_id, COUNT(*) AS count_total
   FROM `unique_payments`
   GROUP BY order_id
   HAVING COUNT(*) > 1;
   ```
   This should return zero results.

---

### Using Interval Joins to Create Completed Orders

Now we'll filter out orders without valid payment within 96 hours using Flink's interval join capability.

1. Create the `completed_orders` table:
   ```sql
   SET 'client.statement-name' = 'completed-orders-materializer';
   CREATE TABLE completed_orders (
      order_id INT,
      amount DOUBLE,
      confirmation_code STRING,
      ts TIMESTAMP_LTZ(3),
      WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
   ) AS
   SELECT
      pymt.order_id,
      pymt.amount,
      pymt.confirmation_code,
      pymt.ts
   FROM unique_payments pymt, `shiftleft.public.orders` ord
   WHERE pymt.order_id = ord.orderid
   AND orderdate BETWEEN pymt.ts - INTERVAL '96' HOUR AND pymt.ts;
   ```

This join ensures we only capture orders with payments received within the valid time window, creating a high-quality data product for analytics.

---

## Part 2: Tableflow Deep Dive

Now that we have clean, validated data products from Flink, we'll make them analytics-ready using Tableflow. Instead of writing complex connectors or ETL jobs, Tableflow automatically materializes topics as Iceberg tables.

### Setting Up Tableflow Infrastructure

First, we'll configure the storage and catalog integrations that Tableflow will use.

#### Configure Custom Storage (S3)

> **Important:** For Lab 3 compatibility, you must use your own S3 storage (not Confluent Managed Storage).

1. Navigate to the Tableflow main page: **Environments > {Your Environment} > Clusters > {Your Cluster} > Tableflow**

   ![Navigate to tableflow](assets/navigate-to-tableflow.gif)

2. You should see a **Storage Provider Integration** already configured by Terraform. This integration allows Confluent to write Iceberg data to your S3 bucket.

#### Configure Glue Data Catalog Integration

Now we'll connect Tableflow to AWS Glue Data Catalog so our Iceberg tables are discoverable by Athena and other query engines.

1. In the Tableflow page, scroll to **External Catalog Integrations** and click **+ Add integration**

2. Configure the integration:
   * **Integration type:** AWS Glue
   * **Name:** `my-glue-integration`
   * **Supported format:** Iceberg
   * Click **Continue**

   ![Set up Glue Integration](assets/set-up-glue-integration.png)

3. Select the provider integration created by Terraform (you can find it in `terraform output resource-ids`)

4. Click **Continue and Launch**

5. Wait for the status to change from **Pending** to **Connected**

   ![Catalog Connected](assets/catalog-connected.png)

---

### Enabling Tableflow on Multiple Tables

Let's enable Tableflow on three different data products to demonstrate its versatility.

#### 1. Enable Tableflow on `completed_orders`

1. Navigate to the [`completed_orders`](https://confluent.cloud/go/topics) topic
2. Click **Enable Tableflow** > **Configure Custom Storage**
3. Select your provider integration and S3 bucket (format: `shiftleft-tableflow-bucket-...`)
4. Click **Continue** and **Launch**

   ![Enable Tableflow on topic](./assets/LAB2_enable_tableflow_custom_storage.png)

#### 2. Enable Tableflow on `product_sales`

Repeat the same process for the `product_sales` topic created in Lab 1:

1. Navigate to the [`product_sales`](https://confluent.cloud/go/topics) topic
2. Click **Enable Tableflow** > **Configure Custom Storage**
3. Use the same provider integration and S3 bucket
4. Click **Continue** and **Launch**

#### 3. Enable Tableflow on `thirty_day_customer_snapshot`

Repeat once more for the customer snapshot:

1. Navigate to the [`thirty_day_customer_snapshot`](https://confluent.cloud/go/topics) topic
2. Click **Enable Tableflow** > **Configure Custom Storage**
3. Use the same provider integration and S3 bucket
4. Click **Continue** and **Launch**

> **Key Point:** Notice how Tableflow automatically infers schema from Schema Registry for each topic. No manual schema mapping required!

---

### Exploring Iceberg Tables in AWS Glue

Let's see what Tableflow created in our data catalog.

1. Open the [AWS Glue Console](https://console.aws.amazon.com/glue) and navigate to **Data Catalog > Databases**

2. Find your database (it's named after your Confluent Cloud cluster ID). You can get the cluster ID from:
   ```bash
   terraform output resource-ids
   ```
   Look for the `Cluster ID` value under "Environment & Cluster Info"

3. Click into the database and you should see three tables:
   * `completed_orders`
   * `product_sales`
   * `thirty_day_customer_snapshot`

4. Click on `completed_orders` to view its schema. Notice:
   * The schema exactly matches what's in Schema Registry
   * Metadata includes Iceberg table properties
   * Storage location points to your S3 bucket

---

### Querying with Amazon Athena

> **Note:** After enabling Tableflow, it may take 5-10 minutes for data to become available in Athena.

1. Navigate to the [AWS Glue Data Catalog Tables page](https://console.aws.amazon.com/glue/home#/v2/data-catalog/tables)

2. Search for your cluster ID database, then find the `completed_orders` table

3. Click **View Data** under the Actions column. This opens Amazon Athena.

   ![Search for Cluster ID](assets/search-for-cluster-id.png)

4. Run a basic query to verify data is flowing:
   ```sql
   SELECT *
   FROM "AwsDataCatalog"."<<cluster-id>>"."completed_orders"
   LIMIT 10;
   ```

> **Note:** You may need to supply an output location for your Athena query if you haven't configured this before. Instructions can be found [here](https://docs.aws.amazon.com/athena/latest/ug/creating-databases-prerequisites.html). Feel free to use the same S3 bucket we are using for Tableflow data.

---

### Analyzing Sales Trends

Now let's perform some real analytics on our streaming data.

1. Calculate hourly sales trends:
   ```sql
   SELECT
   date_trunc('hour', ts) AS window_start,
   date_trunc('hour', ts) + INTERVAL '1' hour AS window_end,
   COUNT(*) AS total_orders,
   SUM(amount) AS total_revenue
   FROM "AwsDataCatalog"."<<cluster-id>>"."completed_orders"
   GROUP BY date_trunc('hour', ts)
   ORDER BY window_start;
   ```

2. Query `product_sales` for product-level insights:
   ```sql
   SELECT
      brand,
      productname,
      COUNT(DISTINCT orderid) as order_count,
      SUM(total_amount) as total_revenue,
      AVG(quantity) as avg_quantity
   FROM "AwsDataCatalog"."<<cluster-id>>"."product_sales"
   GROUP BY brand, productname
   ORDER BY total_revenue DESC
   LIMIT 20;
   ```

3. Query the customer snapshot:
   ```sql
   SELECT
      customername,
      total_amount,
      number_of_orders,
      updated_at
   FROM "AwsDataCatalog"."<<cluster-id>>"."thirty_day_customer_snapshot"
   WHERE number_of_orders > 5
   ORDER BY total_amount DESC
   LIMIT 20;
   ```

---

### Schema Evolution with Tableflow

One of Tableflow's powerful features is automatic schema evolution. Let's see it in action.

#### Add a New Field to Completed Orders

We'll add a `payment_method` field to track how customers pay.

1. First, stop the original statement:
   * Go to Flink Console > Statements
   * Find `completed-orders-materializer`
   * Click **Stop**

2. Add the new column to the existing table using ALTER TABLE:
   ```sql
   ALTER TABLE completed_orders ADD (payment_method STRING);
   ```

3. Start a new statement that populates the evolved schema:
   ```sql
   SET 'client.statement-name' = 'completed-orders-v2-materializer';

   INSERT INTO completed_orders
   SELECT
      pymt.order_id,
      pymt.amount,
      pymt.confirmation_code,
      CASE
         WHEN pymt.cc_number IS NOT NULL THEN 'CREDIT_CARD'
         ELSE 'UNKNOWN'
      END AS payment_method,  -- Derive payment method
      pymt.ts
   FROM unique_payments pymt, `shiftleft.public.orders` ord
   WHERE pymt.order_id = ord.orderid
   AND orderdate BETWEEN pymt.ts - INTERVAL '96' HOUR AND pymt.ts;
   ```

> **Important:** Using `ALTER TABLE` instead of `DROP TABLE` keeps Tableflow enabled throughout the schema evolution. No need to reconfigure storage or re-enable Tableflow!

4. Wait 2-3 minutes, then query in Athena:
   ```sql
   SELECT
      payment_method,
      COUNT(*) as order_count,
      SUM(amount) as total_revenue
   FROM "AwsDataCatalog"."<<cluster-id>>"."completed_orders"
   GROUP BY payment_method;
   ```

5. Notice what happened:
   * Old records have `NULL` for `payment_method` (schema evolution preserves historical data)
   * New records have the derived value
   * No manual DDL changes needed in Glue or Athena
   * Tableflow automatically updated the Iceberg table schema

---

### Time Travel Queries

Iceberg tables support querying historical snapshots. Let's explore this capability.

1. First, find the Iceberg table metadata in S3:
   ```bash
   # Get your S3 bucket name
   terraform output resource-ids | grep tableflow-bucket

   # List metadata files (replace bucket name)
   aws s3 ls s3://shiftleft-tableflow-bucket-XXXXX/completed_orders/metadata/ --recursive
   ```

2. In Athena, query table history using Iceberg's system tables:
   ```sql
   SELECT
      made_current_at,
      snapshot_id,
      parent_id
   FROM "AwsDataCatalog"."<<cluster-id>>"."completed_orders$snapshots"
   ORDER BY made_current_at DESC;
   ```

3. Query data as it existed at a specific snapshot (use a snapshot_id from above):
   ```sql
   SELECT COUNT(*) as record_count
   FROM "AwsDataCatalog"."<<cluster-id>>"."completed_orders"
   FOR SYSTEM_VERSION AS OF <<snapshot-id>>;
   ```

4. Query data as it existed at a specific time:
   ```sql
   SELECT COUNT(*) as record_count
   FROM "AwsDataCatalog"."<<cluster-id>>"."completed_orders"
   FOR SYSTEM_TIME AS OF TIMESTAMP '2026-01-05 10:00:00';
   ```

> **Key Insight:** Time travel enables:
> * Auditing and compliance (see exactly what data looked like at any point)
> * Reproducing historical analysis
> * Debugging data quality issues
> * Comparing current vs. past states

---

### Understanding Partitioning and File Layout

Tableflow automatically partitions data for optimal query performance.

1. Explore the S3 file structure:
   ```bash
   # List partitions for completed_orders (replace bucket name)
   aws s3 ls s3://shiftleft-tableflow-bucket-XXXXX/completed_orders/data/
   ```

   You'll see directories organized by date partitions (e.g., `ts_day=2026-01-05/`)

2. In Athena, query the partitions metadata:
   ```sql
   SELECT
      partition,
      record_count,
      file_count
   FROM "AwsDataCatalog"."<<cluster-id>>"."completed_orders$partitions"
   ORDER BY partition DESC;
   ```

3. Run a partition-pruned query (much faster!):
   ```sql
   SELECT COUNT(*), SUM(amount)
   FROM "AwsDataCatalog"."<<cluster-id>>"."completed_orders"
   WHERE date_trunc('day', ts) = DATE '2026-01-05';
   ```

4. Compare performance with a full table scan:
   ```sql
   SELECT COUNT(*), SUM(amount)
   FROM "AwsDataCatalog"."<<cluster-id>>"."completed_orders";
   ```

   Check the "Data scanned" metric in Athena's query results—the partitioned query should scan significantly less data.

---

### Comparing Query Performance Across Tables

Let's see how different Tableflow-enabled tables perform.

1. Run comparable queries against all three tables:

   **Completed Orders** (smallest table - payment facts only):
   ```sql
   SELECT COUNT(*), SUM(amount)
   FROM "AwsDataCatalog"."<<cluster-id>>"."completed_orders"
   WHERE date_trunc('day', ts) >= CURRENT_DATE - INTERVAL '7' DAY;
   ```

   **Product Sales** (medium table - denormalized order details):
   ```sql
   SELECT COUNT(*), SUM(total_amount)
   FROM "AwsDataCatalog"."<<cluster-id>>"."product_sales"
   WHERE date_trunc('day', orderdate) >= CURRENT_DATE - INTERVAL '7' DAY;
   ```

   **Customer Snapshot** (smallest but widest - aggregated metrics):
   ```sql
   SELECT COUNT(*), SUM(total_amount)
   FROM "AwsDataCatalog"."<<cluster-id>>"."thirty_day_customer_snapshot";
   ```

2. Compare the results in Athena's query history:
   * Data scanned
   * Query runtime
   * Files read

> **Observation:** Notice how Tableflow optimizes each table differently based on:
> * Schema complexity (wide vs. narrow tables)
> * Update patterns (append-only vs. upserts)
> * Data volume

---

### Monitoring Tableflow Operations

Tableflow performs background tasks like compaction and optimization. Let's see what's happening.

1. In the Confluent Cloud UI, navigate to **Tableflow** for your cluster

2. Click on the `completed_orders` topic

3. Observe the **Tableflow Metrics** panel:
   * Total records materialized
   * Iceberg data files created
   * Latest compaction timestamp
   * Storage used

4. Check compaction history in Athena:
   ```sql
   SELECT
      committed_at,
      snapshot_id,
      operation,
      summary
   FROM "AwsDataCatalog"."<<cluster-id>>"."completed_orders$snapshots"
   ORDER BY committed_at DESC;
   ```

   Look for operations like `append`, `replace`, and `overwrite` which indicate compaction activities.

---

## Key Takeaways

In this lab, you learned how Tableflow:

1. **Eliminates ETL Complexity:** No custom connectors or transformation jobs needed
2. **Handles Schema Evolution:** Automatically adapts to schema changes without breaking queries
3. **Enables Time Travel:** Query historical data states for auditing and analysis
4. **Optimizes Storage:** Automatic partitioning and compaction improve query performance
5. **Works with Any Engine:** Standard Iceberg format works with Athena, Snowflake, Spark, etc.

All of this happens automatically—Confluent manages the infrastructure, compaction, and optimization for you.

---

## Topics

**➡️ Next topic:** [Lab 3 - Multi-Engine Analytics with Snowflake](../LAB3/LAB3-README.md)

**🔙 Previous topic:** [Lab 1 - Product Sales and Customer360 Aggregation](../LAB1/LAB1-README.md)

**🏁 Finished?** [Cleanup](../README.md#clean-up)

---

## 🆘 Need Help?

Running into issues? Check the [**Troubleshooting Guide**](../TROUBLESHOOTING.md) for common problems and solutions, or ask a workshop instructor!
