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

package indices

import (
	"encoding/json"
	"fmt"
	"github.com/mattbaird/elastigo/api"
	"net/url"
	"strings"
)

// ClearCache allows to clear either all caches or specific cached associated with one ore more indices.
// see http://www.elasticsearch.org/guide/reference/api/admin-indices-clearcache/
func ClearCache(clearId bool, clearBloom bool, indices ...string) (api.ExtendedStatus, error) {
	var retval api.ExtendedStatus
	var clearCacheUrl string
	if len(indices) > 0 {
		clearCacheUrl = fmt.Sprintf("/%s/_cache/clear", strings.Join(indices, ","))

	} else {
		clearCacheUrl = fmt.Sprintf("/_cache/clear")
	}
	var values url.Values = url.Values{}

	if clearId {
		values.Add("id", "true")
	}
	if clearBloom {
		values.Add("bloom", "true")
	}
	clearCacheUrl += "?" + values.Encode()
	body, err := api.DoCommand("POST", clearCacheUrl, nil)
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
