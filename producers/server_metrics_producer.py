import os
import time
import json
import random
from uuid import uuid4
from faker import Faker
from confluent_kafka import SerializingProducer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer

SERVER_IDS = [f"server_node_{i:02d}" for i in range(20)]

def delivery_report(err, msg):
    if err is not None:
        print(f"Delivery failed for record {msg.key()}: {err}")

def main():
    schema_registry_conf = {'url': 'http://localhost:8085'}
    schema_registry_client = SchemaRegistryClient(schema_registry_conf)
    
    schema_path = os.path.join(os.path.dirname(__file__), "..", "schemas", "server_metric.avsc")
    with open(schema_path, "r") as f:
        schema_str = f.read()
        
    avro_serializer = AvroSerializer(schema_registry_client, schema_str)
    
    producer_conf = {
        'bootstrap.servers': 'localhost:9092',
        'key.serializer': lambda k, ctx: k.encode('utf-8') if k else None,
        'value.serializer': avro_serializer
    }
    
    producer = SerializingProducer(producer_conf)
    topic = "server_metrics"
    
    print(f"Producing to topic '{topic}' ...")
    
    try:
        while True:
            # 5 metrics/sec
            metric_id = str(uuid4())
            server_id = random.choice(SERVER_IDS)
            # Simulate latency spikes on specific nodes randomly
            base_latency = random.uniform(20.0, 150.0)
            if random.random() < 0.1:
                base_latency = random.uniform(800.0, 3000.0) # High lag spike!
                
            cpu_utilization = random.uniform(10.0, 95.0)
            reading_ts = int(time.time() * 1000)
            
            value = {
                "metric_id": metric_id,
                "server_id": server_id,
                "cpu_utilization": cpu_utilization,
                "latency_ms": base_latency,
                "reading_ts": reading_ts
            }
            
            producer.produce(
                topic=topic,
                key=server_id,
                value=value,
                on_delivery=delivery_report
            )
            
            producer.poll(0)
            time.sleep(1.0 / 5.0)
            
    except KeyboardInterrupt:
        pass
    finally:
        producer.flush()

if __name__ == "__main__":
    main()
