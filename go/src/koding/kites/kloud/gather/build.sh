#!/usr/bin/env bash
echo "This script builds and uploads 'check' binary to s3"
echo "Requires 'go' installed with linux_386 cross compilation and 'aws'"
echo ""

echo "Building..."

cd check/
go-bindata -o ./checkers.go checkers/
GOOS=linux GOARCH=386 CGO_ENABLED=0 go build
tar -cf check.tar check

echo "Uploading to s3..."
aws s3 cp check.tar s3://gather-vm-metrics

echo "Cleaning up..."
rm check check.tar

echo "Done"
