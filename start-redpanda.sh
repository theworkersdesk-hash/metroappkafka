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

# Minimal config file (only non-CLI settings)
cat > /tmp/redpanda.yaml <<EOF
redpanda:
  developer_mode: true
  data_directory: /var/lib/redpanda/data
  node_id: 1
  cluster_id: redpanda-docker
  empty_seed_starts_cluster: true
EOF

echo "Starting Redpanda..."
# Use CLI flags for all listeners (bypasses YAML validation issues)
exec rpk redpanda start \
  --config /tmp/redpanda.yaml \
  --kafka-addr "internal://0.0.0.0:9092" \
  --advertise-kafka-addr "internal://${EXTERNAL_IP}:${KAFKA_PORT}" \
  --admin-addr "internal://0.0.0.0:9644" \
  --rpc-addr "0.0.0.0:33145" \
  --overprovisioned \
  --smp 1 \
  --memory 600M \
  --reserve-memory 0M