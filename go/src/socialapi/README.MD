# For Social API Developers

## get the watcher first
go get github.com/skelterjohn/rerun
go install github.com/skelterjohn/rerun
go build github.com/skelterjohn/rerun

## run the workers

``` sh

// main api
../../../go/bin/rerun socialapi/workers/api -c vagrant -d
// to create topic feed
../../../go/bin/rerun socialapi/workers/topicfeed -c vagrant
// sending realtime updates
../../../go/bin/rerun socialapi/workers/realtime -c vagrant -d
// generating following feed
../../../go/bin/rerun socialapi/workers/followingfeed -c vagrant

```

## tests are here
go run ./go/src/socialapi/tests/*.go
