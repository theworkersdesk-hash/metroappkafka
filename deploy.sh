#!/usr/bin/env bash
# Deploy Redpanda on this server.
#
# Usage:
#   ./deploy.sh --ip <THIS_SERVER_IP>        Start Redpanda
#   ./deploy.sh stop                         Stop and remove containers (data volume preserved)
#   ./deploy.sh logs                         Tail logs
#
# --ip is REQUIRED for start — Redpanda must advertise the correct external IP
# so that API/Consumer on other servers can connect.
#
# Firewall: allow port 19092 inbound from your API and Consumer server IPs.

set -euo pipefail

CONTAINER=metro_redpanda
TOPIC_CONTAINER=metro_init_topics

ACTION="${1:-start}"

start() {
  SERVER_IP=""
  shift || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ip) SERVER_IP="$2"; shift 2 ;;
      *)    echo "Unknown flag: $1"; exit 1 ;;
    esac
  done

  if [ -z "$SERVER_IP" ]; then
    echo "ERROR: --ip <THIS_SERVER_IP> is required"
    echo "Usage: ./deploy.sh --ip 198.51.100.10"
    exit 1
  fi

  echo "==> Building Redpanda image"
  docker build -t metro-redpanda .

  echo "==> Starting Redpanda (advertised IP: $SERVER_IP)"
  docker run -d \
    --name "$CONTAINER" \
    --restart unless-stopped \
    -p 9092:9092 -p 19092:19092 \
    -p 8081:8081 -p 18081:18081 \
    -p 8082:8082 -p 18082:18082 \
    -p 9644:9644 -p 33145:33145 \
    -v metro_redpanda_data:/var/lib/redpanda/data \
    -e REDPANDA_EXTERNAL_IP="$SERVER_IP" \
    metro-redpanda

  echo "==> Waiting for Redpanda to be ready..."
  for i in $(seq 1 30); do
    if docker exec "$CONTAINER" rpk cluster health 2>/dev/null | grep -q 'Healthy:.*true'; then
      echo "    Redpanda is healthy"
      break
    fi
    if [ "$i" -eq 30 ]; then
      echo "    ERROR: Redpanda did not become healthy in time"
      exit 1
    fi
    sleep 2
  done

  echo "==> Creating topics"
  docker exec "$CONTAINER" rpk topic create seat-bookings \
    --brokers localhost:9092 \
    --partitions 32 \
    --topic-config retention.ms=3600000 \
    --topic-config cleanup.policy=delete 2>/dev/null || echo "    seat-bookings already exists"

  echo ""
  echo "Redpanda running:"
  echo "  Kafka (external) → $SERVER_IP:19092"
  echo "  Admin API        → $SERVER_IP:9644"
}

stop() {
  echo "==> Stopping Redpanda"
  docker rm -f "$CONTAINER" "$TOPIC_CONTAINER" 2>/dev/null || true
  echo "Done (volume metro_redpanda_data preserved)"
}

logs() {
  docker logs -f "$CONTAINER"
}

case "$ACTION" in
  start) start "$@" ;;
  stop)  stop  ;;
  logs)  logs  ;;
  *)     echo "Usage: $0 {start --ip <IP>|stop|logs}"; exit 1 ;;
esac
