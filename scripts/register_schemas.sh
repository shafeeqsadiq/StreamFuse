#!/bin/bash
# scripts/register_schemas.sh
SCHEMA_REGISTRY_URL="http://localhost:8085"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

register_schema() {
  TOPIC_NAME=$1
  SCHEMA_FILE=$2
  
  # create payload using relative paths so Windows Python doesn't crash on Git Bash Unix paths
  python -c "import json; payload = {'schema': open('schemas/$SCHEMA_FILE').read()}; print(json.dumps(payload))" > "schemas/${TOPIC_NAME}_payload.json"
  
  curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data @"schemas/${TOPIC_NAME}_payload.json" \
    ${SCHEMA_REGISTRY_URL}/subjects/${TOPIC_NAME}-value/versions
    
  echo ""
  rm "schemas/${TOPIC_NAME}_payload.json"
}

echo "Wait a bit for Schema Registry to become fully available..."
sleep 5

echo "Registering schemas..."
register_schema "clicks" "click_event.avsc"
register_schema "transactions" "transaction.avsc"
register_schema "server_metrics" "server_metric.avsc"
