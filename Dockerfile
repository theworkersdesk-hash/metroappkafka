FROM apache/kafka:3.7.0

USER root
COPY start-kafka.sh /usr/local/bin/start-kafka.sh
RUN chmod +x /usr/local/bin/start-kafka.sh

RUN mkdir -p /var/lib/kafka/data && chown appuser:appuser /var/lib/kafka/data

USER appuser

EXPOSE 9092 9093

ENTRYPOINT ["/usr/local/bin/start-kafka.sh"]