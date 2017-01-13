package algoliasearch

import (
	"os"
	"sync"
	"testing"
)

// waitTask waits the task to be finished. If something went wrong, the
// `testing.T` variable is used to terminate the test case (call to `Fatal`).
func waitTask(t *testing.T, i Index, taskID int) {
	err := i.WaitTask(taskID)
	if err != nil {
		t.Fatalf("waitTask: Task %d not published: %s", taskID, err)
	}
}

// waitTasksAsync waits for the given `tasks` asynchronously. `waitTask` is
// caled for every taskID but everything is done concurrently.
func waitTasksAsync(t *testing.T, i Index, tasks []int) {
	var wg sync.WaitGroup

	for _, task := range tasks {
		wg.Add(1)

		go func(taskID int) {
			defer wg.Done()
			waitTask(t, i, taskID)
		}(task)
	}

	wg.Wait()
}

// addOneObject is used to add a single dummy object to the index. This way, we
// make sure the index has been created (and not only initialized).
func addOneObject(t *testing.T, c Client, i Index) string {
	object := Object{"attribute": "value"}

	res, err := i.AddObject(object)
	if err != nil {
		t.Fatalf("addOneObject: Cannot add an object: %s", err)
	}

	waitTask(t, i, res.TaskID)

	return res.ObjectID
}

// initClient instantiates a new client according to the
// `ALGOLIA_APPLICATION_ID` and `ALGOLIA_API_KEY` environment variables.
func initClient(t *testing.T) Client {
	appID := os.Getenv("ALGOLIA_APPLICATION_ID")
	apiKey := os.Getenv("ALGOLIA_API_KEY")

	if appID == "" || apiKey == "" {
		t.Fatal("initClient: Missing ALGOLIA_APPLICATION_ID and/or ALGOLIA_API_KEY")
	}

	return NewClient(appID, apiKey)
}

// initClientWithHosts instantiates a new client according to the
// `ALGOLIA_APPLICATION_ID` and `ALGOLIA_API_KEY` environment variables and set
// one of the host to specifically timeout.
func initClientWithTimeoutHosts(t *testing.T) Client {
	appID := os.Getenv("ALGOLIA_APPLICATION_ID")
	apiKey := os.Getenv("ALGOLIA_API_KEY")

	if appID == "" || apiKey == "" {
		t.Fatal("initClient: Missing ALGOLIA_APPLICATION_ID and/or ALGOLIA_API_KEY")
	}

	return NewClientWithHosts(appID, apiKey, []string{"algolia.biz"})
}

// initIndex init the `c` client with the index called `name`. It also deletes
// the index if it was existing beforehand. It waits until the task is
// finished.
func initIndex(t *testing.T, c Client, name string) (i Index) {
	i = c.InitIndex(name).(*index)

	// List indices
	indexes, err := c.ListIndexes()
	if err != nil {
		t.Fatalf("initIndex: Cannot list existing indexes: %s", err)
	}

	// Delete index if it already exists
	for _, index := range indexes {
		if index.Name == name {
			res, err := i.Delete()
			if err != nil {
				t.Fatalf("initIndex: Cannot delete the index '%s': %s", name, err)
			}

			waitTask(t, i, res.TaskID)
		}
	}

	return
}

// initClientAndIndex is a wrapper for both the `initClient` and `initIndex`.
// Please check them for more detailed informations.
func initClientAndIndex(t *testing.T, name string) (c Client, i Index) {
	c = initClient(t)
	i = initIndex(t, c, name)

	return
}
