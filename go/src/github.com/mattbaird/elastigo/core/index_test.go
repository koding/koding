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

package core

import (
	"fmt"
	u "github.com/araddon/gou"
	"testing"
)

func TestUrlGeneration(t *testing.T) {
	expectedUrl := "/Index/Type/Id?op_type=create&parent=Parent&percolate=Percolate&refresh=true&routing=Routing&timeout=Timeout&timestamp=TimeStamp&ttl=10&version=1"
	url, err := GetIndexUrl("Index", "Type", "Id", "Parent", 1, "create", "Routing", "TimeStamp", 10, "Percolate", "Timeout", true)
	u.Assert(err == nil, t, "err was not nil")
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGeneration Should get %s, instead got %s", expectedUrl, url))
}

func TestUrlGenerationNoIndex(t *testing.T) {
	_, err := GetIndexUrl("", "Type", "Id", "Parent", 1, "create", "Routing", "TimeStamp", 10, "Percolate", "Timeout", true)
	u.Assert(err != nil, t, "err should have been returned")
}

func TestUrlGenerationNoType(t *testing.T) {
	_, err := GetIndexUrl("Index", "", "Id", "Parent", 1, "create", "Routing", "TimeStamp", 10, "Percolate", "Timeout", true)
	u.Assert(err != nil, t, "err should have been returned")
}

func TestUrlGenerationNoId(t *testing.T) {
	expectedUrl := "/Index/Type?op_type=create&parent=Parent&percolate=Percolate&refresh=true&routing=Routing&timeout=Timeout&timestamp=TimeStamp&ttl=10&version=1"
	url, err := GetIndexUrl("Index", "Type", "", "Parent", 1, "create", "Routing", "TimeStamp", 10, "Percolate", "Timeout", true)
	u.Assert(err == nil, t, "err was not nil")
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGenerationNoId Should get %s, instead got %s", expectedUrl, url))
}

// if Id is blank, op_type should default to create
func TestUrlGenerationNoIdAndOpTypeNotCreate(t *testing.T) {
	expectedUrl := "/Index/Type?op_type=create&parent=Parent&percolate=Percolate&refresh=true&routing=Routing&timeout=Timeout&timestamp=TimeStamp&ttl=10&version=1"
	url, err := GetIndexUrl("Index", "Type", "", "Parent", 1, "notcreate", "Routing", "TimeStamp", 10, "Percolate", "Timeout", true)
	u.Assert(err == nil, t, "err was not nil")
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGenerationNoId Should get %s, instead got %s", expectedUrl, url))
}

func TestUrlGenerationNoParent(t *testing.T) {
	expectedUrl := "/Index/Type/Id?op_type=create&percolate=Percolate&refresh=true&routing=Routing&timeout=Timeout&timestamp=TimeStamp&ttl=10&version=1"
	url, err := GetIndexUrl("Index", "Type", "Id", "", 1, "create", "Routing", "TimeStamp", 10, "Percolate", "Timeout", true)
	u.Assert(err == nil, t, "err was not nil")
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGenerationNoParent Should get %s, instead got %s", expectedUrl, url))
}

func TestUrlGenerationNoVersion(t *testing.T) {
	expectedUrl := "/Index/Type/Id?op_type=create&parent=Parent&percolate=Percolate&refresh=true&routing=Routing&timeout=Timeout&timestamp=TimeStamp&ttl=10"
	url, err := GetIndexUrl("Index", "Type", "Id", "Parent", 0, "create", "Routing", "TimeStamp", 10, "Percolate", "Timeout", true)
	u.Assert(err == nil, t, "err was not nil")
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGenerationNoVersion Should get %s, instead got %s", expectedUrl, url))
}

func TestUrlGenerationNoOpType(t *testing.T) {
	expectedUrl := "/Index/Type/Id?parent=Parent&percolate=Percolate&refresh=true&routing=Routing&timeout=Timeout&timestamp=TimeStamp&ttl=10&version=1"
	url, err := GetIndexUrl("Index", "Type", "Id", "Parent", 1, "", "Routing", "TimeStamp", 10, "Percolate", "Timeout", true)
	u.Assert(err == nil, t, "err was not nil")
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGenerationNoOpType Should get %s, instead got %s", expectedUrl, url))
}
func TestUrlGenerationNoRouting(t *testing.T) {
	expectedUrl := "/Index/Type/Id?op_type=create&parent=Parent&percolate=Percolate&refresh=true&timeout=Timeout&timestamp=TimeStamp&ttl=10&version=1"
	url, err := GetIndexUrl("Index", "Type", "Id", "Parent", 1, "create", "", "TimeStamp", 10, "Percolate", "Timeout", true)
	u.Assert(err == nil, t, "err was not nil")
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGenerationNoRouting Should get %s, instead got %s", expectedUrl, url))
}
func TestUrlGenerationNoTimestamp(t *testing.T) {
	expectedUrl := "/Index/Type/Id?op_type=create&parent=Parent&percolate=Percolate&refresh=true&routing=Routing&timeout=Timeout&ttl=10&version=1"
	url, err := GetIndexUrl("Index", "Type", "Id", "Parent", 1, "create", "Routing", "", 10, "Percolate", "Timeout", true)
	u.Assert(err == nil, t, "err was not nil")
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGenerationNoTimestamp Should get %s, instead got %s", expectedUrl, url))
}
func TestUrlGenerationNoTTL(t *testing.T) {
	expectedUrl := "/Index/Type/Id?op_type=create&parent=Parent&percolate=Percolate&refresh=true&routing=Routing&timeout=Timeout&timestamp=TimeStamp&version=1"
	url, err := GetIndexUrl("Index", "Type", "Id", "Parent", 1, "create", "Routing", "TimeStamp", 0, "Percolate", "Timeout", true)
	u.Assert(err == nil, t, "err was not nil")
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGenerationNoTTL Should get %s, instead got %s", expectedUrl, url))
}
func TestUrlGenerationNoPercolate(t *testing.T) {
	expectedUrl := "/Index/Type/Id?op_type=create&parent=Parent&refresh=true&routing=Routing&timeout=Timeout&timestamp=TimeStamp&ttl=10&version=1"
	url, err := GetIndexUrl("Index", "Type", "Id", "Parent", 1, "create", "Routing", "TimeStamp", 10, "", "Timeout", true)
	u.Assert(err == nil, t, "err was not nil")
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGenerationNoPercolate Should get %s, instead got %s", expectedUrl, url))
}
func TestUrlGenerationNoTimeout(t *testing.T) {
	expectedUrl := "/Index/Type/Id?op_type=create&parent=Parent&percolate=Percolate&refresh=true&routing=Routing&timestamp=TimeStamp&ttl=10&version=1"
	url, err := GetIndexUrl("Index", "Type", "Id", "Parent", 1, "create", "Routing", "TimeStamp", 10, "Percolate", "", true)
	u.Assert(err == nil, t, "err was not nil")
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGenerationNoTimeout Should get %s, instead got %s", expectedUrl, url))
}
func TestUrlGenerationNoRefresh(t *testing.T) {
	expectedUrl := "/Index/Type/Id?op_type=create&parent=Parent&percolate=Percolate&routing=Routing&timeout=Timeout&timestamp=TimeStamp&ttl=10&version=1"
	url, err := GetIndexUrl("Index", "Type", "Id", "Parent", 1, "create", "Routing", "TimeStamp", 10, "Percolate", "Timeout", false)
	u.Assert(err == nil, t, "err was not nil")
	u.Assert(url == expectedUrl, t, fmt.Sprintf("TestUrlGenerationNoRefresh Should get %s, instead got %s", expectedUrl, url))
}
