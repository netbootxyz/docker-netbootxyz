#!/bin/bash

# Check TFTP (UDP 69)
if ! nc -z -u -w2 127.0.0.1 69; then
  echo "TFTP check failed"
  exit 1
fi

# Check HTTP (nginx)
if ! curl -fs http://127.0.0.1:${NGINX_PORT:-80}/ > /dev/null; then
  echo "HTTP check failed"
  exit 1
fi

# Check Web App
if ! curl -fs http://127.0.0.1:${WEB_APP_PORT:-3000}${SUBFOLDER:-/} > /dev/null; then
  echo "Web App check failed"
  exit 1
fi

exit 0
