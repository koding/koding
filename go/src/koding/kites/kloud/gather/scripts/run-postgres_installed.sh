#!/usr/bin/env bash
MYDIR="$(dirname "$(which "$0")")"
$MYDIR/installed.sh "PostgreSQL" psql
