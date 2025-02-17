
## Daily Sales Trends

In this use case, we utilize Confluent Cloud and Apache Flink to validate payments and analyze daily sales trends, creating a valuable data product that empowers sales teams to make informed business decisions. While such analyses are typically conducted within a Lakehouse—as demonstrated in use cases 1 and 2—Confluent offers multiple integration options to seamlessly bring data streams into Lakehouses. This includes a suite of connectors that read data from Confluent and write to various engines. Another option is [Tableflow](https://www.confluent.io/product/tableflow/) .

Tableflow simplifies the process of transferring data from Confluent into a data lake, warehouse, or analytics engine. It enables users to convert Kafka topics and their schemas into Apache Iceberg tables with zero effort, significantly reducing the engineering time, compute resources, and costs associated with traditional data pipelines. This efficiency is achieved by leveraging Confluent's Kora Storage Layer and a new metadata materializer that works with Confluent Schema Registry to manage schema mapping and evolution.

Since sales team in our fictitious company store all their data in Iceberg format. Instead of sending data to S3 and transforming it there, we’ll leverage Tableflow, which allows Confluent to handle the heavy lifting of data movement, conversion, and compaction. With Tableflow enabled, data stored in a Confluent topic, is ready for analytics in Iceberg format.

![Architecture](./assets/usecase3.png)


But before doing this, let's make sure that the data is reliable and protected first.

### **[OPTIONAL] Data Contracts in Confluent Cloud**

Analytics teams are focused on general sales trends, so they don't need access to PII. Instead of relying on central teams to write ETL scripts for data encryption and quality, we’re shifting this process left. Central governance teams set data protection and quality rules, which are pushed to the client for enforcement— the beauty of this is that there is not need for code changes on the client side - **IT JUST WORKS**.

##### **Using Confluent Cloud Data Quality Rules**

We want to make sure that any data produced adheres to a specific format. In our case, we want to make sure that any payment event generated needs to have a valide `Confimation Code`. This check is done by using [Data Quality Rules](https://docs.confluent.io/cloud/current/sr/fundamentals/data-contracts.html#data-quality-rules), these rules are set in Confluent Schema registry, and pushed to the clients, where they are enforced. No need to change any code.

The rules were already created by Terraform, there is no need to do anything here except validate that it is working.

1. In the [`payments`](https://confluent.cloud/go/topics) Topic UI, select **Data Contracts**. Under **Rules** notice that there is a rule already created.
   
   The rule basically says that `confirmation_code` field value should follow this regex expression `^[A-Z0-9]{8}$`. Any event that doesnt match, will be sent to a dead letter queue topic named `error-payments`.

   ![Data Quality Rule](./assets/usecase3_dqr.png)

2. To validate that it is working go to the DLQ topic and inspect the message headers there.
   
![Data Quality Rule](./assets/usecase3_msgdlq.png)


##### **Data Protection using Confluent Cloud Client Side Field Level Encryption**

[Client Side Field Level Encryption(CSFLE)](https://docs.confluent.io/cloud/current/security/encrypt/csfle/client-side.html) in Confluent Cloud works by setting the rules in Confluent Schema registry, these rules are then pushed to the clients, where they are enforced. The symmetric key is created in providor and the client should have necessary permissi the providor and the client should have permission to use the key to encrypt the data.

1. In the `payments` topic we notice that, the topic contains credit card information in unencrypted form.
    ![Architecture](./assets/usecase3_msg.png)

This field should be encrypted, the Symmetric Key was already created by the Terraform in AWS KMS. The key ARN was also immported to Confluent by Terraform. We just need to create the rule in Confluent
   
2. In the [`payments`](    
   https://confluent.cloud/go/topics) Topic UI, select **Data Contracts** then click **Evolve**. Tag `cc_number` field as `PII`.
   
2. Click **Rules** and then **+ Add rules** button. Configure as the following:
   * Category: Data Encryption Rule
   * Rule name: `Encrypt_PII`
   * Encrypt fields with: `PII`
   * using: The key added by Terraform (probably called CSFLE_Key)
  
    Then click **Add** and **Save**

    Our rule instructs the serailizer to ecrypt any field in this topic that is tagged as PII

    ![CSFLE Rule](./assets/usecase3_rule.png)
4. Restart the ECS Service for the changes to take effect immediately. Run ```terraform output``` to get the ECS command that should be used to restart the service. The command should look like this:
   ```
   aws ecs update-service --cluster <ECS_CLUSTER_NAME> --service payment-app-service --force-new-deployment
   ```
5. Go back to the `payments` Topic UI, you can see that the Credit number is now encrypted.

    ![Encrypted Field](./assets/usecase3_msgenc.png)


### **Analyzing Daily Sales Trends using Confluent Cloud for Apache Flink**

We have a separate topic for payment information, an order is considered complete once a valid payment is received. To accurately track daily sales trends, we join the ```orders``` and ```payments``` data.

#### **Payments deduplication**

However, before joining both streams together we need to make sure that there are no duplicates in `payments` data coming in.

1. Check if there are any duplicates in `payments` table
   ```sql
   SELECT * FROM
   ( SELECT order_id, amount, count(*) total 
    FROM `payments`
    GROUP BY order_id, amount )
   WHERE total > 1;
   ```
   This query shows all `order_id`s with multiple payments coming in. Since the output returns results, this indicates that the there are duplicicates in the `payments` table.

2. To fix this run the following query in a new Flink cell
   ```sql
   SET 'client.statement-name' = 'unique-payments-maintenance';
   SET 'sql.state-ttl' = '1 hour';
   
   CREATE TABLE unique_payments
   AS SELECT 
     order_id, 
     product_id, 
     customer_id, 
     confirmation_code,
     cc_number,
     expiration,
     `amount`,
     `ts`
   FROM (
      SELECT * ,
             ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY `$rowtime` ASC) AS rownum
      FROM payments
         )
   WHERE rownum = 1;
   ```
   This query creates the `unique_payments` table, ensuring only the latest recorded payment for each `order_id` is retained. It uses `ROW_NUMBER()` to order payments by event time (`$rowtime`) and filters for the earliest entry per order. This removes any duplicate entries.

3. Let's validate that the new `unique_payments` does not comtain any duplicates
   ```sql
   SELECT order_id, COUNT(*) AS count_total FROM `unique_payments` GROUP BY order_id;
   ```
   Every `order_id` will have a `count_total` of `1`, ensuring no duplicates exist in the new table. You will not find any `order_id` with a value greater than `1`.

4. Finally, let's set the new table to `append`-only, meaning payments will not be updated once inserted.  
```sql
ALTER TABLE `unique_payments` SET ('changelog.mode' = 'append');
```

#### **Using Interval joins to filter out invalid orders**

Now let's filter out invalid orders (orders with no payment recieved within 96 hours). To achieve this we will use Flink Interval joins.


1. Create a new table that will hold all completed orders.
   ```sql
    CREATE TABLE completed_orders (
        order_id INT,
        amount DOUBLE,
        confirmation_code STRING,
        ts TIMESTAMP_LTZ(3),
        WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
    );
   ```
2. Filter out orders with no valid payment recieved within `96` hours of the order being placed.
   ```sql
   SET 'client.statement-name' = 'completed-orders-materializer';
   INSERT INTO completed_orders
    SELECT 
        pymt.order_id,
        pymt.amount, 
        pymt.confirmation_code, 
        pymt.ts
    FROM unique_payments pymt, `shiftleft.public.orders` ord 
    WHERE pymt.order_id = ord.orderid
    AND orderdate BETWEEN pymt.ts - INTERVAL '96' HOUR AND pymt.ts;
   ```

#### **Analyzing Sales Trends**

1. Create a ```revenue_summary``` table. This table will hold aggregated revenue data, helping to track and visualize sales over specific time intervals:
   ```sql
   CREATE TABLE revenue_summary (
        window_start TIMESTAMP(3),
        window_end TIMESTAMP(3),
        total_revenue DECIMAL(10, 2)
    );

   ```

2. Finally, we calculate the total revenue within fixed 5-second windows by summing the amount from completed_orders. This is done using the TUMBLE function, which groups data into 5-second intervals, providing a clear view of sales trends over time:
   >Note: The 5-second window is done for demo puposes you can change to the interval to 1 HOUR.

    ```sql
    SET 'client.statement-name' = 'revenue-summary-materializer';
    INSERT INTO revenue_summary
    SELECT 
        window_start, 
        window_end, 
        SUM(amount) AS total_revenue
    FROM 
        TABLE(
            TUMBLE(TABLE completed_orders, DESCRIPTOR(`ts`), INTERVAL '5' SECONDS)
        )
    GROUP BY 
        window_start, 
        window_end;

    ```

5. Preview the final output:
    ```sql
     SELECT * FROM revenue_summary
    ```

#### **Data Lake Integration using Confluent Cloud Tableflow and Amazon Athena**

This data can be made available seamlessly to your Data lake query engines using Confluent Cloud Tableflow feature. When Tableflow is enabled on the cluster, all topics in the cluster are materialized as Iceberg Tables and are available for any Query engine. In this demo, we use Amazon Athena, you can use any Engine that supports Iceberg Rest Catalog.

1. First get the Tableflow access details from the Data Portal UI.
   ![Tableflow Access Details](./assets/usecase3_tableflow.png)

2. In Amazon Athena UI, create a new Spark Notebook and configure it as follows:
   ![Athena Notebook](./assets/usecase3_notebook.png)

3. `revenue_summary` data can now be queried in Athena. In the notebook run this query to SHOW available tables:
   ```
   %sql
   SHOW TABLES in `<Confluent_Cluster_ID>`
   ```

   Next preview `reveue_summary` table:

   ```
   %%sql
   SELECT * FROM `<Confluent_Cluster_ID>`.`revenue_summary`;
   ```

   That's it we are now able to query the data in Athena.
## Topics

**Next topic:** [Managing Data Pipelines](../Usecase4/USECASE4-README.md)

**Previous topic:** [Usecase 2 - Product Sales Aggregation](../Usecase2/USECASE2-README.md)

