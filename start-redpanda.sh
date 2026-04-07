#!/bin/bash
set -e

# Determine environment
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
echo "  Advertised Address: ${EXTERNAL_IP}:${KAFKA_PORT}"
echo "  Internal Listener: 0.0.0.0:9092"

# Generate redpanda.yaml config file (without reserve-memory in additional_start_flags)
cat > /tmp/redpanda.yaml <<EOF
redpanda:
  developer_mode: true
  data_directory: /var/lib/redpanda/data
  node_id: 1
  cluster_id: redpanda-docker
  
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

rpk:
  additional_start_flags:
    - --overprovisioned
    - --smp=1
    - --memory=1G
EOF

echo "Starting Redpanda..."
# Pass --reserve-memory directly to rpk start (not in config file)
exec rpk redpanda start --config /tmp/redpanda.yaml --reserve-memory 0M