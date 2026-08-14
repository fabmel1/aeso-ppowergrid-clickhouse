import json
import random
import time
from datetime import datetime, timedelta
from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
)

regions = ['CALGARY', 'EDMONTON', 'CENTRAL', 'NORTH', 'SOUTH']
asset_types = ['GAS', 'WIND', 'SOLAR', 'HYDRO']

# Set time range offset window (e.g., last 60 minutes or last 12 hours)
MAX_MINUTES_BACK = 60

print(
    "Streaming continuous AESO grid telemetry with randomized timestamps to"
    " Kafka..."
)
print("Press Ctrl+C to stop.")

try:
  while True:
    # Generate a random offset in the past
    random_minutes = random.randint(0, MAX_MINUTES_BACK)
    random_seconds = random.randint(0, 59)
    event_time = datetime.utcnow() - timedelta(
        minutes=random_minutes, seconds=random_seconds
    )

    payload = {
        "recorded_at": event_time.isoformat(),
        "region_id": random.choice(regions),
        "asset_type": random.choice(asset_types),
        "megawatts": round(random.uniform(50.0, 900.0), 2),
        "pool_price_cad": round(random.uniform(20.0, 180.0), 2),
    }

    producer.send('aeso-grid-events', value=payload)
    print(
        f"Sent event [{payload['recorded_at'][:19]}]: {payload['region_id']} |"
        f" {payload['asset_type']} | {payload['megawatts']} MW"
    )
    time.sleep(0.1)  # Sped up slightly (10 events/sec) to backfill quickly

except KeyboardInterrupt:
  print('\nStreaming stopped.')