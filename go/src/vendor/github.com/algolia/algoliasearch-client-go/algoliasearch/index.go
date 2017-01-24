package algoliasearch

import (
	"encoding/json"
	"fmt"
	"net/url"
	"strings"
	"time"
)

type index struct {
	client *client
	name   string
	route  string
}

// NewIndex instantiates a new `Index`. The `name` parameter corresponds to the
// Algolia index name while the `client` is used to connect to the Algolia API.
func NewIndex(name string, client *client) Index {
	return &index{
		client: client,
		name:   name,
		route:  "/1/indexes/" + url.QueryEscape(name),
	}
}

func (i *index) Delete() (res DeleteTaskRes, err error) {
	path := i.route
	err = i.client.request(&res, "DELETE", path, nil, write)
	return
}

func (i *index) Clear() (res UpdateTaskRes, err error) {
	path := i.route + "/clear"
	err = i.client.request(&res, "POST", path, nil, write)
	return
}

func (i *index) GetObject(objectID string, attributes []string) (object Object, err error) {
	var params Map
	if attributes != nil {
		var attrBytes []byte
		attrBytes, err = json.Marshal(attributes)
		if err != nil {
			return
		}
		params = Map{
			"attributes": attrBytes,
		}
	}

	path := i.route + "/" + url.QueryEscape(objectID) + "?" + encodeMap(params)
	err = i.client.request(&object, "GET", path, nil, read)
	return
}

func (i *index) getObjects(objectIDs, attributesToRetrieve []string) (objs []Object, err error) {
	attrs := url.QueryEscape(strings.Join(attributesToRetrieve, ","))

	requests := make([]map[string]string, len(objectIDs))
	for j, id := range objectIDs {
		requests[j] = map[string]string{
			"indexName": i.name,
			"objectID":  url.QueryEscape(id),
		}
		if attributesToRetrieve != nil {
			requests[j]["attributesToRetrieve"] = attrs
		}
	}

	body := Map{
		"requests": requests,
	}

	var res objects
	path := "/1/indexes/*/objects"
	err = i.client.request(&res, "POST", path, body, read)
	objs = res.Results
	return
}

func (i *index) GetObjects(objectIDs []string) (objs []Object, err error) {
	return i.getObjects(objectIDs, nil)
}

func (i *index) GetObjectsAttrs(objectIDs, attrs []string) (objs []Object, err error) {
	return i.getObjects(objectIDs, attrs)
}

func (i *index) DeleteObject(objectID string) (res DeleteTaskRes, err error) {
	path := i.route + "/" + url.QueryEscape(objectID)
	err = i.client.request(&res, "DELETE", path, nil, write)
	return
}

func (i *index) GetSettings() (settings Settings, err error) {
	path := i.route + "/settings?getVersion=2"
	err = i.client.request(&settings, "GET", path, nil, read)
	settings.clean()
	return
}

func (i *index) SetSettings(settings Map) (res UpdateTaskRes, err error) {
	if err = checkSettings(settings); err != nil {
		return
	}

	// Handle forwardToReplicas separately
	forwardToReplicas, ok := settings["forwardToReplicas"]
	if !ok {
		forwardToReplicas = false
	}
	delete(settings, "forwardToReplicas")

	path := i.route + "/settings?forwardToReplicas=" + fmt.Sprintf("%t", forwardToReplicas)
	err = i.client.request(&res, "PUT", path, settings, write)
	return
}

func (i *index) WaitTask(taskID int) error {
	var res TaskStatusRes
	var err error

	var maxDuration time.Duration = time.Second
	var sleepDuration time.Duration

	for {
		if res, err = i.GetStatus(taskID); err != nil {
			return err
		}

		if res.Status == "published" {
			return nil
		}

		sleepDuration = randDuration(maxDuration)
		time.Sleep(sleepDuration)

		// Increase the upper boundary used to generate the sleep
		// duration
		if maxDuration < 10*time.Minute {
			maxDuration *= 2
		}
	}

	return nil
}

func (i *index) ListKeys() (keys []Key, err error) {
	var res listKeysRes

	path := i.route + "/keys"
	if err = i.client.request(&res, "GET", path, nil, read); err != nil {
		return
	}

	keys = res.Keys
	return
}

func (i *index) AddUserKey(ACL []string, params Map) (res AddKeyRes, err error) {
	req := duplicateMap(params)
	req["acl"] = ACL

	if err = checkKey(req); err != nil {
		return
	}

	path := i.route + "/keys"
	err = i.client.request(&res, "POST", path, req, read)
	return
}

func (i *index) UpdateUserKey(key string, params Map) (res UpdateKeyRes, err error) {
	if err = checkKey(params); err != nil {
		return
	}

	path := i.route + "/keys/" + url.QueryEscape(key)
	err = i.client.request(&res, "PUT", path, params, read)
	return
}

func (i *index) GetUserKey(value string) (key Key, err error) {
	path := i.route + "/keys/" + url.QueryEscape(value)
	err = i.client.request(&key, "GET", path, nil, read)
	return
}

func (i *index) DeleteUserKey(value string) (res DeleteRes, err error) {
	path := i.route + "/keys/" + value
	err = i.client.request(&res, "DELETE", path, nil, write)
	return
}

func (i *index) AddObject(object Object) (res CreateObjectRes, err error) {
	path := i.route
	err = i.client.request(&res, "POST", path, object, write)
	return
}

func (i *index) UpdateObject(object Object) (res UpdateObjectRes, err error) {
	objectID, err := object.ObjectID()
	if err != nil {
		return
	}

	path := i.route + "/" + url.QueryEscape(objectID)
	err = i.client.request(&res, "PUT", path, object, write)
	return
}

func (i *index) partialUpdateObject(object Object, createIfNotExists bool) (res UpdateTaskRes, err error) {
	objectID, err := object.ObjectID()
	if err != nil {
		return
	}

	path := i.route + "/" + url.QueryEscape(objectID) + "/partial"
	if !createIfNotExists {
		path += "?createIfNotExists=false"
	}
	err = i.client.request(&res, "POST", path, object, write)
	return
}

func (i *index) PartialUpdateObject(object Object) (res UpdateTaskRes, err error) {
	return i.partialUpdateObject(object, true)
}

func (i *index) PartialUpdateObjectNoCreate(object Object) (res UpdateTaskRes, err error) {
	return i.partialUpdateObject(object, false)
}

func (i *index) AddObjects(objects []Object) (res BatchRes, err error) {
	var operations []BatchOperation

	if operations, err = newBatchOperations(objects, "addObject"); err == nil {
		res, err = i.Batch(operations)
	}

	return
}

func (i *index) UpdateObjects(objects []Object) (res BatchRes, err error) {
	var operations []BatchOperation

	if operations, err = newBatchOperations(objects, "updateObject"); err == nil {
		res, err = i.Batch(operations)
	}

	return
}

func (i *index) partialUpdateObjects(objects []Object, action string) (res BatchRes, err error) {
	var operations []BatchOperation

	if operations, err = newBatchOperations(objects, action); err == nil {
		res, err = i.Batch(operations)
	}

	return
}

func (i *index) PartialUpdateObjects(objects []Object) (res BatchRes, err error) {
	return i.partialUpdateObjects(objects, "partialUpdateObject")
}

func (i *index) PartialUpdateObjectsNoCreate(objects []Object) (res BatchRes, err error) {
	return i.partialUpdateObjects(objects, "partialUpdateObjectNoCreate")
}

func (i *index) DeleteObjects(objectIDs []string) (res BatchRes, err error) {
	objects := make([]Object, len(objectIDs))

	for j, id := range objectIDs {
		objects[j] = Object{
			"objectID": id,
		}
	}

	var operations []BatchOperation
	if operations, err = newBatchOperations(objects, "deleteObject"); err == nil {
		res, err = i.Batch(operations)
	}

	return
}

func (i *index) Batch(operations []BatchOperation) (res BatchRes, err error) {
	body := map[string][]BatchOperation{
		"requests": operations,
	}

	path := i.route + "/batch"
	err = i.client.request(&res, "POST", path, body, write)
	return
}

func (i *index) Copy(name string) (UpdateTaskRes, error) {
	return i.operation(name, "copy")
}

func (i *index) Move(name string) (UpdateTaskRes, error) {
	return i.operation(name, "move")
}

func (i *index) operation(dst, op string) (res UpdateTaskRes, err error) {
	o := IndexOperation{
		Destination: dst,
		Operation:   op,
	}

	path := i.route + "/operation"
	err = i.client.request(&res, "POST", path, o, write)
	return
}

func (i *index) GetStatus(taskID int) (res TaskStatusRes, err error) {
	path := i.route + fmt.Sprintf("/task/%d", taskID)
	err = i.client.request(&res, "GET", path, nil, read)
	return
}

func (i *index) SearchSynonyms(query string, types []string, page, hitsPerPage int) (synonyms []Synonym, err error) {
	body := Map{
		"query":       query,
		"type":        strings.Join(types, ","),
		"page":        page,
		"hitsPerPage": hitsPerPage,
	}

	path := i.route + "/synonyms/search"
	var res SearchSynonymsRes
	err = i.client.request(&res, "POST", path, body, search)

	if err == nil {
		synonyms = res.Hits
	}

	return
}

func (i *index) GetSynonym(objectID string) (s Synonym, err error) {
	path := i.route + "/synonyms/" + url.QueryEscape(objectID)
	err = i.client.request(&s, "GET", path, nil, read)
	return
}

func (i *index) AddSynonym(synonym Synonym, forwardToReplicas bool) (res UpdateTaskRes, err error) {
	params := Map{
		"forwardToReplicas": forwardToReplicas,
	}

	path := i.route + "/synonyms/" + url.QueryEscape(synonym.ObjectID) + "?" + encodeMap(params)
	err = i.client.request(&res, "PUT", path, synonym, write)
	return
}

func (i *index) DeleteSynonym(objectID string, forwardToReplicas bool) (res DeleteTaskRes, err error) {
	params := Map{
		"forwardToReplicas": forwardToReplicas,
	}

	path := i.route + "/synonyms/" + url.QueryEscape(objectID) + "?" + encodeMap(params)
	err = i.client.request(&res, "DELETE", path, nil, write)
	return
}

func (i *index) ClearSynonyms(forwardToReplicas bool) (res UpdateTaskRes, err error) {
	params := Map{
		"forwardToReplicas": forwardToReplicas,
	}

	path := i.route + "/synonyms/clear?" + encodeMap(params)
	err = i.client.request(&res, "POST", path, nil, write)
	return
}

func (i *index) BatchSynonyms(synonyms []Synonym, replaceExistingSynonyms, forwardToReplicas bool) (res UpdateTaskRes, err error) {
	params := Map{
		"replaceExistingSynonyms": replaceExistingSynonyms,
		"forwardToReplicas":       forwardToReplicas,
	}

	path := i.route + "/synonyms/batch?" + encodeMap(params)
	err = i.client.request(&res, "POST", path, synonyms, write)
	return
}

func (i *index) Browse(params Map, cursor string) (res BrowseRes, err error) {
	copy := duplicateMap(params)
	if err = checkQuery(copy); err != nil {
		return
	}

	if cursor != "" {
		copy["cursor"] = cursor
	}

	req := Map{
		"params": encodeMap(copy),
	}

	path := i.route + "/browse"
	err = i.client.request(&res, "POST", path, req, read)
	return
}

func (i *index) BrowseAll(params Map) (it IndexIterator, err error) {
	if err = checkQuery(params); err != nil {
		return
	}

	it, err = newIndexIterator(i, params)
	return
}

func (i *index) Search(query string, params Map) (res QueryRes, err error) {
	copy := duplicateMap(params)
	copy["query"] = query

	if err = checkQuery(copy); err != nil {
		return
	}

	req := Map{
		"params": encodeMap(copy),
	}

	path := i.route + "/query"
	err = i.client.request(&res, "POST", path, req, search)
	return
}

func (i *index) DeleteByQuery(query string, params Map) (err error) {
	copy := duplicateMap(params)
	copy["attributesToRetrieve"] = []string{"objectID"}
	copy["hitsPerPage"] = 1000
	copy["query"] = query
	copy["distinct"] = 0

	var browseRes BrowseRes
	var batchRes BatchRes

	for {
		// Start browsing the content
		if browseRes, err = i.Browse(copy, ""); err != nil {
			return
		}

		// Break if there's no more matching records
		if len(browseRes.Hits) == 0 {
			break
		}

		// Collect all objectIDs
		var objectIDs []string
		for _, hit := range browseRes.Hits {
			objectIDs = append(objectIDs, hit["objectID"].(string))
		}

		// Delete all the objects
		if batchRes, err = i.DeleteObjects(objectIDs); err != nil {
			return
		}

		// Wait until DeleteObjects completion
		if err := i.WaitTask(batchRes.TaskID); err != nil {
			return err
		}
	}

	return nil
}

func (i *index) SearchForFacetValues(facet, query string, params Map) (res SearchFacetRes, err error) {
	copy := duplicateMap(params)
	if err = checkQuery(copy); err != nil {
		return
	}

	copy["facetQuery"] = query

	req := Map{
		"params": encodeMap(copy),
	}

	path := i.route + "/facets/" + facet + "/query"
	err = i.client.request(&res, "POST", path, req, search)
	return
}

func (i *index) SearchFacet(facet, query string, params Map) (res SearchFacetRes, err error) {
	return i.SearchForFacetValues(facet, query, params)
}
