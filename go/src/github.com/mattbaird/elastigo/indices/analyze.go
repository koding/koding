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
	"errors"
	"fmt"
	"github.com/mattbaird/elastigo/api"
	"net/url"
	"strings"
)

// AnalyzeIndices performs the analysis process on a text and return the tokens breakdown of the text.
// http://www.elasticsearch.org/guide/reference/api/admin-indices-analyze/
func AnalyzeIndices(index string, analyzer string, tokenizer string, field string, text string, filters ...string) (AnalyzeResponse, error) {
	var retval AnalyzeResponse
	if len(text) <= 0 {
		return retval, errors.New("text to analyze must not be blank")
	}
	var analyzeUrl string = "/_analyze"
	if len(index) > 0 {
		analyzeUrl = fmt.Sprintf("/%s/%s", index, analyzeUrl)
	}
	var values url.Values = url.Values{}
	if len(analyzer) > 0 {
		values.Add("analyzer", analyzer)
	}
	if len(tokenizer) > 0 {
		values.Add("tokenizer", tokenizer)
	}
	if len(field) > 0 {
		values.Add("field", field)
	}
	if len(filters) > 0 {
		values.Add("filters", strings.Join(filters, ","))
	}
	// text will not be blank
	values.Add("text", text)
	analyzeUrl += "?" + values.Encode()

	body, err := api.DoCommand("GET", analyzeUrl, nil)
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

type AnalyzeResponse struct {
	Tokens []Token `json:"tokens"`
}
type Token struct {
	Name        string `json:"token"`
	StartOffset string `json:"start_offset"`
	EndOffset   string `json:"end_offset"`
	Type        string `json:"type"`
	Position    string `json:"position"`
}
