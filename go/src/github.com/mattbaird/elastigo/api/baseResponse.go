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

package api

import (
	"fmt"
)

type BaseResponse struct {
	Ok      bool        `json:"ok"`
	Index   string      `json:"_index,omitempty"`
	Type    string      `json:"_type,omitempty"`
	Id      string      `json:"_id,omitempty"`
	Source  interface{} `json:"_source,omitempty"` // depends on the schema you've defined
	Version int         `json:"_version,omitempty"`
	Found   bool        `json:"found,omitempty"`
	Exists  bool        `json:"exists,omitempty"`
}
type ExtendedStatus struct {
	Ok           bool   `json:"ok"`
	ShardsStatus Status `json:"_shards"`
}
type Status struct {
	Total      int `json:"total"`
	Successful int `json:"successful"`
	Failed     int `json:"failed"`
}

type Match struct {
	OK           bool         `json:"ok"`
	Matches      []string     `json:"matches"`
	Explaination Explaination `json:"explaination,omitempty"`
}

type Explaination struct {
	Value       float32        `json:"value"`
	Description string         `json:"description"`
	Details     []Explaination `json:"details,omitempty"`
}

func Pretty(pretty bool) string {
	prettyString := ""
	if pretty == true {
		prettyString = "pretty=1"
	}
	return prettyString
}

// http://www.elasticsearch.org/guide/reference/api/search/search-type/

func Scan(scan int) string {
	scanString := ""
	if scan > 0 {
		scanString = fmt.Sprintf("&search_type=scan&size=%v", scan)
	}
	return scanString
}

func Scroll(duration string) string {
	scrollString := ""
	if duration != "" {
		scrollString = "&scroll=" + duration
	}
	return scrollString
}
