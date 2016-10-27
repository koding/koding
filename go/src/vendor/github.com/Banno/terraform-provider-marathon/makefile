.PHONY: vet linux osx build test release

vet:
	go tool vet *.go marathon/*.go

linux:
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o bin/terraform-provider-marathon-linux .

osx:
	GOOS=darwin GOARCH=386 go build -o bin/terraform-provider-marathon-osx .

build: vet osx linux
	go install .

test: build
	big inventory add marathon
	big up -d marathon
	sleep 5
	TF_LOG=TRACE TF_LOG_PATH=./test-sh-tf.log TF_ACC=yes MARATHON_URL=https://marathon.dev.banno.com go test ./marathon -v

release:
	./bin/release.sh
