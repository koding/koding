package udnssdk

import (
	"testing"
)

func Test_ListTasks(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	tasks, err := testClient.Tasks.Select("")
	t.Logf("Tasks: %+v \n", tasks)
	if err != nil {
		t.Fatal(err)
	}
}
