#!/bin/bash
# .ebextensions/datadog/hooks/99stop_datadog.sh
if [ -e /etc/init.d/datadog-agent ]; then
  /etc/init.d/datadog-agent stop
fi

