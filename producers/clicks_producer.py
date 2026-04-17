import os
import time
import json
import random
from uuid import uuid4
from datetime import datetime
from faker import Faker
from confluent_kafka import SerializingProducer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer

# Shared user pool matching other producers
USER_IDS = [f"user_{i:04d}" for i in range(1000)]
DEVICE_TYPES = ["mobile", "desktop", "tablet"]

def delivery_report(err, msg):
    if err is not None:
        print(f"Delivery failed for record {msg.key()}: {err}")

def main():
    fake = Faker()
    
    schema_registry_conf = {'url': 'http://localhost:8085'}
    schema_registry_client = SchemaRegistryClient(schema_registry_conf)
    
    # Load schema
    schema_path = os.path.join(os.path.dirname(__file__), "..", "schemas", "click_event.avsc")
    with open(schema_path, "r") as f:
        schema_str = f.read()
        
    avro_serializer = AvroSerializer(schema_registry_client, schema_str)
    
    producer_conf = {
        'bootstrap.servers': 'localhost:9092',
        'key.serializer': lambda k, ctx: k.encode('utf-8') if k else None,
        'value.serializer': avro_serializer
    }
    
    producer = SerializingProducer(producer_conf)
    topic = "clicks"
    
    print(f"Producing to topic '{topic}' ...")
    
    try:
        while True:
            # Generate a fake click event (~10 events/sec)
            event_id = str(uuid4())
            user_id = random.choice(USER_IDS)
            session_id = str(uuid4())
            page_url = fake.uri()
            event_ts = int(time.time() * 1000)
            device_type = random.choice(DEVICE_TYPES)
            
            value = {
                "event_id": event_id,
                "user_id": user_id,
                "session_id": session_id,
                "page_url": page_url,
                "event_ts": event_ts,
                "device_type": device_type
            }
            
            producer.produce(
                topic=topic,
                key=user_id,
                value=value,
                on_delivery=delivery_report
            )
            
            producer.poll(0)
            time.sleep(0.1) # 10 events/sec
            
    except KeyboardInterrupt:
        pass
    finally:
        producer.flush()

if __name__ == "__main__":
    main()
