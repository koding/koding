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
	"net/url"
	"strconv"
	"strings"
)

// Health gets a very simple status on the health of the cluster. This call defaults to no parameters
// see http://www.elasticsearch.org/guide/reference/api/admin-cluster-health.html
func Health(pretty bool, indices ...string) (ClusterHealthResponse, error) {
	return HealthWithParameters(pretty, "", "", "", 0, 0, indices...)
}

// HealthWithParameters gets cluster health data and exposes all parameters to the caller
// level - one of cluster, indices, or shards
// wait_for_status - green, yellow, or red. Will wait until the status changes to passed status
// wait_for_relocating_shards - How many relocating shards to wait for. Default no wait
// wait_for_nodes - The request waits until N nodes are available
// timeout - How long to wait if any wait_* params are passed. Defaults to 30s
func HealthWithParameters(pretty bool, level string, wait_for_status string, timeout string,
	wait_for_relocating_shards int, wait_for_nodes int, indices ...string) (ClusterHealthResponse, error) {
	var url string
	var retval ClusterHealthResponse
	url, err := getHealthUrl(pretty, level, wait_for_status, timeout, wait_for_relocating_shards, wait_for_nodes, indices...)
	if err != nil {
		return retval, err
	}
	body, err := api.DoCommand("GET", url, nil)
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
	return retval, err
}

func getHealthUrl(pretty bool, level string, wait_for_status string, timeout string,
	wait_for_relocating_shards int, wait_for_nodes int, indices ...string) (retval string, e error) {
	var partialURL string
	var values url.Values = url.Values{}
	partialURL = "/_cluster/health"
	// If indices are specified, append them before the query params
	if len(indices) > 0 {
		partialURL = fmt.Sprintf("%s/%s", partialURL, strings.Join(indices, ","))
	}
	// level - make sure it's one of cluster, indices or shards
	if len(level) > 0 {
		if level != "cluster" && level != "indices" && level != "shards" {
			return "", errors.New(fmt.Sprintf("level must be one of cluster, indices or shards. You passed %s", level))
		}
		values.Add("level", level)
	}
	// wait_for_status - make sure it's one of green, yellow, or red
	if len(wait_for_status) > 0 {
		if wait_for_status != "green" && wait_for_status != "yellow" && wait_for_status != "red" {
			return "", errors.New(fmt.Sprintf("wait_for_status must be one of green, yellow, or red. You passed %s", wait_for_status))
		}
		values.Add("wait_for_status", wait_for_status)
	}
	if wait_for_relocating_shards > 0 {
		values.Add("wait_for_relocating_shards", strconv.Itoa(wait_for_relocating_shards))
	}
	if wait_for_nodes > 0 {
		values.Add("wait_for_nodes", strconv.Itoa(wait_for_nodes))
	}
	if len(timeout) > 0 {
		values.Add("timeout", timeout)
	}
	if pretty {
		values.Add("pretty", strconv.FormatBool(pretty))
	}
	return partialURL + "?" + values.Encode(), nil
}

type ClusterHealthResponse struct {
	ClusterName         string `json:"cluster_name"`
	Status              string `json:"status"`
	TimedOut            bool   `json:"timed_out"`
	NumberOfNodes       int    `json:"number_of_nodes"`
	NumberOfDataNodes   int    `json:"number_of_data_nodes"`
	ActivePrimaryShards int    `json:"active_primary_shards"`
	ActiveShards        int    `json:"active_shards"`
	RelocatingShards    int    `json:"relocating_shards"`
	InitializingShards  int    `json:"initializing_shards"`
	UnassignedShards    int    `json:"unassigned_shards"`
}
