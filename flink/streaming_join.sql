CREATE TABLE clicks (
  event_id STRING,
  user_id STRING,
  session_id STRING,
  page_url STRING,
  event_ts BIGINT,
  device_type STRING,
  -- Compute ts from event_ts
  ts AS TO_TIMESTAMP_LTZ(event_ts, 3),
  WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'clicks',
  'properties.bootstrap.servers' = 'kafka1:29092',
  'properties.group.id' = 'flink_group_clicks',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'avro-confluent',
  'avro-confluent.url' = 'http://schema-registry:8081'
);

CREATE TABLE transactions (
  txn_id STRING,
  user_id STRING,
  amount DOUBLE,
  server_id STRING,
  txn_ts BIGINT,
  ts AS TO_TIMESTAMP_LTZ(txn_ts, 3),
  WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'transactions',
  'properties.bootstrap.servers' = 'kafka1:29092',
  'properties.group.id' = 'flink_group_txns',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'avro-confluent',
  'avro-confluent.url' = 'http://schema-registry:8081'
);

CREATE TABLE server_metrics (
  metric_id STRING,
  server_id STRING,
  cpu_utilization DOUBLE,
  latency_ms DOUBLE,
  reading_ts BIGINT,
  ts AS TO_TIMESTAMP_LTZ(reading_ts, 3),
  WATERMARK FOR ts AS ts - INTERVAL '10' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'server_metrics',
  'properties.bootstrap.servers' = 'kafka1:29092',
  'properties.group.id' = 'flink_group_metrics',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'avro-confluent',
  'avro-confluent.url' = 'http://schema-registry:8081'
);

CREATE TABLE enriched_events (
  window_start BIGINT,
  window_end BIGINT,
  user_id STRING,
  device_type STRING,
  click_count BIGINT,
  total_spend DOUBLE,
  avg_latency_ms DOUBLE
) WITH (
  'connector' = 'kafka',
  'topic' = 'enriched_events',
  'properties.bootstrap.servers' = 'kafka1:29092',
  'format' = 'json'
);

CREATE VIEW windowed_clicks AS
SELECT user_id, MAX(device_type) AS device_type, window_start, window_end, COUNT(event_id) as click_count
FROM TABLE(TUMBLE(TABLE clicks, DESCRIPTOR(ts), INTERVAL '5' MINUTE))
GROUP BY window_start, window_end, user_id;

CREATE VIEW windowed_transactions AS
SELECT user_id, MAX(server_id) as server_id, window_start, window_end, SUM(amount) as total_spend
FROM TABLE(TUMBLE(TABLE transactions, DESCRIPTOR(ts), INTERVAL '5' MINUTE))
GROUP BY window_start, window_end, user_id;

CREATE VIEW windowed_metrics AS
SELECT server_id, window_start, window_end, AVG(latency_ms) as avg_latency
FROM TABLE(TUMBLE(TABLE server_metrics, DESCRIPTOR(ts), INTERVAL '5' MINUTE))
GROUP BY window_start, window_end, server_id;

INSERT INTO enriched_events
SELECT 
  CAST(UNIX_TIMESTAMP(CAST(c.window_start AS STRING)) * 1000 AS BIGINT) AS window_start,
  CAST(UNIX_TIMESTAMP(CAST(c.window_end AS STRING)) * 1000 AS BIGINT) AS window_end,
  c.user_id,
  c.device_type,
  c.click_count,
  COALESCE(t.total_spend, 0.0) AS total_spend,
  COALESCE(s.avg_latency, 0.0) AS avg_latency_ms
FROM windowed_clicks c
LEFT JOIN windowed_transactions t
  ON c.user_id = t.user_id 
  AND c.window_start = t.window_start
  AND c.window_end = t.window_end
LEFT JOIN windowed_metrics s
  ON t.server_id = s.server_id
  AND c.window_start = s.window_start
  AND c.window_end = s.window_end;
