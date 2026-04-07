FROM redpandadata/redpanda:v23.3.5

USER root
COPY start-redpanda.sh /usr/local/bin/start-redpanda.sh
RUN chmod +x /usr/local/bin/start-redpanda.sh

USER redpanda

EXPOSE 9092 9644 33145

ENTRYPOINT ["/usr/local/bin/start-redpanda.sh"]