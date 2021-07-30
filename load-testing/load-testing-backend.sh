#!/usr/bin/env bash

set -e
set -o pipefail

DOMAIN=$1
if [[ "$DOMAIN" == "" ]]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

FQDN=$DOMAIN
if [[ "$DOMAIN" != "http://"* ]] && [[ "$DOMAIN" != "https://"* ]]; then
  FQDN=https://$DOMAIN
fi

echo "Load testing: $FQDN"

TARGETS_FILE=$(mktemp /tmp/vegeta-targets.XXXXXX)
cat > "$TARGETS_FILE" <<EOF
GET $FQDN/api/todos
EOF

vegeta attack -targets "$TARGETS_FILE" -duration=60s -rate 200 | vegeta report
