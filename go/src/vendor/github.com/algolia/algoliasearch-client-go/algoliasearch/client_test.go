package algoliasearch

import (
	"sync"
	"testing"
	"time"
)

func TestClientOperations(t *testing.T) {
	t.Parallel()
	c, i := initClientAndIndex(t, "TestClientOperations")

	objectID := addOneObject(t, c, i)

	t.Log("TestClientOperations: Test CopyIndex")
	{
		res, err := c.CopyIndex("TestClientOperations", "TestClientOperations_copy")
		if err != nil {
			t.Fatalf("TestClientOperations: Cannot copy the index: %s", err)
		}

		waitTask(t, i, res.TaskID)
	}

	t.Log("TestClientOperations: Test MoveIndex")
	i = c.InitIndex("TestClientOperations_copy")
	{
		res, err := c.MoveIndex("TestClientOperations_copy", "TestClientOperations_move")
		if err != nil {
			t.Fatalf("TestClientOperations: Cannot move the index: %s", err)
		}

		waitTask(t, i, res.TaskID)
	}

	t.Log("TestClientOperations: Test ClearIndex")
	i = c.InitIndex("TestClientOperations_move")
	{
		res, err := c.ClearIndex("TestClientOperations_move")
		if err != nil {
			t.Fatalf("TestClear: Cannot clear the index: %s, err")
		}

		waitTask(t, i, res.TaskID)

		_, err = i.GetObject(objectID, nil)
		if err == nil || err.Error() != "{\"message\":\"ObjectID does not exist\",\"status\":404}\n" {
			t.Fatalf("TestClientOperations: Object %s should be deleted after clear: %s", objectID, err)
		}
	}

	t.Log("TestClientOperations: Test DeleteIndex")
	{
		_, err := c.DeleteIndex("TestClientOperations_move")
		if err != nil {
			t.Fatalf("TestClientOperations: Cannot delete the moved index: %s", err)
		}
	}
}

// deleteClientKey deletes the key for the given client.
func deleteClientKey(t *testing.T, c Client, key string) {
	_, err := c.DeleteUserKey(key)
	if err != nil {
		t.Fatalf("deleteClientKey: Cannot delete key: %s", err)
	}
}

// waitClientKey waits until the key has been properly added to the given
// client and if the given function, if not `nil`, returns `true`.
func waitClientKey(t *testing.T, c Client, keyID string, f func(k Key) bool) {
	retries := 120

	for r := 0; r < retries; r++ {
		key, err := c.GetUserKey(keyID)

		if err == nil && (f == nil || f(key)) {
			return
		}
		time.Sleep(1 * time.Second)
	}

	t.Fatalf("waitClientKey: Key not found or function call failed")
}

// waitClientKeysAsync waits until all the keys have been properly added to the
// given client and if the given function, if not `nil`, returns `true` for
// every key.
func waitClientKeysAsync(t *testing.T, c Client, keyIDs []string, f func(k Key) bool) {
	var wg sync.WaitGroup

	for _, keyID := range keyIDs {
		wg.Add(1)

		go func(keyID string) {
			defer wg.Done()
			waitClientKey(t, c, keyID, f)
		}(keyID)
	}

	wg.Wait()
}

// deleteAllClientKeys properly deletes all previous keys associated to the
// application.
func deleteAllClientKeys(t *testing.T, c Client) {
	keys, err := c.ListKeys()

	if err != nil {
		t.Fatalf("deleteAllKeys: Cannot list the keys: %s", err)
	}

	for _, key := range keys {
		_, err = c.DeleteUserKey(key.Value)
		if err != nil {
			t.Fatalf("deleteAllKeys: Cannot delete a key: %s", err)
		}
	}

	for len(keys) != 0 {
		keys, err = c.ListKeys()

		if err != nil {
			t.Fatalf("deleteAllKeys: Cannot list the keys: %s", err)
		}

		time.Sleep(1 * time.Second)
	}
}

func TestClientKeys(t *testing.T) {
	t.Parallel()
	c := initClient(t)

	deleteAllClientKeys(t, c)

	var searchKey, allRightsKey string

	t.Log("TestClientKeys: Add a search key with parameters")
	{
		params := Map{
			"description":            "",
			"maxQueriesPerIPPerHour": 1000,
			"referers":               []string{},
			"queryParameters":        "typoTolerance=strict",
			"validity":               600,
			"maxHitsPerQuery":        1,
		}

		res, err := c.AddUserKey([]string{"search"}, params)
		if err != nil {
			t.Fatalf("TestClientKeys: Cannot create the search key: %s", err)
		}

		searchKey = res.Key
	}
	defer deleteClientKey(t, c, searchKey)

	t.Log("TestClientKeys: Add an all-permissions key")
	{
		acl := []string{
			"search",
			"browse",
			"addObject",
			"deleteObject",
			"deleteIndex",
			"settings",
			"editSettings",
			"analytics",
			"listIndexes",
		}

		res, err := c.AddUserKey(acl, nil)
		if err != nil {
			t.Fatalf("TestClientKeys: Cannot create the all-rights key: %s", err)
		}

		allRightsKey = res.Key
	}
	defer deleteClientKey(t, c, allRightsKey)

	waitClientKeysAsync(t, c, []string{searchKey, allRightsKey}, nil)

	t.Log("TestClientKeys: Update search key description")
	{
		params := Map{"description": "Search-Only Key"}

		_, err := c.UpdateUserKey(searchKey, params)
		if err != nil {
			t.Fatalf("TestClientKeys: Cannot update search only key's description: %s", err)
		}

		waitClientKey(t, c, searchKey, func(k Key) bool { return k.Description == "Search-Only Key" })
	}
}

func TestLogs(t *testing.T) {
	t.Parallel()
	c := initClient(t)

	params := Map{
		"length": 10,
		"offset": 0,
		"type":   "all",
	}

	t.Log("TestLogs: Get the last 10 logs")
	logs, err := c.GetLogs(params)

	if err != nil {
		t.Fatalf("TestLogs: Cannot retrieve the logs: %s", err)
	}

	if len(logs) != 10 {
		t.Fatalf("TestLogs: Should return 10 logs instead of %d", len(logs))
	}
}

func TestMultipleQueries(t *testing.T) {
	t.Parallel()
	c := initClient(t)
	defer c.DeleteIndex("TestMultipleQueries_categories")
	defer c.DeleteIndex("TestMultipleQueries_products")

	var tasks []int

	t.Log("TestMultipleQueries: Set the `categories` index settings")
	i := c.InitIndex("TestMultipleQueries_categories")
	{
		res, err := i.SetSettings(Map{
			"searchableAttributes": []string{"name"},
		})

		if err != nil {
			t.Fatalf("TestMultipleQueries: Cannot set `categories` index settings: %s", err)
		}
		tasks = append(tasks, res.TaskID)
	}

	t.Log("TestMultipleQueries: Add an object to the `categories` index")
	{
		res, err := i.AddObject(Object{
			"name": "computer 1",
		})

		if err != nil {
			t.Fatalf("TestMultipleQueries: Cannot add object to `categories` index: %s", err)
		}

		tasks = append(tasks, res.TaskID)
	}

	waitTasksAsync(t, i, tasks)
	tasks = []int{}

	t.Log("TestMultipleQueries: Set the `products` index settings")
	i = c.InitIndex("TestMultipleQueries_products")
	{
		res, err := i.SetSettings(Map{
			"searchableAttributes": []string{"name"},
		})

		if err != nil {
			t.Fatalf("TestMultipleQueries: Cannot set `products` index settings: %s", err)
		}

		tasks = append(tasks, res.TaskID)
	}

	t.Log("TestMultipleQueries: Add an object to the `products` index")
	{
		res, err := i.AddObjects([]Object{
			{"name": "computer 1"},
			{"name": "computer 2", "_tags": "promotion"},
			{"name": "computer 3", "_tags": "promotion"},
		})

		if err != nil {
			t.Fatalf("TestMultipleQueries: Cannot add objects to `products` index: %s", err)
		}

		tasks = append(tasks, res.TaskID)
	}

	waitTasksAsync(t, i, tasks)

	queries := []IndexedQuery{
		{
			IndexName: "TestMultipleQueries_categories",
			Params:    Map{"query": "computer", "hitsPerPage": 2},
		},
		{
			IndexName: "TestMultipleQueries_products",
			Params:    Map{"query": "computer", "hitsPerPage": 3, "filters": "_tags:promotion"},
		},
		{
			IndexName: "TestMultipleQueries_products",
			Params:    Map{"query": "computer", "hitsPerPage": 4},
		},
	}

	res, err := c.MultipleQueries(queries, "")

	if err != nil {
		t.Fatalf("TestMultipleQueries: Cannot send multiple queries: %s", err)
	}

	if len(res) != 3 {
		t.Fatalf("TestMultipleQueries: Should return 3 MultipleQueryRes instead of %d", len(res))
	}

	if len(res[0].Hits) != 1 {
		t.Fatalf("TestMultipleQueries: First query should return 1 record instead of %d", len(res[0].Hits))
	}

	if len(res[1].Hits) != 2 {
		t.Fatalf("TestMultipleQueries: Second query should return 2 records instead of %d", len(res[1].Hits))
	}

	if len(res[2].Hits) != 3 {
		t.Fatalf("TestMultipleQueries: Third query should return 3 records instead of %d", len(res[2].Hits))
	}
}

func TestBatch(t *testing.T) {
	t.Parallel()
	c := initClient(t)
	defer c.DeleteIndex("TestBatch_dev")
	defer c.DeleteIndex("TestBatch_prod")

	person := Map{
		"firstname": "Jimmie",
		"lastname":  "Barninger",
	}

	operation := BatchOperation{
		Action: "addObject",
		Body:   person,
	}

	operations := []BatchOperationIndexed{
		{IndexName: "TestBatch_dev", BatchOperation: operation},
		{IndexName: "TestBatch_prod", BatchOperation: operation},
	}

	_, err := c.Batch(operations)

	if err != nil {
		t.Fatalf("TestBatch: Cannot batch operations: %s", err)
	}
}

func TestSlaveReplica(t *testing.T) {
	t.Parallel()
	c, i := initClientAndIndex(t, "TestSlaveReplica")

	defer c.DeleteIndex("TestSlaveReplica_slave")
	defer c.DeleteIndex("TestSlaveReplica_replica")

	t.Log("TestSlaveReplica: Set the `slaves` settings")
	slaves := []string{"TestSlaveReplica_slave"}
	expectedSettings := Map{"slaves": slaves}

	res, err := i.SetSettings(expectedSettings)
	if err != nil {
		t.Fatalf("TestSlaveReplica: Cannot set the `slaves` settings: %s", err)
	}
	if err = i.WaitTask(res.TaskID); err != nil {
		t.Fatalf("TestSlaveReplica: SetSettings of `slaves` task didn't finished properly: %s", err)
	}

	t.Log("TestSlaveReplica: Check that the `slaves` settings is properly set")
	settings, err := i.GetSettings()
	if err != nil {
		t.Fatalf("TestSlaveReplica: Cannot get the settings: %s", err)
	}

	if len(settings.Slaves) != 1 || settings.Slaves[0] != slaves[0] {
		t.Fatalf("TestSlaveReplica: Slaves settings are not the same:\nExpected:%s\nGot:%s", slaves, settings.Slaves)
	}

	t.Log("TestSlaveReplica: Set the `replicas` settings")
	replicas := []string{"TestSlaveReplica_replica"}
	expectedSettings = Map{"replicas": replicas}

	res, err = i.SetSettings(expectedSettings)
	if err != nil {
		t.Fatalf("TestSlaveReplica: Cannot set the `replicas` settings: %s", err)
	}
	if err = i.WaitTask(res.TaskID); err != nil {
		t.Fatalf("TestSlaveReplica: SetSettings of `replicas` task didn't finished properly: %s", err)
	}

	t.Log("TestSlaveReplica: Check that the `replicas` settings is properly set and override the `slaves` settings")
	settings, err = i.GetSettings()
	if err != nil {
		t.Fatalf("TestSlaveReplica: Cannot get the settings: %s", err)
	}

	if len(settings.Slaves) != 0 {
		t.Fatalf("TestSlaveReplica: Slaves settings has not been overriden: %s", settings.Slaves)
	}

	if len(settings.Replicas) != 1 || settings.Replicas[0] != replicas[0] {
		t.Fatalf("TestSlaveReplica: Replicas settings are not the same:\nExpected:%s\nGot:%s", replicas, settings.Replicas)
	}
}

func TestDnsTimeout(t *testing.T) {
	t.Parallel()

	client := initClientWithTimeoutHosts(t)

	start := time.Now()
	for i := 0; i < 10; i++ {
		client.ListIndexes()
	}
	delta := time.Now().Sub(start)

	if delta > 5*time.Second {
		t.Fatalf("TestDnsTimeout: Spent %d seconds instead of <5s to perform the 10 retries", int(delta.Seconds()))
	}
}
