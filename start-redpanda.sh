#!/bin/bash
# REDPANDA_EXTERNAL_IP should be the external reachable IP of this server.
# If not set, it defaults to localhost (which won't work across different machines).

EXTERNAL_IP=${REDPANDA_EXTERNAL_IP:-localhost}

echo "Starting Redpanda with Advertised IP: $EXTERNAL_IP"

exec redpanda start \
  --smp 1 \
  --memory 512M \
  --set redpanda.developer_mode=true \
  --set redpanda.kafka_api="[{'name': 'internal','address': '0.0.0.0','port': 9092}]" \
  --set redpanda.advertised_kafka_api="[{'name': 'internal','address': '$EXTERNAL_IP','port': ${RAILWAY_TCP_PROXY_PORT:-19092}}]"
