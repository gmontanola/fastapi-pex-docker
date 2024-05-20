FROM python:3.11-slim
ARG repo=ttl.sh/appex
COPY --from=${repo}:deps /app /app
COPY --from=${repo}:src /app /app

ENTRYPOINT ["/app/pex"]
EXPOSE 8000
