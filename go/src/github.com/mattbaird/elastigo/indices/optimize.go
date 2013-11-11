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
	"strconv"
	"strings"
)

// AnalyzeIndices performs the analysis process on a text and return the tokens breakdown of the text.
// http://www.elasticsearch.org/guide/reference/api/admin-indices-analyze/
func OptimizeIndices(max_num_segments int, only_expunge_deletes bool, refresh bool, flush bool, wait_for_merge bool,
	indices ...string) (OptimizeResponse, error) {
	var retval OptimizeResponse
	var optimizeUrl string = "/_optimize"
	if len(indices) > 0 {
		optimizeUrl = fmt.Sprintf("/%s/%s", strings.Join(indices, ","), optimizeUrl)
	}
	var values url.Values = url.Values{}
	if max_num_segments > 0 {
		values.Add("max_num_segments", strconv.Itoa(max_num_segments))
	}
	if only_expunge_deletes {
		values.Add("only_expunge_deletes", strconv.FormatBool(only_expunge_deletes))
	}
	if !refresh {
		values.Add("refresh", strconv.FormatBool(refresh))
	}
	if !flush {
		values.Add("flush", strconv.FormatBool(flush))
	}
	if wait_for_merge {
		values.Add("wait_for_merge", strconv.FormatBool(wait_for_merge))
	}

	optimizeUrl += "?" + values.Encode()

	body, err := api.DoCommand("POST", optimizeUrl, nil)
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

type OptimizeResponse struct {
	Ok     bool       `json:"ok"`
	Shards api.Status `json:"_shards"`
}
