# StreamFuse: Real-Time Web Infrastructure Analytics Platform

StreamFuse is a real-time data platform that ingests live event streams from three different domains simultaneously, joins them together inside a 5-minute tumbling window using **Apache Flink**, writes the enriched results to **Apache Pinot** for sub-second database queries, and visualizes everything instantly in a live **Grafana** dashboard.

## The Architecture & Workflow

StreamFuse focuses on **E-Commerce Web Performance**. It demonstrates multi-domain enrichment by instantly combining Marketing (Ad clicks), Finance (Transactions), and IT Hardware (Server Metrics).

1. **Python Producers:** Continuously emit mock `ClickEvents`, `Transactions`, and `ServerMetrics` (CPU/Latency) to Apache Kafka. 
2. **Kafka & Schema Registry:** Serves as the ultra-fast message highway. Events are serialized into tiny binary footprints using **Avro** and managed via the Confluent Schema Registry to prevent corrupted data from crashing the pipeline (Poison Pills).
3. **Apache Flink Stream Join:** Acts as the processing brain. It performs intense in-memory stream-stream joins on `user_id` and `server_id` using 5-minute Tumbling Windows. It accurately calculates exactly how much money users spent, and correlates it with the exact latency of the server that handled their checkout. It then spits this JSON math back to an `enriched_events` Kafka topic.
4. **Apache Pinot:** Real-time Online Analytical Processing (OLAP) database optimized for hyper-fast aggregations. It ingests the Flink math instantly without locking or freezing up.
5. **Grafana:** Connects natively to Pinot to render live, breathing operational intelligence dashboards based on sub-second SQL queries.

## Technology Stack

- **Apache Flink**: Highly scalable, stateful stream-processing framework utilized for performing complex, in-memory 5-minute tumbling window joins across live data streams.
- **Apache Kafka & Confluent Schema Registry**: High-throughput distributed message broker paired with strict Avro serialization to guarantee structural event integrity and prevent poison-pill crashes.
- **Apache Pinot**: Real-time OLAP datastore optimized for sub-second, hyper-fast aggregations and direct, lock-free ingestion from Kafka topics.
- **Grafana**: Interactive visualization endpoint linking natively to Pinot via REST to render live, updating operational intelligence dashboards.
- **Python**: Producer generators utilizing the `confluent-kafka` library to orchestrate and simulate high-volume, continuous multi-domain web traffic.
- **Docker Compose**: Complete cluster containerization, ensuring instant deployment of all nodes (Zookeeper, JobManagers, Brokers) entirely isolated from the host machine.

## Repository Structure

- `docker-compose.yml`: Primary configuration file that initializes the isolated internal network and spins up all heavyweight containers (Kafka, Zookeeper, Flink, Pinot, Schema Registry, Grafana).
- `schemas/`: Holds the strict Avro rule books (`click_event.avsc`, `transaction.avsc`, `server_metric.avsc`) that physically force the data shape before Kafka accepts it.
- `producers/`: Contains the highly threaded Python simulator scripts (`clicks_producer.py`, `transactions_producer.py`, `server_metrics_producer.py`) that pump live mock events into the Kafka topics.
- `flink/streaming_join.sql`: The hardcore Stream Processing logic. Houses the Flink SQL Table-Valued Functions (TVF) that execute the 3-way Tumbling Window joins matching Users to Checkout Latency.
- `pinot/`: Houses the complex JSON schemas orchestrating Pinot's high-speed columnar database indices for zero-lag aggregation.
- `scripts/`: Holds the critical automated bash logic (`start.sh`, `register_schemas.sh`, `init_pinot.sh`, `setup_grafana.py`) that bypasses manual API handshakes to launch the pipeline instantly.

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


