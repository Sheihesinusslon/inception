FROM alpine:3.23

RUN apk add --no-cache python3 py3-flask py3-gunicorn

WORKDIR /app
COPY app/ /app/

RUN chmod +x /app/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/app/entrypoint.sh"]