# StreamFuse: Real-Time Web Infrastructure Analytics Platform

StreamFuse is a real-time data platform that ingests live event streams from three different domains simultaneously, joins them together inside a 5-minute tumbling window using **Apache Flink**, writes the enriched results to **Apache Pinot** for sub-second database queries, and visualizes everything instantly in a live **Grafana** dashboard.

## The Problem Solved

Most analytical pipelines are "Batch Pipelines". They store data in rigid databases and analyze it hours later. In a modern e-commerce company, waiting 24 hours to find out that a lagging checkout server is killing Ad Campaign revenue is unacceptable. 

StreamFuse solves this by merging data "in-flight" while it is still moving through the network, allowing you to build a 360-degree view of your operations in milliseconds.

## The Architecture & Workflow

StreamFuse focuses on **E-Commerce Web Performance**. It demonstrates multi-domain enrichment by instantly combining Marketing (Ad clicks), Finance (Transactions), and IT Hardware (Server Metrics).

1. **Python Producers:** Continuously emit mock `ClickEvents`, `Transactions`, and `ServerMetrics` (CPU/Latency) to Apache Kafka. 
2. **Kafka & Schema Registry:** Serves as the ultra-fast message highway. Events are serialized into tiny binary footprints using **Avro** and managed via the Confluent Schema Registry to prevent corrupted data from crashing the pipeline (Poison Pills).
3. **Apache Flink Stream Join:** Acts as the processing brain. It performs intense in-memory stream-stream joins on `user_id` and `server_id` using 5-minute Tumbling Windows. It accurately calculates exactly how much money users spent, and correlates it with the exact latency of the server that handled their checkout. It then spits this JSON math back to an `enriched_events` Kafka topic.
4. **Apache Pinot:** Real-time Online Analytical Processing (OLAP) database optimized for hyper-fast aggregations. It ingests the Flink math instantly without locking or freezing up.
5. **Grafana:** Connects natively to Pinot to render live, breathing operational intelligence dashboards based on sub-second SQL queries.

### Avro Definitions (`schemas/`)

*(These act as rigid rule books. If a Python script tries to send a "click" without a `user_id`, the Schema Registry rejects it instantly to prevent the pipeline from crashing).*

- `click_event.avsc`: Dictates the shape of a click (`user_id`, `page_url`, `device_type`).
- `transaction.avsc`: Dictates the shape of a purchase (`txn_id`, `user_id`, `amount`, `server_id`).
- `server_metric.avsc`: Dictates the shape of a server latency log (`server_id`, `cpu_utilization`, `latency_ms`).

## How to Run

Ensure you have Docker and Python installed. **Note:** If you are running Docker Desktop on Windows, please ensure you have configured your `.wslconfig` to allow Docker at least 6GB-8GB of memory so the JVMs don't crash.

Execute the startup script which automatically performs:
1. Downloading necessary Flink Kafka & Avro connectors
2. Starting the Docker Compose cluster (Kafka, Schema Registry, Zookeeper, Flink, Pinot, Grafana)
3. Registering Avro schemas to the Confluent Schema Registry
4. Creating Apache Pinot real-time tables
5. Automating Grafana Dashboard/Datasource provisioning via REST API
6. Spawning 3 Python simulated data producers in the background
7. Submitting the Flink SQL Job to `flink-jobmanager`

```bash
sh scripts/start.sh
```

## Dashboard Overview
Once the script says `=== StreamFuse is Fully Running! ===`, head to [http://localhost:3000](http://localhost:3000) (Login: `admin`/`admin`) to experience the stream visualized under **Dashboards -> StreamFuse Live Analytics**:

1. **Checkout Server Latency**: Time series tracking live latency spikes matching specific checkout server nodes processing the purchases.
2. **Total Processed Spend**: A live counter capturing the total aggregated transaction value of the real-time financial stream.

### Graceful Shutdown
To completely turn off the platform and wipe the background data streams, open your terminal and run:
*Windows Users:* `taskkill -F -IM python.exe` then `docker-compose down -v`
*Mac/Linux Users:* `killall python` then `docker-compose down -v`
