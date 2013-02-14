#!/bin/bash
for i in *.json ; do cfn-update-stack  prod-webstack-a-${i%.tmpl.json} --template-file $i ; done
