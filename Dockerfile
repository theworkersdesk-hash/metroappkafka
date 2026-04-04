FROM redpandadata/redpanda:v24.3.1

USER root
COPY start-redpanda.sh /usr/local/bin/start-redpanda.sh
RUN chmod +x /usr/local/bin/start-redpanda.sh

USER redpanda

# Expose Kafka API, Schema Registry, and Admin API
EXPOSE 9092 19092 8081 18081 8082 18082 9644 33145

# Start redpanda utilizing our script to inject the external IP for proper multi-server routing
ENTRYPOINT ["/usr/local/bin/start-redpanda.sh"]
