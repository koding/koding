package algoliasearch

import "syscall"
import "strconv"
import "testing"
import "time"

func initTest(t *testing.T) (*Client, *Index) {
  appID, haveAppID := syscall.Getenv("ALGOLIA_APPLICATION_ID")
  apiKey, haveApiKey := syscall.Getenv("ALGOLIA_API_KEY")
  if !haveApiKey || !haveAppID {
    t.Fatalf("Need ALGOLIA_APPLICATION_ID and ALGOLIA_API_KEY")
  }
  client := NewClient(appID, apiKey)
  index := client.InitIndex("àlgol?à-go")
  return client, index
}

func shouldHave(json interface{}, attr, msg string, t *testing.T) {
  _, ok := json.(map[string]interface{})[attr]
  if !ok  {
    t.Fatalf(msg + ", expected attribute: " + attr)
  }
}

func shouldNotHave(json interface{}, attr, msg string, t *testing.T) {
  _, ok := json.(map[string]interface{})[attr]
  if ok  {
    t.Fatalf(msg + ", unexpected attribute: " + attr)
  }
}

func shouldStr(json interface{}, attr, value, msg string, t *testing.T) {
  resp, ok := json.(map[string]interface{})[attr]
  if !ok || value != resp.(string) {
    t.Fatalf(msg + ", expected: " + value + " have: " + resp.(string))
  }
}

func shouldFloat(json interface{}, attr string, value float64, msg string, t *testing.T) {
  resp, ok := json.(map[string]interface{})[attr]
  if !ok || value != resp.(float64) {
    t.Fatalf(msg + ", expected: " + strconv.FormatFloat(value, 'f', -1, 64) + " have: " + strconv.FormatFloat(resp.(float64), 'f', -1, 64))
  }
}

func shouldContainString(json interface{}, attr string, value string, msg string, t *testing.T) {
  array := json.([]interface{})
  for i := range array {
    val, ok := array[i].(map[string]interface{})[attr]
    if ok && value == val.(string) {
      return
    }
  }
  t.Fatalf(msg + ", expected: " + value + " in the array.")
}

func shouldNotContainString(json interface{}, attr string, value string, msg string, t *testing.T) {
  array := json.([]interface{})
  for i := range array {
    val, ok := array[i].(map[string]interface{})[attr]
    if ok && value == val.(string) {
      t.Fatalf(msg + ", expected: " + value + " in the array.")
    }
  }
}

func TestClear(t *testing.T) {
  _, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  resp, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  resp, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  resp, err = index.Clear()
  if err != nil {
    t.Fatalf(err.Error())
  }
  index.WaitTask(resp)
  results, err := index.Search("", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(results, "nbHits", 0, "Unable to clear the index", t)
  index.Delete()
}

func TestAddObject(t *testing.T) {
  _, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  _, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  object["name"] = "John Snow"
  object["objectID"] = "àlgol?à"
  resp, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  results, err := index.Search("", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(results, "nbHits", 2, "Unable to clear the index", t)
  index.Delete()
}

func TestUpdateObject(t *testing.T) {
  _, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  object["objectID"] = "àlgol?à"
  _, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  object["name"] = "Roger"
  resp, err := index.UpdateObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  results, err := index.Search("", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  hits := results.(map[string]interface{})["hits"]
  shouldStr(hits.([]interface{})[0], "name", "Roger", "Unable to update an object", t)
  shouldNotHave(hits.([]interface{})[0], "job", "Unable to update an object", t)
  index.Delete()
}

func TestPartialUpdateObject(t *testing.T) {
  _, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  object["job"] = "Knight"
  object["objectID"] = "àlgol?à"
  _, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  delete(object, "job")
  object["name"] = "Roger"
  resp, err := index.PartialUpdateObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  results, err := index.Search("", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  hits := results.(map[string]interface{})["hits"]
  shouldStr(hits.([]interface{})[0], "name", "Roger", "Unable to update an object", t)
  index.Delete()
}


func TestGetObject(t *testing.T) {
  _, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  object["objectID"] = "àlgol?à"
  resp, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  resp, err = index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  obj, err := index.GetObject("àlgol?à")
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldStr(obj, "name", "John Snow", "Unable to update an object", t)
  obj, err = index.GetObject("àlgol?à", "name")
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldStr(obj, "name", "John Snow", "Unable to update an object", t)
  index.Delete()
}

func TestGetObjectError(t *testing.T) {
  _, index := initTest(t)
  _, err := index.GetObject("", "test", "test")
  if err == nil {
    t.Fatalf("GetObject variadic args checking failed")
  }
}

func TestGetObjects(t *testing.T) {
  _, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "Los Angeles"
  object["objectID"] = "1"
  resp, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  object = make(map[string]interface{})
  object["name"] = "San Francisco"
  object["objectID"] = "2"
  resp, err = index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  res, err := index.GetObjects("1", "2")
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldStr(res.(map[string]interface{})["results"].([]interface{})[0], "name", "Los Angeles", "Unable to get objects", t)
  shouldStr(res.(map[string]interface{})["results"].([]interface{})[1], "name", "San Francisco", "Unable to get objects", t)

  index.Delete()
}


func TestDeleteObject(t *testing.T) {
  _, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  object["objectID"] = "àlgol?à"
  resp, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  resp, err = index.DeleteObject("àlgol?à")
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  results, err := index.Search("", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(results, "nbHits", 0, "Unable to clear the index", t)
  index.Delete()
}

func TestSetSettings(t *testing.T) {
  _, index := initTest(t)
  settings := make(map[string]interface{})
  settings["hitsPerPage"] = 30
  resp, err := index.SetSettings(settings)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  settingsChanged, err := index.GetSettings()
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(settingsChanged, "hitsPerPage", 30, "Unable to change setting", t)
  index.Delete()
}

func TestGetLogs(t *testing.T) {
  client, _ := initTest(t)
  logs, err := client.GetLogs(0, 100, false)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldHave(logs, "logs", "Unable to get logs", t)
}

func TestBrowse(t *testing.T) {
  _, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  object["objectID"] = "àlgol?à"
  resp, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  items, err := index.Browse(1, 1)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldHave(items, "hits", "Unable to browse index", t)
  index.Delete()
}

func TestQuery(t *testing.T) {
  _, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  object["objectID"] = "àlgol?à"
  resp, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  params := make(map[string]interface{})
  params["attributesToRetrieve"] = "*"
  params["getRankingInfo"] = 1
  results, err := index.Search("", params)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(results, "nbHits", 1, "Unable to query an index", t)
}

func TestCopy(t *testing.T) {
  client, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  object["objectID"] = "àlgol?à"
  _, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  resp, err := index.Copy("àlgo?à2-go")
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  indexCopy := client.InitIndex("àlgo?à2-go")
  results, err := indexCopy.Search("", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(results, "nbHits", 1, "Unable to copy an index", t)
  index.Delete()
  indexCopy.Delete()
}

func TestMove(t *testing.T) {
  client, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  object["objectID"] = "àlgol?à"
  task, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(task)
  if err != nil {
    t.Fatalf(err.Error())
  }
  resp, err := index.Move("àlgo?à2-go")
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }
  indexMove := client.InitIndex("àlgo?à2-go")
  results, err := indexMove.Search("", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(results, "nbHits", 1, "Unable to move an index", t)
  indexMove.Delete()
}

func TestAddIndexKey(t *testing.T) {
  _, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  resp, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  resp, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }

  acl := []string{"search"}
  newKey, err := index.AddKey(acl, 300, 100, 100)
  if err != nil {
    t.Fatalf(err.Error())
  }
  time.Sleep(1000 * time.Millisecond)
  key, err := index.GetKey(newKey.(map[string]interface{})["key"].(string))
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldStr(key, "value", newKey.(map[string]interface{})["key"].(string), "Unable to get a key", t)
  list, err := index.ListKeys()
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldContainString(list.(map[string]interface{})["keys"], "value", newKey.(map[string]interface{})["key"].(string), "Unable to add a key", t)
  _, err = index.DeleteKey(newKey.(map[string]interface{})["key"].(string))
  if err != nil {
    t.Fatalf(err.Error())
  }
  time.Sleep(1000 * time.Millisecond)
  list, err = index.ListKeys()
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldNotContainString(list.(map[string]interface{})["keys"], "value", newKey.(map[string]interface{})["key"].(string), "Unable to add a key", t)
  index.Delete() 
}

func TestAddKey(t *testing.T) {
  client, index := initTest(t)
  acl := []string{"search"}
  indexes := []string{index.name}
  newKey, err := client.AddKey(acl, indexes, 300, 100, 100)
  if err != nil {
    t.Fatalf(err.Error())
  }
  time.Sleep(1000 * time.Millisecond)
  key, err := client.GetKey(newKey.(map[string]interface{})["key"].(string))
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldStr(key, "value", newKey.(map[string]interface{})["key"].(string), "Unable to get a key", t)
  list, err := client.ListKeys()
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldContainString(list.(map[string]interface{})["keys"], "value", newKey.(map[string]interface{})["key"].(string), "Unable to add a key", t)
  _, err = client.DeleteKey(newKey.(map[string]interface{})["key"].(string))
  if err != nil {
    t.Fatalf(err.Error())
  }
  time.Sleep(1000 * time.Millisecond)
  list, err = client.ListKeys()
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldNotContainString(list.(map[string]interface{})["keys"], "value", newKey.(map[string]interface{})["key"].(string), "Unable to add a key", t)
}

func TestAddObjects(t *testing.T) {
  _, index := initTest(t)
  objects := make([]interface{}, 2)

  object := make(map[string]interface{})
  object["name"] = "John"
  object["city"] = "San Francisco"
  objects[0] = object

  object = make(map[string]interface{})
  object["name"] = "Roger"
  object["city"] = "New York"
  objects[1] = object
  task, err := index.AddObjects(objects)
  if err != nil {
    t.Fatalf(err.Error())
  }
  index.WaitTask(task)
  results, err := index.Search("", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(results, "nbHits", 2, "Unable to add objects", t)
  index.Delete()
}

func TestUpdateObjects(t *testing.T) {
  _, index := initTest(t)
  objects := make([]interface{}, 2)

  object := make(map[string]interface{})
  object["name"] = "John"
  object["city"] = "San Francisco"
  object["objectID"] = "àlgo?à-1"
  objects[0] = object

  object = make(map[string]interface{})
  object["name"] = "Roger"
  object["city"] = "New York"
  object["objectID"] = "àlgo?à-2"
  objects[1] = object
  task, err := index.UpdateObjects(objects)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(task)
  if err != nil {
    t.Fatalf(err.Error())
  }
  results, err := index.Search("", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(results, "nbHits", 2, "Unable to update objects", t)
  index.Delete()
}

func TestPartialUpdateObjects(t *testing.T) {
  _, index := initTest(t)
  objects := make([]interface{}, 2)

  object := make(map[string]interface{})
  object["name"] = "John"
  object["objectID"] = "àlgo?à-1"
  objects[0] = object

  object = make(map[string]interface{})
  object["name"] = "Roger"
  object["objectID"] = "àlgo?à-2"
  objects[1] = object
  task, err := index.PartialUpdateObjects(objects)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(task)
  if err != nil {
    t.Fatalf(err.Error())
  }
  results, err := index.Search("", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(results, "nbHits", 2, "Unable to partial update objects", t)
  index.Delete()
}

func TestDeleteObjects(t *testing.T) {
  _, index := initTest(t)
  objects := make([]interface{}, 2)

  object := make(map[string]interface{})
  object["name"] = "John"
  object["objectID"] = "àlgo?à-1"
  objects[0] = object

  object = make(map[string]interface{})
  object["name"] = "Roger"
  object["objectID"] = "àlgo?à-2"
  objects[1] = object
  task, err := index.PartialUpdateObjects(objects)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(task)
  if err != nil {
    t.Fatalf(err.Error())
  }
  objectIDs := []string{"àlgo?à-1", "àlgo?à-2"}
  task, err = index.DeleteObjects(objectIDs)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(task)
  if err != nil {
    t.Fatalf(err.Error())
  }
  results, err := index.Search("", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(results, "nbHits", 0, "Unable to partial update objects", t)
  index.Delete()
}

func TestDeleteByQuery(t *testing.T) {
  _, index := initTest(t)
  objects := make([]interface{}, 3)

  object := make(map[string]interface{})
  object["name"] = "San Jose"
  objects[0] = object

  object = make(map[string]interface{})
  object["name"] = "Washington"
  objects[1] = object

  object = make(map[string]interface{})
  object["name"] = "San Francisco"
  objects[2] = object
  task, err := index.AddObjects(objects)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.WaitTask(task)
  if err != nil {
    t.Fatalf(err.Error())
  }
  _, err = index.DeleteByQuery("San", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  results, err := index.Search("", nil)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(results, "nbHits", 1, "Unable to delete by query", t)
  index.Delete()
}


/*
func TestKeepAlive(t *testing.T) {
  _, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  object["objectID"] = "àlgol?à"
  _, err := index.addObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  query := make(map[string]interface{})
  for i := 0; i < 100; i++ {
    index.query(query)
  }
}*/

func TestGenerateSecuredApiKey(t *testing.T) {
  client, _ := initTest(t)
  key, _ := client.GenerateSecuredApiKey("my_api_key", "(public,user1)")
  if "1fd74b206c64fb49fdcd7a5f3004356cd3bdc9d9aba8733656443e64daafc417" != key {
    t.Fatalf("Invalid key: " + key)
  }
  key, _ = client.GenerateSecuredApiKey("my_api_key", "(public,user1)", "user1")
  if "5d50c79541de552654e3fad2091c38a457b56992d61b342fb09da8c42fbbe043" != key {
    t.Fatalf("Invalid key: " + key)
  }
}

func TestMultipleQueries(t *testing.T) {
  client, index := initTest(t)
  object := make(map[string]interface{})
  object["name"] = "John Snow"
  resp, err := index.AddObject(object)
  if err != nil {
    t.Fatalf(err.Error())
  }
  resp, err = index.WaitTask(resp)
  if err != nil {
    t.Fatalf(err.Error())
  }

  query := make(map[string]interface{})
  query["indexName"] = "àlgol?à-go"
  query["query"] = ""
  queries := make([]interface{}, 1)
  queries[0] = query
  res, err := client.MultipleQueries(queries)
  if err != nil {
    t.Fatalf(err.Error())
  }
  shouldFloat(res.(map[string]interface{})["results"].([]interface{})[0], "nbHits", 1, "Unable to query multiple indexes", t)
  index.Delete()
}
