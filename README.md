# StreamFuse: Real-Time Web Analytics Platform

StreamFuse is a real-time data pipeline that ingests, processes, and visualizes live data from multiple domains in an e-commerce system.

It combines:

* Marketing data (ad clicks)
* Financial data (transactions)
* Infrastructure data (server metrics)

All streams are joined in real time to generate enriched insights.

---

## Architecture

### Data Ingestion

Python producers continuously generate mock events:

* ClickEvents
* Transactions
* ServerMetrics

These are sent to Kafka topics.

---

### Messaging Layer

Kafka handles high-throughput data streaming.

* Events are serialized using Avro
* Schema Registry enforces strict data formats
* Prevents invalid data from entering the pipeline

---

### Stream Processing

Apache Flink performs real-time processing by:

* Joining streams on `user_id` and `server_id`
* Using 5-minute tumbling windows
* Calculating:

  * Total user spend
  * Server latency during checkout

The output is written to an `enriched_events` Kafka topic.

---

### Storage

Apache Pinot ingests enriched events in real time.

* Optimized for fast OLAP queries
* Supports sub-second aggregations

---

### Visualization

Grafana connects to Pinot and displays live dashboards using SQL queries.

---

## Tech Stack

* Apache Kafka + Schema Registry
* Apache Flink
* Apache Pinot
* Grafana
* Python
* Docker Compose

---

## Project Structure

```
docker-compose.yml     # Starts all services

schemas/               # Avro schemas
producers/             # Python data generators
flink/                 # Stream processing SQL
pinot/                 # Pinot configs
scripts/               # Automation scripts
```

---

## How to Run

### Prerequisites

* Docker
* Python
* 6–8GB RAM recommended

### Start the System

```
sh scripts/start.sh
```

This will:

* Start all services (Kafka, Flink, Pinot, Grafana)
* Register schemas
* Initialize Pinot tables
* Launch data producers
* Submit the Flink job
* Configure Grafana dashboards

---

## Dashboard

Open: http://localhost:3000
Login: `admin / admin`

Navigate to:
**Dashboards → StreamFuse Live Analytics**

---

## Key Metrics

* **Checkout Server Latency**
  Tracks real-time latency of servers handling transactions

* **Total Processed Spend**
  Displays cumulative transaction value

---

## Summary

StreamFuse demonstrates a complete real-time analytics pipeline:
data ingestion → stream processing → storage → visualization

It highlights how multiple data streams can be joined and analyzed instantly to generate actionable insights.
