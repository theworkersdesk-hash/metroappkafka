#!/bin/bash
set -e

if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
    EXTERNAL_IP="$RAILWAY_PUBLIC_DOMAIN"
    KAFKA_PORT="${RAILWAY_TCP_PROXY_PORT:-9092}"
    echo "Railway environment detected"
else
    EXTERNAL_IP="${REDPANDA_EXTERNAL_IP:-localhost}"
    KAFKA_PORT="${REDPANDA_ADVERTISED_PORT:-19092}"
    echo "Local development environment"
fi

echo "Starting Redpanda..."
echo "  Advertised: ${EXTERNAL_IP}:${KAFKA_PORT}"

exec redpanda start \
  --smp 1 \
  --memory 600M \
  --reserve-memory 0M \
  --overprovisioned \
  --set redpanda.developer_mode=true \
  --set redpanda.empty_seed_starts_cluster=true \
  --set redpanda.kafka_api="[{'name':'internal','address':'0.0.0.0','port':9092}]" \
  --set redpanda.advertised_kafka_api="[{'name':'internal','address':'${EXTERNAL_IP}','port':${KAFKA_PORT}}]" \
  --set redpanda.admin_api="[{'name':'internal','address':'0.0.0.0','port':9644}]" \
  --set redpanda.rpc_server.address=0.0.0.0 \
  --set redpanda.rpc_server.port=33145