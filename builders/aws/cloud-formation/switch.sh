#!/bin/bash

cfn-update-stack prod-webstack-b-web --template-file ./json/prod/prod-webstack-b/web_server.tmpl.json
cfn-update-stack prod-webstack-a-web --template-file  ./json/prod/prod-webstack-a/web_server.tmpl.json

cfn-update-stack prod-webstack-b-broker --template-file  ./json/prod/prod-webstack-b/broker.tmpl.json
cfn-update-stack prod-webstack-a-broker --template-file  ./json/prod/prod-webstack-a/broker.tmpl.json
