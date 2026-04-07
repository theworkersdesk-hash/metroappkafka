FROM apache/kafka:3.6.1

USER root
COPY start-kafka.sh /usr/local/bin/start-kafka.sh
RUN chmod +x /usr/local/bin/start-kafka.sh

# Create data directory
RUN mkdir -p /var/lib/kafka/data && chown kafka:kafka /var/lib/kafka/data

USER kafka

EXPOSE 9092 9093

ENTRYPOINT ["/usr/local/bin/start-kafka.sh"]