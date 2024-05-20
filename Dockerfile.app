FROM python:3.11-slim

COPY --from=ttl.sh/appex:deps /app /app
COPY --from=ttl.sh/appex:src /app /app

ENTRYPOINT ["/app/pex"]
EXPOSE 8000
