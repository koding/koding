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
	"log"
	"time"

	elastigo "github.com/mattbaird/elastigo/lib"
)

var (
	eshost *string = flag.String("host", "localhost", "Elasticsearch Server Host Address")
)

// for testing
func main() {
	flag.Parse()
	log.SetFlags(log.Ltime | log.Lshortfile)

	c := elastigo.NewConn()
	c.Domain = *eshost
	response, _ := c.Index("twitter", "tweet", "1", nil, NewTweet("kimchy", "Search is cool"))
	c.Flush()
	log.Printf("Index OK: %v", response.Ok)
	searchresponse, err := c.Search("twitter", "tweet", nil, "{\"query\" : {\"term\" : { \"user\" : \"kimchy\" }}}")
	if err != nil {
		log.Println("error during search:" + err.Error())
		log.Fatal(err)
	}
	// try marshalling to tweet type
	var t Tweet
	bytes, err := searchresponse.Hits.Hits[0].Source.MarshalJSON()
	if err != nil {
		log.Fatalf("err calling marshalJson:%v", err)
	}
	json.Unmarshal(bytes, t)
	log.Printf("Search Found: %s", t)
	response, _ = c.Get("twitter", "tweet", "1", nil)
	log.Printf("Get: %v", response.Exists)
	exists, _ := c.Exists("twitter", "tweet", "1", nil)
	log.Printf("Exists: %v", exists)
	c.Flush()
	countResponse, _ := c.Count("twitter", "tweet", nil, nil)

	log.Printf("Count: %v", countResponse.Count)
	response, _ = c.Delete("twitter", "tweet", "1", map[string]interface{}{"version": -1, "routing": ""})
	log.Printf("Delete OK: %v", response.Ok)
	response, _ = c.Get("twitter", "tweet", "1", nil)
	log.Printf("Get: %v", response.Exists)

	healthResponse, _ := c.Health()
	log.Printf("Health: %v", healthResponse.Status)

	c.UpdateSettings("transient", "discovery.zen.minimum_master_nodes", 2)
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
