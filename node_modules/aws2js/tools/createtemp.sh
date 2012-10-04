#!/bin/sh

dd if=/dev/urandom of=10M.tmp bs=1M count=10 2>/dev/null
md5sum 10M.tmp | cut -d' ' -f1
