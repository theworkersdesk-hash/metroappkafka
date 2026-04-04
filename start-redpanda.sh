#!/bin/bash
# REDPANDA_EXTERNAL_IP should be the external reachable IP of this server.
# If not set, it defaults to localhost (which won't work across different machines).

EXTERNAL_IP=${REDPANDA_EXTERNAL_IP:-localhost}

echo "Starting Redpanda with Advertised IP: $EXTERNAL_IP"

exec redpanda start \
  --kafka-addr internal://0.0.0.0:9092,external://0.0.0.0:19092 \
  --advertise-kafka-addr internal://redpanda:9092,external://$EXTERNAL_IP:19092 \
  --pandaproxy-addr internal://0.0.0.0:8082,external://0.0.0.0:18082 \
  --advertise-pandaproxy-addr internal://redpanda:8082,external://$EXTERNAL_IP:18082 \
  --schema-registry-addr internal://0.0.0.0:8081,external://0.0.0.0:18081 \
  --rpc-addr 0.0.0.0:33145 \
  --advertise-rpc-addr $EXTERNAL_IP:33145 \
  --smp 1 \
  --memory 512M \
  --default-log-level=warn
