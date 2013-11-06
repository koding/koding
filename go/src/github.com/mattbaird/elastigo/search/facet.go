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

package search

import (
	"encoding/json"

	u "github.com/araddon/gou"
)

var (
	_ = u.DEBUG
)

/*
"facets": {
    "terms": {
		"terms": {
			"field": [
			  "@fields.category"
			],
			"size": 25
		}
    }
}


"facets": {
  "actors": { "terms": {"field": ["actor"],"size": "10" }}
  , "langauge": { "terms": {"field": ["repository.language"],"size": "10" }}
}

*/
func Facet() *FacetDsl {
	return &FacetDsl{}
}

type FacetDsl struct {
	size  string
	Terms map[string]*Term `json:"terms,omitempty"`
}

func (m *FacetDsl) Size(size string) *FacetDsl {
	m.size = size
	return m
}

func (m *FacetDsl) Regex(field, match string) *FacetDsl {
	if len(m.Terms) == 0 {
		m.Terms = make(map[string]*Term)
	}
	m.Terms[field] = &Term{Terms{Fields: []string{field}, Regex: match}}
	return m
}

func (m *FacetDsl) Fields(fields ...string) *FacetDsl {
	if len(fields) < 1 {
		return m
	}
	if len(m.Terms) == 0 {
		m.Terms = make(map[string]*Term)
	}
	m.Terms[fields[0]] = &Term{Terms{Fields: fields}}
	return m
}

func (m *FacetDsl) MarshalJSON() ([]byte, error) {
	for _, t := range m.Terms {
		t.Terms.Size = m.size
	}
	return json.Marshal(&m.Terms)
}
