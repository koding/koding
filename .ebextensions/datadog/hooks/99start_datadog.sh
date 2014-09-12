#!/bin/bash
# .ebextensions/datadog/hooks/99start_datadog.sh
if [ -e /etc/init.d/datadog-agent ]; then
  /etc/init.d/datadog-agent start
fi
