package algoliasearch

import "syscall"
import "strconv"
import "testing"
import "time"

func safeName(name string) string {
	travis, haveTravis := syscall.Getenv("TRAVIS")
	buildId, haveBuildId := syscall.Getenv("TRAVIS_JOB_NUMBER")
	if !haveTravis || !haveBuildId || travis != "true" {
		return name
	}

	return name + "_travis-" + buildId
}

func initTest(t *testing.T) (*Client, *Index) {
	appID, haveAppID := syscall.Getenv("ALGOLIA_APPLICATION_ID")
	apiKey, haveApiKey := syscall.Getenv("ALGOLIA_API_KEY")
	if !haveApiKey || !haveAppID {
		t.Fatalf("Need ALGOLIA_APPLICATION_ID and ALGOLIA_API_KEY")
	}
	client := NewClient(appID, apiKey)
	client.SetTimeout(1000, 10000)
	hosts := make([]string, 3)
	hosts[0] = appID + "-1.algolia.net"
	hosts[1] = appID + "-2.algolia.net"
	hosts[2] = appID + "-3.algolia.net"
	client = NewClientWithHosts(appID, apiKey, hosts)
	index := client.InitIndex(safeName("àlgol?à-go"))

	return client, index
}

func shouldHave(json interface{}, attr, msg string, t *testing.T) {
	_, ok := json.(map[string]interface{})[attr]
	if !ok {
		t.Fatalf(msg + ", expected attribute: " + attr)
	}
}

func shouldNotHave(json interface{}, attr, msg string, t *testing.T) {
	_, ok := json.(map[string]interface{})[attr]
	if ok {
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
	logs, err := client.GetLogs(0, 100, "all")
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

func TestBrowseWithCursor(t *testing.T) {
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
	items, err := index.BrowseAll(map[string]interface{}{"query": ""})
	if err != nil {
		t.Fatalf(err.Error())
	}
	hit, err := items.Next()
	if err != nil {
		t.Fatalf(err.Error())
	}
	shouldStr(hit, "name", "John Snow", "Unable to browse index with cursor", t)
	hit, err = items.Next()
	if err == nil {
		t.Fatalf("Should contains only one elt")
	}
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

func TestIndexCopy(t *testing.T) {
	client, index := initTest(t)
	object := make(map[string]interface{})
	object["name"] = "John Snow"
	object["objectID"] = "àlgol?à"
	_, err := index.AddObject(object)
	if err != nil {
		t.Fatalf(err.Error())
	}
	resp, err := index.Copy(safeName("àlgo?à2-go"))
	if err != nil {
		t.Fatalf(err.Error())
	}
	_, err = index.WaitTask(resp)
	if err != nil {
		t.Fatalf(err.Error())
	}
	indexCopy := client.InitIndex(safeName("àlgo?à2-go"))
	results, err := indexCopy.Search("", nil)
	if err != nil {
		t.Fatalf(err.Error())
	}
	shouldFloat(results, "nbHits", 1, "Unable to copy an index", t)
	index.Delete()
	indexCopy.Delete()
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
	resp, err := client.CopyIndex(safeName("àlgol?à-go"), safeName("àlgo?à2-go"))
	if err != nil {
		t.Fatalf(err.Error())
	}
	_, err = index.WaitTask(resp)
	if err != nil {
		t.Fatalf(err.Error())
	}
	indexCopy := client.InitIndex(safeName("àlgo?à2-go"))
	results, err := indexCopy.Search("", nil)
	if err != nil {
		t.Fatalf(err.Error())
	}
	shouldFloat(results, "nbHits", 1, "Unable to copy an index", t)
	index.Delete()
	indexCopy.Delete()
}

func TestIndexMove(t *testing.T) {
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
	resp, err := index.Move(safeName("àlgo?à2-go"))
	if err != nil {
		t.Fatalf(err.Error())
	}
	_, err = index.WaitTask(resp)
	if err != nil {
		t.Fatalf(err.Error())
	}
	indexMove := client.InitIndex(safeName("àlgo?à2-go"))
	results, err := indexMove.Search("", nil)
	if err != nil {
		t.Fatalf(err.Error())
	}
	shouldFloat(results, "nbHits", 1, "Unable to move an index", t)
	indexMove.Delete()
}

func TestMove(t *testing.T) {
	client, index := initTest(t)
	object := make(map[string]interface{})
	object["name"] = "John Snow"
	object["objectID"] = "àlgol?à"
	_, err := index.AddObject(object)
	if err != nil {
		t.Fatalf(err.Error())
	}
	resp, err := client.MoveIndex(safeName("àlgol?à-go"), safeName("àlgo?à2-go"))
	if err != nil {
		t.Fatalf(err.Error())
	}
	_, err = index.WaitTask(resp)
	if err != nil {
		t.Fatalf(err.Error())
	}
	indexCopy := client.InitIndex(safeName("àlgo?à2-go"))
	results, err := indexCopy.Search("", nil)
	if err != nil {
		t.Fatalf(err.Error())
	}
	shouldFloat(results, "nbHits", 1, "Unable to copy an index", t)
	index.Delete()
	indexCopy.Delete()
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
	time.Sleep(5000 * time.Millisecond)
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

	_, err = index.UpdateKey(newKey.(map[string]interface{})["key"].(string), []string{"addObject"}, 300, 100, 100)
	if err != nil {
		t.Fatalf(err.Error())
	}
	time.Sleep(5000 * time.Millisecond)
	list, err = index.ListKeys()
	if err != nil {
		t.Fatalf(err.Error())
	}
	shouldContainString(list.(map[string]interface{})["keys"], "value", newKey.(map[string]interface{})["key"].(string), "Unable to add a key", t)

	_, err = index.DeleteKey(newKey.(map[string]interface{})["key"].(string))
	if err != nil {
		t.Fatalf(err.Error())
	}
	time.Sleep(5000 * time.Millisecond)
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
	time.Sleep(5000 * time.Millisecond)
	key, err := client.GetKey(newKey.(map[string]interface{})["key"].(string))
	if err != nil {
		t.Fatalf(err.Error())
	}
	shouldStr(key, "value", newKey.(map[string]interface{})["key"].(string), "Unable to get a key", t)

	_, err = client.UpdateKey(newKey.(map[string]interface{})["key"].(string), []string{"addObject"}, indexes, 300, 100, 100)
	if err != nil {
		t.Fatalf(err.Error())
	}
	time.Sleep(5000 * time.Millisecond)

	list, err := client.ListKeys()
	if err != nil {
		t.Fatalf(err.Error())
	}
	shouldContainString(list.(map[string]interface{})["keys"], "value", newKey.(map[string]interface{})["key"].(string), "Unable to add a key", t)
	_, err = client.DeleteKey(newKey.(map[string]interface{})["key"].(string))
	if err != nil {
		t.Fatalf(err.Error())
	}
	time.Sleep(5000 * time.Millisecond)
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

func TestGenerateNewSecuredApiKey(t *testing.T) {
	client, _ := initTest(t)
	key, _ := client.GenerateSecuredApiKey("182634d8894831d5dbce3b3185c50881", "(public,user1)")
	expected := "MDZkNWNjNDY4M2MzMDA0NmUyNmNkZjY5OTMzYjVlNmVlMTk1NTEwMGNmNTVjZmJhMmIwOTIzYjdjMTk2NTFiMnRhZ0ZpbHRlcnM9JTI4cHVibGljJTJDdXNlcjElMjk="
	if expected != key {
		t.Fatalf("Invalid key: " + key + " != " + expected)
	}
	key, _ = client.GenerateSecuredApiKey("182634d8894831d5dbce3b3185c50881", "tagFilters=%28public%2Cuser1%29")
	expected = "MDZkNWNjNDY4M2MzMDA0NmUyNmNkZjY5OTMzYjVlNmVlMTk1NTEwMGNmNTVjZmJhMmIwOTIzYjdjMTk2NTFiMnRhZ0ZpbHRlcnM9JTI4cHVibGljJTJDdXNlcjElMjk="
	if expected != key {
		t.Fatalf("Invalid key: " + key + " != " + expected)
	}
	key, _ = client.GenerateSecuredApiKey("182634d8894831d5dbce3b3185c50881", map[string]interface{}{"tagFilters": "(public,user1)"})
	expected = "MDZkNWNjNDY4M2MzMDA0NmUyNmNkZjY5OTMzYjVlNmVlMTk1NTEwMGNmNTVjZmJhMmIwOTIzYjdjMTk2NTFiMnRhZ0ZpbHRlcnM9JTI4cHVibGljJTJDdXNlcjElMjk="
	if expected != key {
		t.Fatalf("Invalid key: " + key + " != " + expected)
	}
	key, _ = client.GenerateSecuredApiKey("182634d8894831d5dbce3b3185c50881", map[string]interface{}{"tagFilters": "(public,user1)", "userToken": "42"})
	expected = "OGYwN2NlNTdlOGM2ZmM4MjA5NGM0ZmYwNTk3MDBkNzMzZjQ0MDI3MWZjNTNjM2Y3YTAzMWM4NTBkMzRiNTM5YnRhZ0ZpbHRlcnM9JTI4cHVibGljJTJDdXNlcjElMjkmdXNlclRva2VuPTQy"
	if expected != key {
		t.Fatalf("Invalid key: " + key + " != " + expected)
	}
	key, _ = client.GenerateSecuredApiKey("182634d8894831d5dbce3b3185c50881", map[string]interface{}{"tagFilters": "(public,user1)"}, "42")
	expected = "OGYwN2NlNTdlOGM2ZmM4MjA5NGM0ZmYwNTk3MDBkNzMzZjQ0MDI3MWZjNTNjM2Y3YTAzMWM4NTBkMzRiNTM5YnRhZ0ZpbHRlcnM9JTI4cHVibGljJTJDdXNlcjElMjkmdXNlclRva2VuPTQy"
	if expected != key {
		t.Fatalf("Invalid key: " + key + " != " + expected)
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
	query["indexName"] = safeName("àlgol?à-go")
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

func TestFacets(t *testing.T) {
	_, index := initTest(t)

	settings := map[string]interface{}{"attributesForFacetting": []string{"f", "g"}}
	_, err := index.SetSettings(settings)
	if err != nil {
		t.Fatalf(err.Error())
	}

	_, err = index.AddObject(map[string]interface{}{"f": "f1", "g": "g1"})
	if err != nil {
		t.Fatalf(err.Error())
	}
	_, err = index.AddObject(map[string]interface{}{"f": "f1", "g": "g2"})
	if err != nil {
		t.Fatalf(err.Error())
	}
	_, err = index.AddObject(map[string]interface{}{"f": "f2", "g": "g2"})
	if err != nil {
		t.Fatalf(err.Error())
	}
	task, err := index.AddObject(map[string]interface{}{"f": "f3", "g": "g2"})
	if err != nil {
		t.Fatalf(err.Error())
	}
	_, err = index.WaitTask(task)
	if err != nil {
		t.Fatalf(err.Error())
	}

	res, err := index.Search("", map[string]interface{}{"facets": "f", "facetFilters": []string{"f:f1"}})
	if err != nil {
		t.Fatalf(err.Error())
	}
	shouldFloat(res, "nbHits", 2, "Unable to filter facets", t)

	index.Delete()
}
