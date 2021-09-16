FROM nginx:1.21-alpine

RUN apk add --no-cache jq
COPY download-image.sh /docker-entrypoint.d/40-download-image.sh

COPY crontab /etc/crontabs/root
COPY run-crond.sh /docker-entrypoint.d/50-run-crond.sh

COPY --from=julienbreux/clamp:v1.4.0 /bin/clamp /usr/local/bin/
COPY render-templates.sh /docker-entrypoint.d/60-render-templates.sh

COPY static /usr/share/nginx/html
