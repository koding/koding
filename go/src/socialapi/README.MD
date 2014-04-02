# For Social API Developers

## get the watcher first
go get github.com/skelterjohn/rerun
go install github.com/skelterjohn/rerun
go build github.com/skelterjohn/rerun

## run the workers
../../../go/bin/rerun socialapi/workers/api -c vagrant -d
../../../go/bin/rerun socialapi/workers/topicfeed -c vagrant
../../../go/bin/rerun socialapi/workers/realtime -c vagrant -d
../../../go/bin/rerun socialapi/workers/followingfeed -c vagrant

## tests are here
go run ./go/src/socialapi/tests/*.go
