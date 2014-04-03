# For Social API Developers

## get the watcher first

``` sh
go get github.com/skelterjohn/rerun
go install github.com/skelterjohn/rerun
go build github.com/skelterjohn/rerun

```
## run the workers

``` sh

// main api
../../../go/bin/rerun socialapi/workers/api -c ./config/vagrant.toml -d
// to create topic feed
../../../go/bin/rerun socialapi/workers/topicfeed -c ./config/vagrant.toml -d
// sending realtime updates
../../../go/bin/rerun socialapi/workers/realtime -c ./config/vagrant.toml -d
// generating following feed
../../../go/bin/rerun socialapi/workers/followingfeed -c ./config/vagrant.toml -d

```

## tests are here
go run ./go/src/socialapi/tests/*.go
