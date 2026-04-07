#!/bin/bash
set -e

# Detect Railway environment
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

# Config file with correct property names
cat > /tmp/redpanda.yaml <<EOF
redpanda:
  developer_mode: true
  data_directory: /var/lib/redpanda/data
  node_id: 1
  cluster_id: redpanda-docker
  empty_seed_starts_cluster: true
  
  admin:
    - name: internal
      address: 0.0.0.0
      port: 9644
EOF

echo "Starting Redpanda..."
# CLI flags only for options that support it
exec rpk redpanda start \
  --config /tmp/redpanda.yaml \
  --kafka-addr "internal://0.0.0.0:9092" \
  --advertise-kafka-addr "internal://${EXTERNAL_IP}:${KAFKA_PORT}" \
  --rpc-addr "0.0.0.0:33145" \
  --overprovisioned \
  --smp 1 \
  --memory 600M \
  --reserve-memory 0M