package algoliasearch

import "time"
import "strconv"
import "net/url"
import "errors"

type Index struct {
  name string
  nameEncoded string
  client *Client
}

func NewIndex(name string, client *Client) *Index {
  index := new(Index)
  index.name = name
  index.client = client
  index.nameEncoded = client.transport.urlEncode(name)
  return index
}

func (i *Index) Delete() (interface{}, error) {
  return i.client.transport.request("DELETE", "/1/indexes/" + i.nameEncoded, nil)
}

func (i *Index) Clear() (interface{}, error) {
  return i.client.transport.request("POST", "/1/indexes/" + i.nameEncoded + "/clear", nil)
}

func (i *Index) GetObject(objectID string, attribute ...string) (interface{}, error) {
  v := url.Values{}
  if len(attribute) > 1 {
    return nil, errors.New("Too many parametter")
  }
  if len(attribute) > 0 {
    v.Add("attribute", attribute[0])
  }
  return i.client.transport.request("GET", "/1/indexes/" + i.nameEncoded + "/" + i.client.transport.urlEncode(objectID) + "?" + v.Encode(), nil)
}

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
  return i.client.transport.request("POST", "/1/indexes/*/objects", body);
}

func (i *Index) DeleteObject(objectID string) (interface{}, error) {
  return i.client.transport.request("DELETE", "/1/indexes/" + i.nameEncoded + "/" +  i.client.transport.urlEncode(objectID), nil)
}

func (i *Index) GetSettings() (interface{}, error) {
  return i.client.transport.request("GET", "/1/indexes/" + i.nameEncoded + "/settings", nil)
}

func (i *Index) SetSettings(settings interface{}) (interface{}, error) {
  return i.client.transport.request("PUT", "/1/indexes/" + i.nameEncoded + "/settings", settings)
}

func (i *Index) getStatus(taskID float64) (interface{}, error) {
  return i.client.transport.request("GET", "/1/indexes/" + i.nameEncoded + "/task/" + strconv.FormatFloat(taskID, 'f', -1, 64), nil)
}

func (i *Index) WaitTask(task interface{}) (interface{}, error) {
  for true {
    status, err := i.getStatus(task.(map[string]interface{})["taskID"].(float64))
    if err != nil {
      return nil, err
    }
    if status.(map[string]interface{})["status"] == "published" {
      break
    }
    time.Sleep(time.Duration(100) * time.Millisecond) 
  }
  return task, nil
}

func (i *Index) ListKeys() (interface{}, error) {
  return i.client.transport.request("GET", "/1/indexes/" + i.nameEncoded + "/keys", nil)
}

func (i *Index) GetKey(key string) (interface{}, error) {
  return i.client.transport.request("GET", "/1/indexes/" + i.nameEncoded + "/keys/" + key , nil)
}

func (i *Index) DeleteKey(key string) (interface{}, error) {
  return i.client.transport.request("DELETE", "/1/indexes/" + i.nameEncoded + "/keys/" + key , nil)
}

func (i *Index) AddObject(object interface{}) (interface{}, error) {
  method := "POST"
  path := "/1/indexes/" + i.nameEncoded
  if id, ok := object.(map[string]interface{})["objectID"]; ok {
    method = "PUT"
    path = path + "/" + i.client.transport.urlEncode(id.(string))
  }
  return i.client.transport.request(method, path, object)
}

func (i *Index) UpdateObject(object interface{}) (interface{}, error) {
  id := object.(map[string]interface{})["objectID"]
  path := "/1/indexes/" + i.nameEncoded + "/" + i.client.transport.urlEncode(id.(string))
  return i.client.transport.request("PUT", path, object)
}

func (i *Index) PartialUpdateObject(object interface{}) (interface{}, error) {
  id := object.(map[string]interface{})["objectID"]
  path := "/1/indexes/" + i.nameEncoded + "/" + i.client.transport.urlEncode(id.(string)) + "/partial"
  return i.client.transport.request("POST", path, object)
}

func (i *Index) AddObjects(objects interface{}) (interface{}, error) {
  return i.sameBatch(objects, "addObject")
}

func (i *Index) UpdateObjects(objects interface{}) (interface{}, error) {
  return i.sameBatch(objects, "updateObject")
}

func (i *Index) PartialUpdateObjects(objects interface{}) (interface{}, error) {
  return i.sameBatch(objects, "partialUpdateObject")
}

func (i *Index) DeleteObjects(objectIDs []string) (interface{}, error) {
  objects := make([]interface{}, len(objectIDs))
  for i := range objectIDs {
    object := make(map[string]interface{})
    object["objectID"] = objectIDs[i]
    objects[i] = object
  }
  return i.sameBatch(objects, "deleteObject")
}

func (i *Index) DeleteByQuery(query string, params map[string]interface{}) (interface{}, error) {
  if (params == nil) {
    params = make(map[string]interface{})
  }
  params["attributesToRetrieve"] = "[\"objectID\"]"
  params["hitsPerPage"] = 1000

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

func (i *Index) sameBatch(objects interface{}, action string) (interface{}, error) {
  length := len(objects.([]interface{}))
  method := make([]string, length)
  for i := range method {
    method[i] = action
  }
  return i.Batch(objects, method)
}

func (i *Index) Batch(objects interface{}, actions []string) (interface{}, error) {
  array := objects.([]interface{})
  queries := make([]map[string]interface{}, len(array))
  for i := range array {
    queries[i] = make(map[string]interface{})
    queries[i]["action"] = actions[i]
    queries[i]["body"] = array[i]
  }
  return i.customBatch(queries)
}

func (i *Index) customBatch(queries interface{}) (interface{}, error) {
  request :=  make(map[string]interface{})
  request["requests"] = queries
  return i.client.transport.request("POST", "/1/indexes/" + i.nameEncoded + "/batch", request)
}

func (i *Index) Browse(page, hitsPerPage int) (interface{}, error) {
  return i.client.transport.request("GET", "/1/indexes/" + i.nameEncoded + "/browse?page=" + strconv.Itoa(page) + "&hitsPerPage=" + strconv.Itoa(hitsPerPage) , nil)
}

func (i *Index) Search(query string, params interface{}) (interface{}, error) {
  if params == nil {
    params = make(map[string]interface{})
  }
  params.(map[string]interface{})["query"] = query
  body := make(map[string]interface{})
  body["params"] = i.client.transport.EncodeParams(params)
  return i.client.transport.request("POST", "/1/indexes/" + i.nameEncoded + "/query", body)
}

func (i *Index) operation(name, op string) (interface{}, error) {
  body := make(map[string]interface{})
  body["operation"] = op
  body["destination"] = name
  return i.client.transport.request("POST", "/1/indexes/" + i.nameEncoded + "/operation", body)
}

func (i *Index) Copy(name string) (interface{}, error) {
  return i.operation(name, "copy")
}

func (i *Index) Move(name string) (interface{}, error) {
  return i.operation(name, "move")
}

func (i *Index) AddKey(acl []string, validity int, maxQueriesPerIPPerHour int, maxHitsPerQuery int) (interface{}, error) {
  body := make(map[string]interface{})
  body["acl"] = acl
  body["maxHitsPerQuery"] = maxHitsPerQuery
  body["maxQueriesPerIPPerHour"] = maxQueriesPerIPPerHour
  body["validity"] = validity
  return i.client.transport.request("POST", "/1/indexes/" + i.nameEncoded + "/keys", body)
}
