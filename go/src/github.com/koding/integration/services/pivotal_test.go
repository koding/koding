package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/koding/integration/helpers"
	"github.com/koding/logging"
)

func TestConfigureCreatePivotalWebhook(t *testing.T) {
	service := CreateTestPivotalService(t)
	mux := http.NewServeMux()
	server := httptest.NewServer(mux)

	project_id := "123456"
	webhook_id := "1234567"

	mux.HandleFunc(fmt.Sprintf("/projects/%s/webhooks", project_id),
		func(w http.ResponseWriter, r *http.Request) {
			if r.Method != "POST" {
				w.WriteHeader(404)
				return
			}
			w.Header().Set("Content-Type", "application/json")

			fmt.Fprintln(w, createPivotalWebhookResponse)
		},
	)

	mux.HandleFunc(fmt.Sprintf("/projects/%s/webhooks/%s", project_id, webhook_id),
		func(w http.ResponseWriter, r *http.Request) {
			if r.Method != "PUT" {
				w.WriteHeader(404)
				return
			}
			w.Header().Set("Content-Type", "application/json")

			fmt.Fprintln(w, updatePivotalWebhookResponse)
		},
	)

	defer server.Close()
	service.serverURL = server.URL

	// test create
	emptyStr := ""
	reqData := createPivotalWebhookRequestData(
		createPivotalWebhookSettings(&emptyStr, &project_id), nil,
	)

	res, err := doConfigurePivotalRequest(t, service, reqData)
	if err != nil {
		t.Fatalf("Expected nil, got %s", err)
	}

	if res["webhook_id"].(string) != webhook_id {
		t.Fatalf("Expected %s, got %d", webhook_id, res["webhook_id"])
	}

	// test update
	reqData = createPivotalWebhookRequestData(
		createPivotalWebhookSettings(&webhook_id, &project_id), nil,
	)

	res, err = doConfigurePivotalRequest(t, service, reqData)
	if err != nil {
		t.Fatalf("Expected nil, got %s", err)
	}

	if res["webhook_id"].(string) != webhook_id {
		t.Fatalf("Expected %s, got %d", webhook_id, res["webhook_id"])
	}
}

func CreateTestPivotalService(t *testing.T) *Pivotal {
	pv := Pivotal{}
	pv.publicURL = "http://koding.com/api/webhook"
	pv.integrationURL = "http://koding.com/api/integration"
	pv.log = logging.NewLogger("testing")

	pc := &PivotalConfig{
		ServerURL:      "",
		PublicURL:      pv.publicURL,
		IntegrationURL: pv.integrationURL,
	}

	service, err := NewPivotal(pc, pv.log)
	if err != nil {
		t.Fatal(err)
	}

	return service
}

func createPivotalWebhookSettings(webhook_id, project_id *string) map[string]*string {
	return map[string]*string{
		"webhook_id": webhook_id,
		"project_id": project_id,
	}
}

func createPivotalWebhookRequestData(settings, oldSettings map[string]*string) map[string]interface{} {
	return map[string]interface{}{
		"userToken":    "640e289a912484cdaf79ab55e2534181e0d40ba1",
		"serviceToken": "e4e18128-d0db-487c-6e33-825e6fe6e824",
		"settings":     settings,
		"oldSettings":  oldSettings,
	}
}

func doConfigurePivotalRequest(t *testing.T, service *Pivotal, data map[string]interface{}) (helpers.ConfigureResponse, error) {
	body, err := json.Marshal(data)
	if err != nil {
		t.Errorf("Expected nil, got %s", err)
	}

	reader := bytes.NewReader(body)
	req, _ := http.NewRequest("POST", "/configure/pivotal", reader)

	return service.Configure(req)
}

var (
	webhookURL                   = "https://koding.com/api/webhook/push/pivotal/e4e18128-d0db-487c-6e33-825e6fe6e824"
	createPivotalWebhookResponse = fmt.Sprintf(`{
   "created_at": "2015-07-21T12:00:00Z",
   "id": 1234567,
   "kind": "webhook",
   "project_id": 123456,
   "updated_at": "2015-07-21T12:00:00Z",
   "webhook_url": "%s",
   "webhook_version": "v5"
}`, webhookURL)

	updatedWebhookURL            = "https://koding.com/api/webhook/push/pivotal/e4e18128-d0db-487c-6e33-825e6fe6e825"
	updatePivotalWebhookResponse = fmt.Sprintf(`{
   "created_at": "2015-07-21T12:00:00Z",
   "id": 1234567,
   "kind": "webhook",
   "project_id": 1234568,
   "updated_at": "2015-07-21T12:00:00Z",
   "webhook_url": "%s",
   "webhook_version": "v5"
}`, updatedWebhookURL)
)
