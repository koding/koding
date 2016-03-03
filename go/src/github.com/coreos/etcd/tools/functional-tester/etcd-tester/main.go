// Copyright 2015 CoreOS, Inc.
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
	"flag"
	"net/http"
	"strings"

	"github.com/coreos/etcd/Godeps/_workspace/src/github.com/coreos/pkg/capnslog"
	"github.com/coreos/etcd/Godeps/_workspace/src/github.com/prometheus/client_golang/prometheus"
)

var plog = capnslog.NewPackageLogger("github.com/coreos/etcd", "etcd-tester")

func main() {
	endpointStr := flag.String("agent-endpoints", "localhost:9027", "HTTP RPC endpoints of agents. Do not specify the schema.")
	datadir := flag.String("data-dir", "agent.etcd", "etcd data directory location on agent machine.")
	stressKeySize := flag.Int("stress-key-size", 100, "the size of each key written into etcd.")
	stressKeySuffixRange := flag.Int("stress-key-count", 250000, "the count of key range written into etcd.")
	limit := flag.Int("limit", 3, "the limit of rounds to run failure set.")
	isV2Only := flag.Bool("v2-only", false, "'true' to run V2 only tester.")
	flag.Parse()

	endpoints := strings.Split(*endpointStr, ",")
	c, err := newCluster(endpoints, *datadir, *stressKeySize, *stressKeySuffixRange, *isV2Only)
	if err != nil {
		plog.Fatal(err)
	}
	defer c.Terminate()

	t := &tester{
		failures: []failure{
			newFailureKillAll(),
			newFailureKillMajority(),
			newFailureKillOne(),
			newFailureKillLeader(),
			newFailureKillOneForLongTime(),
			newFailureKillLeaderForLongTime(),
			newFailureIsolate(),
			newFailureIsolateAll(),
		},
		cluster: c,
		limit:   *limit,
	}

	sh := statusHandler{status: &t.status}
	http.Handle("/status", sh)
	http.Handle("/metrics", prometheus.Handler())
	go func() { plog.Fatal(http.ListenAndServe(":9028", nil)) }()

	t.runLoop()
}
