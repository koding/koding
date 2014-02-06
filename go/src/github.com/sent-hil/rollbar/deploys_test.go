package rollbar

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"testing"
)

var (
	deploysService = DeployService{client}
)

func TestGettingDeploys(t *testing.T) {
	mux.HandleFunc("/deploys/", func(w http.ResponseWriter, r *http.Request) {
		if m := "GET"; m != r.Method {
			t.Errorf("Request method = %v, want %v", r.Method, m)
		}

		filename := "fixtures/deploys.json"
		content, err := ioutil.ReadFile(filename)
		if err != nil {
			panic(fmt.Sprintf("Error trying to read fixture file: %v", filename))
		}

		fmt.Fprint(w, string(content))
	})

	var deploysResp, err = deploysService.All()
	if err != nil {
		t.Errorf("Expected empty error response, got: %v", err)
	}

	var deploys = deploysResp.Result.Deploys
	if len(deploys) < 1 {
		t.Errorf("Instances length: %v, want 20", len(deploys))
	}
}
