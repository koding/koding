#!/bin/bash

S3_CFG=$HOME/.s3cfg
echo "[default]" > $S3_CFG
echo "access_key=$S3_KEY_ID" >> $S3_CFG
echo "secret_key=$S3_KEY_SECRET" >> $S3_CFG
