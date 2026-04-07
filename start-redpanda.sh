#!/bin/bash
set -e

# Railway injects these automatically when TCP Proxy is enabled
# RAILWAY_TCP_PROXY_PORT = the external port clients connect to (e.g., 7312)
# RAILWAY_PUBLIC_DOMAIN = your service domain (e.g., redpanda-xxxx.up.railway.app)

EXTERNAL_IP=${REDPANDA_EXTERNAL_IP:-${RAILWAY_PUBLIC_DOMAIN:-localhost}}
ADVERTISED_PORT=${RAILWAY_TCP_PROXY_PORT:-9092}

echo "=========================================="
echo "Redpanda Railway Configuration"
echo "External Address: ${EXTERNAL_IP}:${ADVERTISED_PORT}"
echo "Internal Listener: 0.0.0.0:9092"
echo "=========================================="

exec redpanda start \
  --smp 1 \
  --memory 1G \
  --reserve-memory 0M \
  --overprovisioned \
  --set redpanda.developer_mode=true \
  --set redpanda.node_id=1 \
  --set redpanda.cluster_id=redpanda-railway \
  --set redpanda.kafka_api="[{'name':'internal','address':'0.0.0.0','port':9092}]" \
  --set redpanda.advertised_kafka_api="[{'name':'internal','address':'${EXTERNAL_IP}','port':${ADVERTISED_PORT}}]" \
  --set redpanda.admin_api="[{'name':'internal','address':'0.0.0.0','port':9644}]"