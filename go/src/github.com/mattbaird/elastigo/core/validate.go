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
	"encoding/json"
	"fmt"
	"github.com/mattbaird/elastigo/api"
)

// Validate allows a user to validate a potentially expensive query without executing it.
// see http://www.elasticsearch.org/guide/reference/api/validate.html
func Validate(pretty bool, index string, _type string, query string, explain bool) (api.BaseResponse, error) {
	var url string
	var retval api.BaseResponse
	if len(_type) > 0 {
		url = fmt.Sprintf("/%s/%s/_validate/query?q=%s&%s&explain=%s", index, _type, query, api.Pretty(pretty), explain)
	} else {
		url = fmt.Sprintf("/%s/_validate/query?q=%s&%s&explain=%s", index, query, api.Pretty(pretty), explain)
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
	fmt.Println(body)
	return retval, err
}

type Validation struct {
	Valid         bool           `json:"valid"`
	Shards        api.Status     `json:"_shards"`
	Explainations []Explaination `json:"explanations,omitempty"`
}

type Explaination struct {
	Index string `json:"index"`
	Valid bool   `json:"valid"`
	Error string `json:"error"`
}
