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

package search

import (
	"flag"
	"github.com/araddon/gou"
	"github.com/mattbaird/elastigo/api"
	"github.com/mattbaird/elastigo/core"
	"log"
	"os"
	//"testing"
)

var (
	_                 = log.Ldate
	hasStartedTesting bool
	eshost            *string = flag.String("host", "localhost", "Elasticsearch Server Host Address")
	logLevel          *string = flag.String("logging", "info", "Which log level: [debug,info,warn,error,fatal]")
)

/*

usage:

	test -v -host eshost

*/

func init() {
	InitTests(false)
	if *logLevel == "debug" {
		//*logLevel = "debug"
		core.DebugRequests = true
	}
}

func InitTests(startIndexor bool) {
	if !hasStartedTesting {
		flag.Parse()
		hasStartedTesting = true
		gou.SetLogger(log.New(os.Stderr, "", log.Ltime|log.Lshortfile), *logLevel)
		log.SetFlags(log.Ltime | log.Lshortfile)
		api.Domain = *eshost
	}
}
