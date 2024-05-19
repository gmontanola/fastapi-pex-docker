FROM python:3.11-slim
COPY --from=ttl.sh/deps:1h /app /app
COPY --from=ttl.sh/src:1h /app /app

ENTRYPOINT ["/app/pex"]
EXPOSE 8000
