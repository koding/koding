#!/usr/bin/env bash
find . -maxdepth 5 -type f -name '*.*' -not -path "*/.gem/*" -not -path "*.npm/*" -not -path "*node_modules/*" | sed 's|.*\.||' | sort | uniq -c | sort -n
