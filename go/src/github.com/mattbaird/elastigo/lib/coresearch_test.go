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

package elastigo

import (
	"encoding/json"
	"testing"
)

func TestSearchResultToJSON(t *testing.T) {
	c := NewTestConn()

	qry := map[string]interface{}{
		"query": map[string]interface{}{
			"wildcard": map[string]string{"actor": "a*"},
		},
	}
	var args map[string]interface{}
	out, err := c.Search("github", "", args, qry)

	if err != nil {
		t.Error(err)
	}
	_, err = json.Marshal(out.Hits.Hits)
	if err != nil {
		t.Error(err)
	}
}
