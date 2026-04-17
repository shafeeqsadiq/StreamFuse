import os
import time
import json
import random
from uuid import uuid4
from faker import Faker
from confluent_kafka import SerializingProducer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer

# Shared user pool matching clicks producer
USER_IDS = [f"user_{i:04d}" for i in range(1000)]
# Shared checkout node ids to join with server metrics
SERVER_IDS = [f"server_node_{i:02d}" for i in range(20)]

def delivery_report(err, msg):
    if err is not None:
        print(f"Delivery failed for record {msg.key()}: {err}")

def main():
    fake = Faker()
    
    schema_registry_conf = {'url': 'http://localhost:8085'}
    schema_registry_client = SchemaRegistryClient(schema_registry_conf)
    
    schema_path = os.path.join(os.path.dirname(__file__), "..", "schemas", "transaction.avsc")
    with open(schema_path, "r") as f:
        schema_str = f.read()
        
    avro_serializer = AvroSerializer(schema_registry_client, schema_str)
    
    producer_conf = {
        'bootstrap.servers': 'localhost:9092',
        'key.serializer': lambda k, ctx: k.encode('utf-8') if k else None,
        'value.serializer': avro_serializer
    }
    
    producer = SerializingProducer(producer_conf)
    topic = "transactions"
    
    print(f"Producing to topic '{topic}' ...")
    
    try:
        while True:
            # Generate a fake transaction (~3 events/sec)
            txn_id = str(uuid4())
            user_id = random.choice(USER_IDS)
            amount = round(random.uniform(5.0, 500.0), 2)
            server_id = random.choice(SERVER_IDS)
            txn_ts = int(time.time() * 1000)
            
            value = {
                "txn_id": txn_id,
                "user_id": user_id,
                "amount": amount,
                "server_id": server_id,
                "txn_ts": txn_ts
            }
            
            producer.produce(
                topic=topic,
                key=user_id,
                value=value,
                on_delivery=delivery_report
            )
            
            producer.poll(0)
            time.sleep(1.0 / 3.0) # 3 events/sec
            
    except KeyboardInterrupt:
        pass
    finally:
        producer.flush()

if __name__ == "__main__":
    main()
