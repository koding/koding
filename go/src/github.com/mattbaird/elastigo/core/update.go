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

// Update updates a document based on a script provided. The operation gets the document
// (collocated with the shard) from the index, runs the script (with optional script language and parameters),
// and index back the result (also allows to delete, or ignore the operation). It uses versioning to make sure
// no updates have happened during the “get” and “reindex”. (available from 0.19 onwards).
// Note, this operation still means full reindex of the document, it just removes some network roundtrips
// and reduces chances of version conflicts between the get and the index. The _source field need to be enabled
// for this feature to work.
//
// http://www.elasticsearch.org/guide/reference/api/update.html
// TODO: finish this, it's fairly complex
func Update(pretty bool, index string, _type string, id string) (api.BaseResponse, error) {
	var url string
	var retval api.BaseResponse
	url = fmt.Sprintf("/%s/%s/%s/_update?%s", index, _type, id, api.Pretty(pretty))
	body, err := api.DoCommand("POST", url, nil)
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
