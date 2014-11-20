// Copyright 2013 Matthew Baird
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//     http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"flag"
	"fmt"
	elastigo "github.com/mattbaird/elastigo/lib"
	"log"
	"os"
)

var (
	host *string = flag.String("host", "localhost", "Elasticsearch Host")
)

func main() {
	c := elastigo.NewConn()
	log.SetFlags(log.LstdFlags)
	flag.Parse()

	fmt.Println("host = ", *host)
	// Set the Elasticsearch Host to Connect to
	c.Domain = *host

	// Index a document
	_, err := c.Index("testindex", "user", "docid_1", nil, `{"name":"bob"}`)
	exitIfErr(err)

	// Index a doc using a map of values
	_, err = c.Index("testindex", "user", "docid_2", nil, map[string]string{"name": "venkatesh"})
	exitIfErr(err)

	// Index a doc using Structs
	_, err = c.Index("testindex", "user", "docid_3", nil, MyUser{"wanda", 22})
	exitIfErr(err)

	// Search Using Raw json String
	searchJson := `{
	    "query" : {
	        "term" : { "Name" : "wanda" }
	    }
	}`
	out, err := c.Search("testindex", "user", nil, searchJson)
	if len(out.Hits.Hits) == 1 {
		fmt.Println("%v", out.Hits.Hits[0].Source)
	}
	exitIfErr(err)

}
func exitIfErr(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %s\n", err.Error())
		os.Exit(1)
	}
}

type MyUser struct {
	Name string
	Age  int
}
