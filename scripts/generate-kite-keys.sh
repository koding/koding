#!/bin/bash

set -euo pipefail

REPO_HOME=${KONFIG_PROJECTROOT:-$(git rev-parse --show-toplevel)}

# TODO(rjeczalik): GEN-2535
KONTROL_URL=${KONFIG_KONTROL_URL:-"http://127.0.0.1:3000/kite"}

KONTROL_DIR="${REPO_HOME}/generated/private_keys/kontrol"
KLOUD_DIR="${REPO_HOME}/generated/private_keys/kloud"
KITE_DIR="${REPO_HOME}/generated/kite_home/koding"

if [[ ! -f "${KONTROL_DIR}/kontrol.pem" ]]; then
	mkdir -p "${KONTROL_DIR}"
	openssl genrsa -out "${KONTROL_DIR}/kontrol.pem" 2048 &>/dev/null
	openssl rsa -in "${KONTROL_DIR}/kontrol.pem" -outform PEM -pubout -out "${KONTROL_DIR}/kontrol.pub" &>/dev/null
fi

if [[ ! -f "${KLOUD_DIR}/kloud.pem" ]]; then
	mkdir -p "${KLOUD_DIR}"
	ssh-keygen -q -N "" -t rsa -C hello@koding.com -f "${KLOUD_DIR}/kloud.pem"
	mv "${KLOUD_DIR}"/kloud{.pem,}.pub
fi

if [[ ! -f "${KITE_DIR}/kite.key" ]]; then
	mkdir -p "${KITE_DIR}"
	go run "${REPO_HOME}/go/src/koding/kites/kloud/scripts/kitekey/main.go" \
		-pem "${KONTROL_DIR}/kontrol.pem" \
		-pub "${KONTROL_DIR}/kontrol.pub" \
		-kontrolurl "${KONTROL_URL}" \
		-username koding \
		-file "${KITE_DIR}/kite.key"
fi
