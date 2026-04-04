#!/usr/bin/env bash
# Creates required Redpanda topics.
# Usage: ./redpanda/scripts/init-topics.sh [broker]
# Default broker: localhost:9092

set -euo pipefail

BROKER="${1:-localhost:9092}"

echo "Creating topics on broker: $BROKER"

# Production topic: 32 partitions, 1-hour retention
rpk topic create seat-bookings \
  --brokers "$BROKER" \
  --partitions 32 \
  --topic-config retention.ms=3600000 \
  --topic-config cleanup.policy=delete \
  || echo "seat-bookings already exists"

# Test topic: 4 partitions, 1-hour retention
rpk topic create seat-bookings-test \
  --brokers "$BROKER" \
  --partitions 4 \
  --topic-config retention.ms=3600000 \
  --topic-config cleanup.policy=delete \
  || echo "seat-bookings-test already exists"

echo "Topics created:"
rpk topic list --brokers "$BROKER"
