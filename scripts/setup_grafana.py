import requests
import json
import time

GRAFANA_URL = "http://admin:admin@localhost:3000"

# 1. Install Pinot Datasource
print("Adding Pinot Data Source...")
ds_payload = {
    "name": "Pinot",
    "type": "startree-pinot-datasource",
    "access": "proxy",
    "url": "http://pinot-broker:8099",
    "isDefault": True
}
response = requests.post(f"{GRAFANA_URL}/api/datasources", json=ds_payload)
if response.status_code not in [200, 409]:
    print(f"Failed to add data source: {response.text}")
    print("Attempting to add using native JSON API if plugin is missing...")
    ds_payload["type"] = "json"
    requests.post(f"{GRAFANA_URL}/api/datasources", json=ds_payload)

# 2. Create the StreamFuse Dashboard
print("Creating StreamFuse Dashboard...")
dashboard_payload = {
  "dashboard": {
    "id": None,
    "uid": "streamfuse-1",
    "title": "StreamFuse Live Analytics",
    "tags": [ "real-time" ],
    "timezone": "browser",
    "schemaVersion": 16,
    "version": 0,
    "panels": [
      {
        "type": "timeseries",
        "title": "Checkout Server Latency (ms)",
        "gridPos": { "h": 9, "w": 12, "x": 0, "y": 0 },
        "targets": [
          {
            "rawQuery": True,
            "query": "SELECT window_start, avg_latency_ms FROM enriched_events_REALTIME ORDER BY window_start DESC LIMIT 10",
            "format": "time_series"
          }
        ]
      },
      {
        "type": "stat",
        "title": "Total Processed Spend",
        "gridPos": { "h": 9, "w": 12, "x": 12, "y": 0 },
        "targets": [
          {
            "rawQuery": True,
            "query": "SELECT SUM(total_spend) FROM enriched_events_REALTIME"
          }
        ]
      }
    ]
  },
  "folderId": 0,
  "overwrite": True
}

resp = requests.post(f"{GRAFANA_URL}/api/dashboards/db", json=dashboard_payload)
if resp.status_code == 200:
    print("Dashboard Successfully Created!")
else:
    print(f"Failed to create dashboard: {resp.text}")

