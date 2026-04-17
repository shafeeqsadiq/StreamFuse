#!/bin/bash
# scripts/start.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/.."

mkdir -p flink-lib
echo "Downloading Flink Kafka & Avro Connectors for Flink 1.18..."
curl -sSLo flink-lib/flink-connector-kafka-3.0.1-1.18.jar https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/3.0.1-1.18/flink-connector-kafka-3.0.1-1.18.jar
curl -sSLo flink-lib/kafka-clients-3.4.0.jar https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.4.0/kafka-clients-3.4.0.jar
curl -sSLo flink-lib/flink-sql-avro-1.18.1.jar https://repo1.maven.org/maven2/org/apache/flink/flink-sql-avro/1.18.1/flink-sql-avro-1.18.1.jar
curl -sSLo flink-lib/flink-sql-avro-confluent-registry-1.18.1.jar https://repo1.maven.org/maven2/org/apache/flink/flink-sql-avro-confluent-registry/1.18.1/flink-sql-avro-confluent-registry-1.18.1.jar

echo "Starting Docker Compose services..."
docker-compose up -d

echo "Waiting for Schema Registry to become healthy (this can take ~30s)..."
while ! curl -s http://localhost:8085/subjects > /dev/null; do
  echo "Still waiting..."
  sleep 5
done

echo "Running Initialization Scripts (Waiting for services to become healthy)..."
bash scripts/register_schemas.sh
bash scripts/init_pinot.sh
python scripts/setup_grafana.py

echo "Installing Python generic producer dependencies..."
pip install -r producers/requirements.txt

echo "Starting producers in background..."
python producers/clicks_producer.py &
CLICKS_PID=$!
python producers/transactions_producer.py &
TXNS_PID=$!
python producers/server_metrics_producer.py &
SERVER_METRICS_PID=$!

echo "Submitting Flink SQL Stream-Stream Join Job..."
# Wait sequentially to give Flink TM time to register
sleep 5
# Prefix with MSYS_NO_PATHCONV=1 to prevent Windows Git Bash from mangling absolute paths in containers
MSYS_NO_PATHCONV=1 docker exec -d flink-jobmanager /opt/flink/bin/sql-client.sh -j /opt/flink/usrlib/flink-connector-kafka-3.0.1-1.18.jar -j /opt/flink/usrlib/kafka-clients-3.4.0.jar -j /opt/flink/usrlib/flink-sql-avro-1.18.1.jar -j /opt/flink/usrlib/flink-sql-avro-confluent-registry-1.18.1.jar -f /opt/flink/sql/streaming_join.sql

echo ""
echo "=== StreamFuse is Fully Running! ==="
echo "Access Grafana at http://localhost:3000"
echo "To terminate producers, run: kill $CLICKS_PID $TXNS_PID $SERVER_METRICS_PID"
