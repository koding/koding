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
	"errors"
	"fmt"
	"github.com/mattbaird/elastigo/api"
	"net/url"
	"strconv"
)

// Index adds or updates a typed JSON document in a specific index, making it searchable, creating an index
// if it did not exist.
// if id is omited, op_type 'create' will be pased and http method will default to "POST"
// id is optional
// parentId is optional
// version is optional
// op_type is optional
// routing is optional
// timestamp is optional
// ttl is optional
// percolate is optional
// timeout is optional
// http://www.elasticsearch.org/guide/reference/api/index_.html
func Index(pretty bool, index string, _type string, id string, data interface{}) (api.BaseResponse, error) {
	return IndexWithParameters(pretty, index, _type, id, "", 0, "", "", "", 0, "", "", false, data)
}

// IndexWithParameters takes all the potential parameters available
func IndexWithParameters(pretty bool, index string, _type string, id string, parentId string, version int, op_type string,
	routing string, timestamp string, ttl int, percolate string, timeout string, refresh bool, data interface{}) (api.BaseResponse, error) {
	var url string
	var retval api.BaseResponse
	url, err := GetIndexUrl(index, _type, id, parentId, version, op_type, routing, timestamp, ttl, percolate, timeout, refresh)
	if err != nil {
		return retval, err
	}
	var method string
	if len(id) == 0 {
		method = "POST"
	} else {
		method = "PUT"
	}

	body, err := api.DoCommand(method, url, data)
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

func GetIndexUrl(index string, _type string, id string, parentId string, version int, op_type string,
	routing string, timestamp string, ttl int, percolate string, timeout string, refresh bool) (retval string, e error) {

	if len(index) == 0 {
		return "", errors.New("index can not be blank")
	}
	if len(_type) == 0 {
		return "", errors.New("_type can not be blank")
	}
	var partialURL string
	var values url.Values = url.Values{}
	partialURL = fmt.Sprintf("/%s/%s", index, _type)
	if len(id) > 0 {
		partialURL = fmt.Sprintf("%s/%s", partialURL, id)
	}
	// A child document can be indexed by specifying it’s parent when indexing.
	if len(parentId) > 0 {
		values.Add("parent", parentId)
	}
	// versions start at 1, so if greater than 0
	if version > 0 {
		values.Add("version", strconv.Itoa(version))
	}
	if len(op_type) > 0 {
		if len(id) == 0 {
			//if id is omited, op_type defaults to 'create'
			values.Add("op_type", "create")
		} else {
			values.Add("op_type", op_type)
		}
	}
	if len(routing) > 0 {
		values.Add("routing", routing)
	}
	// A document can be indexed with a timestamp associated with it.
	// The timestamp value of a document can be set using the timestamp parameter.
	if len(timestamp) > 0 {
		values.Add("timestamp", timestamp)
	}
	// A document can be indexed with a ttl (time to live) associated with it. Expired documents
	// will be expunged automatically.
	if ttl > 0 {
		values.Add("ttl", strconv.Itoa(ttl))
	}
	if len(percolate) > 0 {
		values.Add("percolate", percolate)
	}
	// example 5m
	if len(timeout) > 0 {
		values.Add("timeout", timeout)
	}

	if refresh {
		values.Add("refresh", "true")
	}

	partialURL += "?" + values.Encode()
	return partialURL, nil
}
