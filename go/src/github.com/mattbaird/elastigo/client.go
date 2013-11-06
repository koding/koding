// Copyright 2012 Matthew Baird
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package main

import (
	"encoding/json"
	"flag"
	"github.com/mattbaird/elastigo/api"
	"github.com/mattbaird/elastigo/cluster"
	"github.com/mattbaird/elastigo/core"
	"github.com/mattbaird/elastigo/indices"
	"log"
	"time"
)

var (
	eshost *string = flag.String("host", "localhost", "Elasticsearch Server Host Address")
)

// for testing
func main() {
	flag.Parse()
	log.SetFlags(log.Ltime | log.Lshortfile)
	api.Domain = *eshost
	response, _ := core.Index(true, "twitter", "tweet", "1", NewTweet("kimchy", "Search is cool"))
	indices.Flush()
	log.Printf("Index OK: %v", response.Ok)
	searchresponse, err := core.SearchRequest(true, "twitter", "tweet", "{\"query\" : {\"term\" : { \"user\" : \"kimchy\" }}}", "", 0)
	if err != nil {
		log.Println("error during search:" + err.Error())
		log.Fatal(err)
	}
	// try marshalling to tweet type
	var t Tweet
	json.Unmarshal(searchresponse.Hits.Hits[0].Source, t)
	log.Printf("Search Found: %s", t)
	response, _ = core.Get(true, "twitter", "tweet", "1")
	log.Printf("Get: %v", response.Exists)
	exists, _ := core.Exists(true, "twitter", "tweet", "1")
	log.Printf("Exists: %v", exists)
	indices.Flush()
	countResponse, _ := core.Count(true, "twitter", "tweet")
	log.Printf("Count: %v", countResponse.Count)
	response, _ = core.Delete(true, "twitter", "tweet", "1", -1, "")
	log.Printf("Delete OK: %v", response.Ok)
	response, _ = core.Get(true, "twitter", "tweet", "1")
	log.Printf("Get: %v", response.Exists)

	healthResponse, _ := cluster.Health(true)
	log.Printf("Health: %v", healthResponse.Status)

	cluster.UpdateSettings("transient", "discovery.zen.minimum_master_nodes", 2)

}

// used in test suite, chosen to be similar to the documentation
type Tweet struct {
	User     string    `json:"user"`
	PostDate time.Time `json:"postDate"`
	Message  string    `json:"message"`
}

func NewTweet(user string, message string) Tweet {
	return Tweet{User: user, PostDate: time.Now(), Message: message}
}

func (t *Tweet) String() string {
	b, _ := json.Marshal(t)
	return string(b)
}
