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

package cluster

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/mattbaird/elastigo/api"
)

// The cluster health API allows to get a very simple status on the health of the cluster.
// see http://www.elasticsearch.org/guide/reference/api/admin-cluster-health.html
// TODO: implement wait_for_status, timeout, wait_for_relocating_shards, wait_for_nodes
// TODO: implement level (Can be one of cluster, indices or shards. Controls the details level of the health
// information returned. Defaults to cluster.)
func Reroute(pretty bool, dryRun bool, commands Commands) (ClusterHealthResponse, error) {
	var url string
	var retval ClusterHealthResponse
	if len(commands.Commands) > 0 {
		url = fmt.Sprintf("/_cluster/reroute%s&%s", api.Pretty(pretty), dryRunOption(dryRun))
	} else {
		return retval, errors.New("Must pass at least one command")
	}
	body, err := api.DoCommand("POST", url, commands)
	if err != nil {
		return retval, err
	}
	if err == nil {
		// marshall into json
		jsonErr := json.Unmarshal(body, &retval)
		if jsonErr != nil {
			return retval, jsonErr
		}
	}
	fmt.Println(body)
	return retval, err
}

func dryRunOption(isDryRun bool) string {
	if isDryRun {
		return "dry_run"
	} else {
		return ""
	}
	return ""
}

// supported commands are
// move (index, shard, from_node, to_node)
// cancel (index, shard, node, allow_primary)
// allocate (index, shard, node, allow_primary)

type Commands struct {
	Commands []interface{} `json:"commands"`
}

type MoveCommand struct {
	Index    string `json:"index"`
	Shard    string `json:"shard"`
	FromNode string `json:"from_node"`
	ToNode   string `json:"to_node"`
}

type CancelCommand struct {
	Index        string `json:"index"`
	Shard        string `json:"shard"`
	Node         string `json:"node"`
	AllowPrimary bool   `json:"allow_primary,omitempty"`
}
type AllocateCommand struct {
	Index        string `json:"index"`
	Shard        string `json:"shard"`
	Node         string `json:"node"`
	AllowPrimary bool   `json:"allow_primary,omitempty"`
}
