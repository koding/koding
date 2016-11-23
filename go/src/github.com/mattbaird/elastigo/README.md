elastigo v2.0 
-------------

[![Build Status][1]][2] 
[1]: https://drone.io/github.com/mattbaird/elastigo/status.png 
[2]: https://drone.io/github.com/mattbaird/elastigo/latest
[![Total views](https://sourcegraph.com/api/repos/github.com/mattbaird/elastigo/counters/views.png)](https://sourcegraph.com/github.com/mattbaird/elastigo)


A Go (Golang) based Elasticsearch client, implements core api for Indexing and searching.   
GoDoc http://godoc.org/github.com/mattbaird/elastigo


NOTE: Based on the great work from Jeremy Shute, Elastigo now supports multiple connections. We attempted to make this backwards compatible, however in the end it wasn't possible, so we tagged the older single connection code as v1.0 and started work on v2.0.

If you want to use v1.0, you can use a tool like GoDep to make that possible. See http://bit.ly/VLG2et for full details.

The godep tool saves the exact version of the dependencies you’re building your project against, which means that upstream modifications in third-party dependencies won’t break your build.

```bash
go get github.com/tools/godep
```

Now, to pull in an existing project with godep:
```bash
	godep go get github.com/myuser/myproject
```

When your code compiles in your workspace, ala:

```bash
cd $HOME/gopath/src/github.com/myuser/myproject
# hack hack hack
go build ./...
```

You can freeze your dependencies thusly:

```bash
godep save github.com/myuser/myproject
git add Godeps
```

The godep tool will examine your code to find and save the transitive closure of your dependencies in the current directory, observing their versions.  If you want to restore or update these versions, see the documentation for the tool.

Note, in particular, that if your current directory contains a group of binaries or packages, you may save all of them at once:

```bash
godep save ./...
```

To get the Chef based Vagrantfile working, be sure to pull like so::

    # This will pull submodules.
    git clone --recursive git@github.com:mattbaird/elastigo.git

It's easier to use the ElasticSearch provided Docker image found here: https://github.com/dockerfile/elasticsearch

Non-persistent usage is:
```bash
docker run -d -p 9200:9200 -p 9300:9300 dockerfile/elasticsearch
```

Quick Start with Docker
=======================
Make sure docker is installed. If you are running docker on a mac, you must expose ports 9200 and 9300. Shut down docker:
```bash
boot2docker stop
```
and run
```bash
for i in {9200..9300}; do
 VBoxManage modifyvm "boot2docker-vm" --natpf1 "tcp-port$i,tcp,,$i,,$i";
 VBoxManage modifyvm "boot2docker-vm" --natpf1 "udp-port$i,udp,,$i,,$i";
done
```
The following will allow you to get the code, and run the tests against your docker based non-persistent elasticsearch:

```bash
docker run -d -p 9200:9200 -p 9300:9300 dockerfile/elasticsearch
git clone git@github.com:mattbaird/elastigo.git
cd elastigo
go get -u ./...
cd lib
go test -v -host localhost -loaddata
cd ..
go test -v ./...
```

Usage Examples - Currently out of date, being rewritten for v2.0
----------------------------------------------------------------

Adding content to Elasticsearch
-------------------------------

```go
import "github.com/mattbaird/elastigo/api"
import "github.com/mattbaird/elastigo/core"

type Tweet struct {
  User     string    `json:"user"`
  Message  string    `json:"message"`
}

// Set the Elasticsearch Host to Connect to
api.Domain = "localhost"
// api.Port = "9300"

// add single go struct entity
response, _ := core.Index("twitter", "tweet", "1", nil, Tweet{"kimchy", "Search is cool"})

// you have bytes
tw := Tweet{"kimchy", "Search is cool part 2"}
bytesLine, err := json.Marshal(tw)
response, _ := core.Index("twitter", "tweet", "2", nil, bytesLine)

// Bulk Indexing
t := time.Now()
core.IndexBulk("twitter", "tweet", "3", &t, Tweet{"kimchy", "Search is now cooler"})

// Search Using Raw json String
searchJson := `{
    "query" : {
        "term" : { "user" : "kimchy" }
    }
}`
out, err := core.SearchRequest(true, "twitter", "tweet", searchJson, "")
if len(out.Hits.Hits) == 1 {
  fmt.Println(string(out.Hits.Hits[0].Source))
}
```

A Faceted, ranged Search using the `Search DSL` :

```go
import "github.com/mattbaird/elastigo/api"
import "github.com/mattbaird/elastigo/core"

// Set the Elasticsearch Host to Connect to
api.Domain = "localhost"
// api.Port = "9300"

out, err := Search("github").Size("1").Facet(
  Facet().Fields("actor").Size("500"),
).Query(
  Query().Range(
     Range().Field("created_at").From("2012-12-10T15:00:00-08:00").To("2012-12-10T15:10:00-08:00"),
  ).Search("add"),
).Result()
```

A Ranged Search using the `Search DSL` :

```go
out, err := Search("github").Type("Issues").Pretty().Query(
  Query().Range(
     Range().Field("created_at").From("2012-12-10T15:00:00-08:00").To("2012-12-10T15:10:00-08:00"),
  ).Search("add"),
).Result()
```

A Simple Search using the `Search DSL` :

```go
out, err := Search("github").Type("Issues").Size("100").Search("add").Result()
```

A Direct Search using the api :

```go
qry := map[string]interface{}{
  "query":map[string]interface{}{
     "term":map[string]string{"user": "kimchy"},
  },
}
core.SearchRequest(true, "github", "Issues", qry, "", 0)
```

A Direct Search using the query string Api :

```go
core.SearchUri("github", "Issues", "user:kimchy", "", 0)
```

A Filtered search `Search DSL` :

```go
out, err := Search("github").Filter(
  Filter().Exists("repository.name"),
).Result()
```

Adding content to Elasticsearch in Bulk
----------------------------------------------

```go
import "github.com/mattbaird/elastigo/api"
import "github.com/mattbaird/elastigo/core"

// Set the Elasticsearch Host to Connect to
api.Domain = "localhost"
// api.Port = "9300"

indexer := core.NewBulkIndexerErrors(10, 60)
done := make(chan bool)
indexer.Run(done)

go func() {
  for errBuf := range indexer.ErrorChannel {
    // just blissfully print errors forever
    fmt.Println(errBuf.Err)
  }
}()
for i := 0; i < 20; i++ {
  indexer.Index("twitter", "user", strconv.Itoa(i), "", nil, `{"name":"bob"}`, false)
}
done <- true
// Indexing might take a while. So make sure the program runs
// a little longer when trying this in main.
```

status updates
========================

* *2014-07-09* Version 2.0 development started. Focused on multi-connection support, using Dial idiom.
* *2014-5-21* Note: Drone.io tests are failing, I don't know why because the build and tests are working fine for me on my ubuntu box running the docker elasticsearch image. It's possible there is a timing issue. Any Ideas?
* *2013-9-27* Fleshing out cluster and indices APIs, updated vagrant image to 0.90.3
* *2013-7-10* Improvements/changes to bulk indexer (includes breaking changes to support TTL),
         Search dsl supports And/Or/Not
    * *SearchDsl* should still be considered beta at this
         point, there will be minor breaking changes as more of the
         elasticsearch feature set is implemented.
* *2013-1-26* expansion of search dsl for greater coverage
* *2012-12-30* new bulk indexing and search dsl
* *2012-10-12* early in development, not ready for production yet.

license
=======
    Copyright 2012 Matthew Baird, Aaron Raddon, Jeremy Shute and more!

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
