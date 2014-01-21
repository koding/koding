package rollbar

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"testing"
)

var (
	instancesService = InstanceService{client}
)

func TestGettingInstancesOfItem(t *testing.T) {
	mux.HandleFunc("/item/272364549/instances/", func(w http.ResponseWriter, r *http.Request) {
		if m := "GET"; m != r.Method {
			t.Errorf("Request method = %v, want %v", r.Method, m)
		}

		filename := "fixtures/instances/272364549.json"
		content, err := ioutil.ReadFile(filename)
		if err != nil {
			panic(fmt.Sprintf("Error trying to read fixture file: %v", filename))
		}

		fmt.Fprint(w, string(content))
	})

	instancesResp, err := instancesService.GetByItem(272364549)
	if err != nil {
		t.Errorf("Expected empty error response, got: %v", err)
	}

	instances := instancesResp.Result.Instances
	if len(instances) < 1 {
		t.Errorf("Instances length: %v, want 20", len(instances))
	}
}
