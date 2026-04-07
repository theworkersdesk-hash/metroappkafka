#!/bin/bash
set -e

# Detect Railway environment
if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
    EXTERNAL_IP="$RAILWAY_PUBLIC_DOMAIN"
    KAFKA_PORT="${RAILWAY_TCP_PROXY_PORT:-9092}"
    echo "Railway environment detected"
    echo "External: ${EXTERNAL_IP}:${KAFKA_PORT}"
    
    # Single listener for Railway (external only)
    LISTENERS="PLAINTEXT://0.0.0.0:9092"
    ADVERTISED_LISTENERS="PLAINTEXT://${EXTERNAL_IP}:${KAFKA_PORT}"
    SECURITY_PROTOCOL_MAP="PLAINTEXT:PLAINTEXT"
    INTER_BROKER="PLAINTEXT"
else
    EXTERNAL_IP="${KAFKA_EXTERNAL_IP:-localhost}"
    KAFKA_PORT="${KAFKA_EXTERNAL_PORT:-19092}"
    echo "Local environment detected"
    
    # Dual listener for local (internal + external)
    LISTENERS="INTERNAL://0.0.0.0:9092,EXTERNAL://0.0.0.0:9093"
    ADVERTISED_LISTENERS="INTERNAL://kafka:9092,EXTERNAL://${EXTERNAL_IP}:${KAFKA_PORT}"
    SECURITY_PROTOCOL_MAP="INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT,CONTROLLER:PLAINTEXT"
    INTER_BROKER="INTERNAL"
fi

# Set Kafka environment variables
export KAFKA_NODE_ID=1
export KAFKA_PROCESS_ROLES=broker,controller
export KAFKA_CONTROLLER_QUORUM_VOTERS=1@localhost:9094
export KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER
export KAFKA_LISTENERS="${LISTENERS},CONTROLLER://localhost:9094"
export KAFKA_ADVERTISED_LISTENERS="${ADVERTISED_LISTENERS}"
export KAFKA_LISTENER_SECURITY_PROTOCOL_MAP="${SECURITY_PROTOCOL_MAP}"
export KAFKA_INTER_BROKER_LISTENER_NAME="${INTER_BROKER}"
export KAFKA_LOG_DIRS=/var/lib/kafka/data
export KAFKA_AUTO_CREATE_TOPICS_ENABLE=true
export KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
export KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1
export KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1

# Format storage if first run (KRaft requires this)
if [ ! -f /var/lib/kafka/data/meta.properties ]; then
    echo "Formatting Kafka KRaft storage..."
    CLUSTER_ID=$(/opt/kafka/bin/kafka-storage.sh random-uuid)
    /opt/kafka/bin/kafka-storage.sh format -t $CLUSTER_ID -c /opt/kafka/config/server.properties
fi

echo "Starting Kafka KRaft..."
echo "  Listeners: ${KAFKA_LISTENERS}"
echo "  Advertised: ${KAFKA_ADVERTISED_LISTENERS}"

exec /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties