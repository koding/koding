#!/bin/bash
for i in *.json ; do cfn-create-stack  prod-webstack-b-${i%.tmpl.json} --template-file $i ; done
