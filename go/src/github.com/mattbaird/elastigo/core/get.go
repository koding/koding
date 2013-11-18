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

// Get allows caller to get a typed JSON document from the index based on its id.
// GET - retrieves the doc
// HEAD - checks for existence of the doc
// http://www.elasticsearch.org/guide/reference/api/get.html
// TODO: make this implement an interface
func Get(pretty bool, index string, _type string, id string) (api.BaseResponse, error) {
	var url string
	var retval api.BaseResponse
	if len(_type) > 0 {
		url = fmt.Sprintf("/%s/%s/%s?%s", index, _type, id, api.Pretty(pretty))
	} else {
		url = fmt.Sprintf("/%s/%s?%s", index, id, api.Pretty(pretty))
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
	//fmt.Println(body)
	return retval, err
}

// GetSource retrieves the document by id and converts it to provided interface
func GetSource(index string, _type string, id string, source interface{}) error {
  url := fmt.Sprintf("/%s/%s/%s/_source", index, _type, id)
	body, err := api.DoCommand("GET", url, nil)
	if err == nil {
		err = json.Unmarshal(body, &source)
	}
	//fmt.Println(body)
  return err
}

// Exists allows caller to check for the existance of a document using HEAD
func Exists(pretty bool, index string, _type string, id string) (bool, error) {

	var url string

	var response map[string]interface{}

	if len(_type) > 0 {
		url = fmt.Sprintf("/%s/%s/%s?fields=_id%s", index, _type, id, api.Pretty(pretty))
	} else {
		url = fmt.Sprintf("/%s/%s?fields=_id%s", index, id, api.Pretty(pretty))
	}

	req, err := api.ElasticSearchRequest("HEAD", url)

	if err != nil {
		fmt.Println(err)
	}

	httpStatusCode, _, err := req.Do(&response)

	if err != nil {
		return false, err
	}
	if httpStatusCode == 404 {
		return false, err
	} else {
		return true, err
	}
}
