package rollbar

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"testing"
)

var (
	itemsService = ItemsService{client}
)

func TestGettingItems(t *testing.T) {
	mux.HandleFunc("/items", func(w http.ResponseWriter, r *http.Request) {
		if m := "GET"; m != r.Method {
			t.Errorf("Request method = %v, want %v", r.Method, m)
		}

		filename := "fixtures/items.json"
		content, err := ioutil.ReadFile(filename)
		if err != nil {
			panic(fmt.Sprintf("Error trying to read fixture file: %v", filename))
		}

		fmt.Fprint(w, string(content))
	})

	itemsResp, err := itemsService.All()
	if err != nil {
		t.Errorf("Expected empty error response, got: %v", err)
	}

	items := itemsResp.Result.Items
	if len(items) < 1 {
		t.Errorf("Items length: %v, want 2", len(items))
	}
}
