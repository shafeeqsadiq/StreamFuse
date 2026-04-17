#!/bin/bash
# scripts/init_pinot.sh
PINOT_CONTROLLER_URL="http://localhost:9000"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Wait a bit for Pinot to start..."
sleep 25

echo "Registering schema..."
curl -X POST -H "Content-Type: application/json" \
  -d @"$DIR/../pinot/enriched_events_schema.json" \
  ${PINOT_CONTROLLER_URL}/schemas

echo ""
echo "Creating real-time table..."
curl -X POST -H "Content-Type: application/json" \
  -d @"$DIR/../pinot/enriched_events_table.json" \
  ${PINOT_CONTROLLER_URL}/tables

echo ""
echo "Pinot initialization complete."
