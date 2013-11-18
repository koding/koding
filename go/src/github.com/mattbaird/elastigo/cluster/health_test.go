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
	"fmt"
	u "github.com/araddon/gou"
	"testing"
)

func TestUrlGeneration(t *testing.T) {
	expectedUrl := "/_cluster/health/Indice1,Indice2,Indice3?level=cluster&pretty=true&timeout=30s&wait_for_nodes=1&wait_for_relocating_shards=1&wait_for_status=green"
	indices := []string{"Indice1", "Indice2", "Indice3"}
	url, err := getHealthUrl(true, "cluster", "green", "30s", 1, 1, indices...)
	u.Assert(err == nil, t, fmt.Sprintf("err was not nil: %v", err))
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGeneration Should get %s, instead got %s", expectedUrl, url))
}

func TestUrlGenerationNoIndices(t *testing.T) {
	expectedUrl := "/_cluster/health?level=cluster&pretty=true&timeout=30s&wait_for_nodes=1&wait_for_relocating_shards=1&wait_for_status=green"
	indices := []string{}
	url, err := getHealthUrl(true, "cluster", "green", "30s", 1, 1, indices...)
	u.Assert(err == nil, t, fmt.Sprintf("err was not nil: %v", err))
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGeneration Should get %s, instead got %s", expectedUrl, url))
}

func TestUrlGenerationNoWaits(t *testing.T) {
	expectedUrl := "/_cluster/health/Indice1,Indice2,Indice3?level=cluster&pretty=true&timeout=30s&wait_for_status=green"
	indices := []string{"Indice1", "Indice2", "Indice3"}
	url, err := getHealthUrl(true, "cluster", "green", "30s", 0, 0, indices...)
	u.Assert(err == nil, t, fmt.Sprintf("err was not nil: %v", err))
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGeneration Should get %s, instead got %s", expectedUrl, url))
}

func TestUrlGenerationBadLevel(t *testing.T) {
	indices := []string{"Indice1", "Indice2", "Indice3"}
	_, err := getHealthUrl(true, "Level", "Wait_For_Status", "Timeout", 1, 1, indices...)
	u.Assert(err != nil, t, fmt.Sprintf("Call should have failed with bad Level parameter: %v", err))
}
func TestUrlGenerationBadWaitForStatus(t *testing.T) {
	indices := []string{"Indice1", "Indice2", "Indice3"}
	_, err := getHealthUrl(true, "cluster", "Wait_For_Status", "Timeout", 1, 1, indices...)
	u.Assert(err != nil, t, fmt.Sprintf("Call should have failed with bad wait_for_status parameter: %v", err))
}
