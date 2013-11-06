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
	"fmt"
	"github.com/mattbaird/elastigo/api"
	"strings"
)

// IndicesExists checks for the existance of indices. uses http 404 if it does not exist, and 200 if it does
// see http://www.elasticsearch.org/guide/reference/api/admin-indices-indices-exists/
func IndicesExists(indices ...string) (bool, error) {
	var url string
	if len(indices) > 0 {
		url = fmt.Sprintf("/%s", strings.Join(indices, ","))
	}
	_, err := api.DoCommand("HEAD", url, nil)
	if err != nil {
		eserror := err.(api.ESError)
		if eserror.Code == 404 {
			return false, err
		} else {
			return eserror.Code == 200, err
		}
	}
	return true, nil
}
