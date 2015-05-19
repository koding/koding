#!/usr/bin/env bash
cd ~; find . -maxdepth 2 -type f -name '*.*' -not -path "*/.gem/*" -not -path "*.npm/*" -not -path "*node_modules/*" | sed 's|.*\.||' | sort | uniq -c | sort -n
