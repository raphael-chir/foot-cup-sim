#!/bin/sh

cat >/opt/app-root/src/config.js <<EOL
window.APP_CONFIG = {
  API_URL: "${API_URL}",
  MODE: "${MODE:-viewer}"
}
EOL

echo "Starting World Cup UI"
echo "API_URL=${API_URL}"
echo "MODE=${MODE:-viewer}"

exec nginx -g 'daemon off;'
