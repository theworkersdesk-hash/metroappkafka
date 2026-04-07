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

echo "Configuring Redpanda..."
echo "  Advertised: ${EXTERNAL_IP}:${KAFKA_PORT}"

# Create config file for v23.3.5
cat > /tmp/redpanda.yaml <<EOF
redpanda:
  developer_mode: true
  data_directory: /var/lib/redpanda/data
  node_id: 1
  cluster_id: redpanda-docker
  empty_seed_starts_cluster: true
  
  kafka_api:
    - name: internal
      address: 0.0.0.0
      port: 9092
  
  advertised_kafka_api:
    - name: internal
      address: ${EXTERNAL_IP}
      port: ${KAFKA_PORT}
  
  admin_api:
    - name: internal
      address: 0.0.0.0
      port: 9644
  
  rpc_server:
    address: 0.0.0.0
    port: 33145
EOF

echo "Starting Redpanda..."
# Use rpk redpanda start (not redpanda start) with YAML config
exec rpk redpanda start \
  --config /tmp/redpanda.yaml \
  --overprovisioned \
  --smp 1 \
  --memory 600M \
  --reserve-memory 0M