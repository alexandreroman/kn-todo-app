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
GET $FQDN
GET $FQDN/js/api.js
GET $FQDN/js/app.js
GET $FQDN/js/axios.min.js
GET $FQDN/js/axios.min.map
GET $FQDN/js/director.min.js
GET $FQDN/js/routes.js
GET $FQDN/js/store.js
GET $FQDN/js/sync.js
GET $FQDN/js/vue.min.js
GET $FQDN/css/styles.css
EOF

vegeta attack -targets "$TARGETS_FILE" -duration=60s -rate 5 -workers 1 | vegeta report
