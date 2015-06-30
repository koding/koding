#! /bin/bash
set -o errexit

export CONFIG_EBENVNAME="cihangir3"
export CONFIG_REGION="us-east-1"
export CONFIG_AUTOSCALINGNAME="awseb-e-ps6yvwi873-stack-AWSEBAutoScalingGroup-H7SOTEVY95MP"
export CONFIG_ACCESSKEYID="AKIAIM3GAPJAIWTFZOJQ"
export CONFIG_SECRETACCESSKEY="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"
export CONFIG_DEBUG="true"

go test -c && ./tunnelproxymanager.test
rm ./tunnelproxymanager.test
