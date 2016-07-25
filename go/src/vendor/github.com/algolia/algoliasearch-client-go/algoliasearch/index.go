package algoliasearch

import (
	"errors"
	"net/url"
	"reflect"
	"strconv"
	"time"
)

// Index is the structure used to manipulate an Algolia index.
type Index struct {
	name        string
	nameEncoded string
	client      *Client
}

// NewIndex instantiates a new Index. The `name` parameter corresponds to the
// Algolia index's name while the `client` is used to connect to the Algolia
// API.
func NewIndex(name string, client *Client) *Index {
	index := new(Index)
	index.name = name
	index.client = client
	index.nameEncoded = client.transport.urlEncode(name)
	return index
}

// Delete deletes the Algolia index.
func (i *Index) Delete() (interface{}, error) {
	return i.client.transport.request("DELETE", "/1/indexes/"+i.nameEncoded, nil, write)
}

// Clear removes every record from the Algolia index.
func (i *Index) Clear() (interface{}, error) {
	return i.client.transport.request("POST", "/1/indexes/"+i.nameEncoded+"/clear", nil, write)
}

// GetObject retrieves the object as an interface representing the JSON-encoded
// object. The `objectID` is used to uniquely identify the object in the index
// while the `attribute` (optional) is a string containing comma-separated
// attributes that you want to retrieve. If this parameter is omitted, all the
// attributes are returned.
func (i *Index) GetObject(objectID string, attribute ...string) (interface{}, error) {
	v := url.Values{}
	if len(attribute) > 1 {
		return nil, errors.New("Too many parametter")
	}
	if len(attribute) > 0 {
		v.Add("attribute", attribute[0])
	}
	return i.client.transport.request("GET", "/1/indexes/"+i.nameEncoded+"/"+i.client.transport.urlEncode(objectID)+"?"+v.Encode(), nil, read)
}

// GetObjects retrieves the objects identified by the given `objectIDs`.
func (i *Index) GetObjects(objectIDs ...string) (interface{}, error) {
	requests := make([]interface{}, len(objectIDs))
	for it := range objectIDs {
		object := make(map[string]interface{})
		object["indexName"] = i.name
		object["objectID"] = objectIDs[it]
		requests[it] = object
	}
	body := make(map[string]interface{})
	body["requests"] = requests
	return i.client.transport.request("POST", "/1/indexes/*/objects", body, read)
}

// DeleteObject deletes an object from the index that is uniquely identified by
// its `objectID`.
func (i *Index) DeleteObject(objectID string) (interface{}, error) {
	return i.client.transport.request("DELETE", "/1/indexes/"+i.nameEncoded+"/"+i.client.transport.urlEncode(objectID), nil, write)
}

// GetSettings retrieves the index settings.
func (i *Index) GetSettings() (interface{}, error) {
	return i.client.transport.request("GET", "/1/indexes/"+i.nameEncoded+"/settings", nil, read)
}

// SetSettings changes the index settings.
func (i *Index) SetSettings(settings interface{}) (interface{}, error) {
	return i.client.transport.request("PUT", "/1/indexes/"+i.nameEncoded+"/settings", settings, write)
}

// getStatus returns the status of a task given its ID `taskID`. The returned
// interface is the JSON-encoded answered from the API server. The error is
// non-nil if the REST API has returned an error.
func (i *Index) getStatus(taskID float64) (interface{}, error) {
	return i.client.transport.request("GET", "/1/indexes/"+i.nameEncoded+"/task/"+strconv.FormatFloat(taskID, 'f', -1, 64), nil, read)
}

// WaitTask waits for the given task to be completed. The interface given is
// typically the returned value of a call to `AddObject`.
func (i *Index) WaitTask(task interface{}) (interface{}, error) {
	if reflect.TypeOf(task).Name() == "float64" {
		return i.WaitTaskWithInit(task.(float64), 100)
	}
	return i.WaitTaskWithInit(task.(map[string]interface{})["taskID"].(float64), 100)
}

// WaitTaskWithInit waits for the task with the `taskID` to be completed. The
// `timeToWait` parameter controls the first duration, in ms, to use between
// each retry (it will be exponentiated up to 10s).
func (i *Index) WaitTaskWithInit(taskID float64, timeToWait float64) (interface{}, error) {
	for true {
		status, err := i.getStatus(taskID)
		if err != nil {
			return nil, err
		}
		if status.(map[string]interface{})["status"] == "published" {
			return status, nil
		}
		time.Sleep(time.Duration(timeToWait) * time.Millisecond)
		timeToWait = timeToWait * 2
		if timeToWait > 10000 {
			timeToWait = 10000
		}
	}
	return nil, errors.New("Code not reachable")
}

// ListKeys lists all the keys that can access the index.
func (i *Index) ListKeys() (interface{}, error) {
	return i.client.transport.request("GET", "/1/indexes/"+i.nameEncoded+"/keys", nil, read)
}

// GetKey returns the ACL and the validity of the given `key` API key for the
// current index.
func (i *Index) GetKey(key string) (interface{}, error) {
	return i.client.transport.request("GET", "/1/indexes/"+i.nameEncoded+"/keys/"+key, nil, read)
}

// DeleteKey deletes the `key` API key of the current index.
func (i *Index) DeleteKey(key string) (interface{}, error) {
	return i.client.transport.request("DELETE", "/1/indexes/"+i.nameEncoded+"/keys/"+key, nil, write)
}

// AddObject adds a new object to the index.
func (i *Index) AddObject(object interface{}) (interface{}, error) {
	method := "POST"
	path := "/1/indexes/" + i.nameEncoded
	return i.client.transport.request(method, path, object, write)
}

// UpdateObject modifies the record in the Algolia index matching the one given
// in parameter, according to its `objectID` value.
func (i *Index) UpdateObject(object interface{}) (interface{}, error) {
	id := object.(map[string]interface{})["objectID"]
	path := "/1/indexes/" + i.nameEncoded + "/" + i.client.transport.urlEncode(id.(string))
	return i.client.transport.request("PUT", path, object, write)
}

// PartialUpdateObject modifies the record in the Algolia index matching the
// one given in parameter, according to its `objectID` value. However, the
// record is only partially updated i.e. only the specified attributes will be
// updated.
func (i *Index) PartialUpdateObject(object interface{}) (interface{}, error) {
	id := object.(map[string]interface{})["objectID"]
	path := "/1/indexes/" + i.nameEncoded + "/" + i.client.transport.urlEncode(id.(string)) + "/partial"
	return i.client.transport.request("POST", path, object, write)
}

// AddObject adds several objects to the index.
func (i *Index) AddObjects(objects interface{}) (interface{}, error) {
	return i.sameBatch(objects, "addObject")
}

// UpdateObjects adds or updates several objects at the same time, according to
// their respective `objectID` attribute.
func (i *Index) UpdateObjects(objects interface{}) (interface{}, error) {
	return i.sameBatch(objects, "updateObject")
}

// PartialUpdateObjects partially updates several objects at the same time,
// according to their respective `objectID` attribute.
func (i *Index) PartialUpdateObjects(objects interface{}) (interface{}, error) {
	return i.sameBatch(objects, "partialUpdateObject")
}

// DeleteObjects deletes several objects at the same time, according to their
// respective `objectID` attribute.
func (i *Index) DeleteObjects(objectIDs []string) (interface{}, error) {
	objects := make([]interface{}, len(objectIDs))
	for i := range objectIDs {
		object := make(map[string]interface{})
		object["objectID"] = objectIDs[i]
		objects[i] = object
	}
	return i.sameBatch(objects, "deleteObject")
}

// DeleteByQuery deletes all the records that are found after performing the
// `query` search query, following the `params` parameters.
func (i *Index) DeleteByQuery(query string, params map[string]interface{}) (interface{}, error) {
	if params == nil {
		params = make(map[string]interface{})
	}
	params["attributesToRetrieve"] = "[\"objectID\"]"
	params["hitsPerPage"] = 1000
	params["distinct"] = false

	results, error := i.Search(query, params)
	if error != nil {
		return results, error
	}
	for results.(map[string]interface{})["nbHits"].(float64) != 0 {
		objectIDs := make([]string, len(results.(map[string]interface{})["hits"].([]interface{})))
		for i := range results.(map[string]interface{})["hits"].([]interface{}) {
			hits := results.(map[string]interface{})["hits"].([]interface{})[i].(map[string]interface{})
			objectIDs[i] = hits["objectID"].(string)
		}
		task, error := i.DeleteObjects(objectIDs)
		if error != nil {
			return task, error
		}

		_, error = i.WaitTask(task)
		if error != nil {
			return nil, error
		}
		results, error = i.Search(query, params)
		if error != nil {
			return results, error
		}
	}
	return nil, nil
}

// sameBatch performs the `action` command on all the objects specified in the
// `objects` parameter.
func (i *Index) sameBatch(objects interface{}, action string) (interface{}, error) {
	length := len(objects.([]interface{}))
	method := make([]string, length)
	for i := range method {
		method[i] = action
	}
	return i.Batch(objects, method)
}

// Batch performs each action contained in the `actions` parameter to their
// respective object from the `objects` parameter.
func (i *Index) Batch(objects interface{}, actions []string) (interface{}, error) {
	array := objects.([]interface{})
	queries := make([]map[string]interface{}, len(array))
	for i := range array {
		queries[i] = make(map[string]interface{})
		queries[i]["action"] = actions[i]
		queries[i]["body"] = array[i]
	}
	return i.CustomBatch(queries)
}

// CustomBatch actually performs the batch request of all `queries`.
func (i *Index) CustomBatch(queries interface{}) (interface{}, error) {
	request := make(map[string]interface{})
	request["requests"] = queries
	return i.client.transport.request("POST", "/1/indexes/"+i.nameEncoded+"/batch", request, write)
}

// Browse returns `hitsPerPage` results from the `page` page.
// Deprecated: Use `BrowseFrom` or `BrowseAll` instead.
func (i *Index) Browse(page, hitsPerPage int) (interface{}, error) {
	return i.client.transport.request("GET", "/1/indexes/"+i.nameEncoded+"/browse?page="+strconv.Itoa(page)+"&hitsPerPage="+strconv.Itoa(hitsPerPage), nil, read)
}

// makeIndexIterator instantiates an new IndexIterator given the `params`
// parameters. It also initializes it to the first page of results.
func (i *Index) makeIndexIterator(params interface{}, cursor string) (*IndexIterator, error) {
	it := new(IndexIterator)
	it.answer = map[string]interface{}{"cursor": cursor}
	it.params = params
	it.pos = 0
	it.index = i
	ok := it.loadNextPage()
	return it, ok
}

// BrowseFrom browses the results according to the given `params` parameters at
// the position defined by the `cursor` parameter.
func (i *Index) BrowseFrom(params interface{}, cursor string) (interface{}, error) {
	if len(cursor) != 0 {
		cursor = "&cursor=" + i.client.transport.urlEncode(cursor)
	} else {
		cursor = ""
	}
	return i.client.transport.request("GET", "/1/indexes/"+i.nameEncoded+"/browse?"+i.client.transport.EncodeParams(params)+cursor, nil, read)
}

// BrowseAll browses the results according to the given `params` parameter
// starting at the first results. It returns an `IndexIterator` that is used to
// iterate over the results.
func (i *Index) BrowseAll(params interface{}) (*IndexIterator, error) {
	return i.makeIndexIterator(params, "")
}

// Search performs a search query according to the `query` search query and the
// given `params` parameters.
func (i *Index) Search(query string, params interface{}) (interface{}, error) {
	if params == nil {
		params = make(map[string]interface{})
	}
	params.(map[string]interface{})["query"] = query
	body := make(map[string]interface{})
	body["params"] = i.client.transport.EncodeParams(params)
	return i.client.transport.request("POST", "/1/indexes/"+i.nameEncoded+"/query", body, search)
}

// operation performs the `op` operation on the underlying index and names the
// resulting new index `name`. The `op` operation can be either `copy` or
// `move`.
func (i *Index) operation(name, op string) (interface{}, error) {
	body := make(map[string]interface{})
	body["operation"] = op
	body["destination"] = name
	return i.client.transport.request("POST", "/1/indexes/"+i.nameEncoded+"/operation", body, write)
}

// Copy copies the index into a new one called `name`.
func (i *Index) Copy(name string) (interface{}, error) {
	return i.operation(name, "copy")
}

// Move renames the index into `name`.
func (i *Index) Move(name string) (interface{}, error) {
	return i.operation(name, "move")
}

// AddKey registers a new API key for the index. The `acl` parameter controls
// which permissions are given, `validity` is the validity duration in seconds
// (0 for unlimited), `maxQueriesPerIPPerHour` is the maximum number of calls
// authorized per hour and `maxHitsPerQuery` controls the number of results
// that each query could return at most.
func (i *Index) AddKey(acl []string, validity int, maxQueriesPerIPPerHour int, maxHitsPerQuery int) (interface{}, error) {
	body := make(map[string]interface{})
	body["acl"] = acl
	body["maxHitsPerQuery"] = maxHitsPerQuery
	body["maxQueriesPerIPPerHour"] = maxQueriesPerIPPerHour
	body["validity"] = validity
	return i.AddKeyWithParam(body)
}

// AddKeyWithParam registers a new API for the index. The `params` parameter is
// a `map[string]interface{}` of all the parameters given to the `AddKey`
// function.
func (i *Index) AddKeyWithParam(params interface{}) (interface{}, error) {
	return i.client.transport.request("POST", "/1/indexes/"+i.nameEncoded+"/keys", params, write)
}

// UpdateKey updates the `key` API key according to the other given parameters.
func (i *Index) UpdateKey(key string, acl []string, validity int, maxQueriesPerIPPerHour int, maxHitsPerQuery int) (interface{}, error) {
	body := make(map[string]interface{})
	body["acl"] = acl
	body["maxHitsPerQuery"] = maxHitsPerQuery
	body["maxQueriesPerIPPerHour"] = maxQueriesPerIPPerHour
	body["validity"] = validity
	return i.UpdateKeyWithParam(key, body)
}

// UpdateKeyWithParam updates the `key` API key according to the `params`
// parameters which is a `map[string]interface{}` of all the parameters given
// to the `UpdateKey` function.
func (i *Index) UpdateKeyWithParam(key string, params interface{}) (interface{}, error) {
	return i.client.transport.request("PUT", "/1/indexes/"+i.nameEncoded+"/keys/"+key, params, write)
}
