package services

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"

	"github.com/koding/integration/helpers"
	"github.com/koding/logging"
)

const (
	PIVOTAL          = "pivotal"
	PivotalServerURL = "https://www.pivotaltracker.com/services/v5"
)

var (
	ErrProjectIdNotValid   = errors.New("project_id is not valid")
	ErrUserTokenIsNotValid = errors.New("userToken is not set")
	ErrInvalidRequest      = errors.New("invalid request")
)

type PivotalConfig struct {
	ServerURL      string
	PublicURL      string
	IntegrationURL string
}

func NewPivotal(pc *PivotalConfig, log logging.Logger) (*Pivotal, error) {
	if pc.ServerURL == "" {
		pc.ServerURL = PivotalServerURL
	}

	return &Pivotal{
		serverURL:      pc.ServerURL,
		publicURL:      pc.PublicURL,
		integrationURL: pc.IntegrationURL,
		log:            log.New(PIVOTAL),
	}, nil
}

func (p *Pivotal) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	token := req.URL.Query().Get("token")
	if token == "" {
		w.WriteHeader(http.StatusBadRequest)
		p.log.Error("Token is not found %v", ErrUserTokenIsNotValid)
		return
	}

	pm, err := readBody(req.Body)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	resources := ""
	comma := ""
	for _, pr := range pm.PrimaryResources {
		resources += fmt.Sprintf("%s[%s](%s)", comma, pr.Name, pr.URL)
		comma = ","
	}

	message := fmt.Sprintf("[%s] %s: %s", pm.Project.Name, pm.Message, resources)

	pr := helpers.NewPushRequest(message)

	if err := helpers.Push(token, pr, p.integrationURL); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		p.log.Error("Could not push message: %s", err)
		return
	}

}

func (p *Pivotal) Configure(req *http.Request) (helpers.ConfigureResponse, error) {
	cr := new(helpers.ConfigureRequest)
	if err := helpers.MapConfigureRequest(req, cr); err != nil {
		return nil, err
	}

	projectID := cr.Settings.GetString("project_id")
	if projectID == "" {
		return nil, ErrProjectIdNotValid
	}

	userToken := cr.UserToken
	if userToken == "" {
		return nil, ErrUserTokenIsNotValid
	}

	cp := &ConfigurePivotal{
		// prepare our endpoint
		WebhookURL:     prepareEndpoint(p.publicURL, PIVOTAL, cr.ServiceToken),
		WebhookVersion: "v5",
		WebhookID:      cr.Settings.GetString("webhook_id"),
	}

	createReq, err := p.sendRequest(cp, projectID, userToken)
	if err != nil {
		return nil, err
	}

	return createReq, nil

}

func (p *Pivotal) sendRequest(cp *ConfigurePivotal, projectID, userToken string) (helpers.ConfigureResponse, error) {
	js, err := json.Marshal(cp)
	if err != nil {
		return nil, err
	}

	body := bytes.NewReader(js)

	// this url request to pivotal api to create a webhook for the project
	url := fmt.Sprintf("%s/projects/%s/webhooks", p.serverURL, projectID)
	method := "POST"

	// if WebhookID is set, that means this is an update request
	if cp.WebhookID != "" {
		method = "PUT"
		url = fmt.Sprintf("%s/%v", url, cp.WebhookID)
	}

	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return nil, err
	}

	// This content-type is required for request
	// Otherwise pivotal responds with invalid request error
	req.Header.Add("Content-Type", "application/json")
	// Set user's oauth token
	req.Header.Add("X-TrackerToken", userToken)
	c := &http.Client{}
	resp, err := c.Do(req)
	defer func() {
		if resp.Body != nil {
			resp.Body.Close()
		}
	}()
	if err != nil {
		return nil, err
	}

	result := make(map[string]interface{})
	// var result interface{}

	// Decode response even if we get error from pivotal
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	if resp.StatusCode >= 300 {
		return nil, fmt.Errorf("configure failed with code: %d, response: %#v", resp.StatusCode, result)
	}

	response := helpers.ConfigureResponse{}
	response["webhook_id"] = strconv.FormatInt(int64(result["id"].(float64)), 10)
	response["project_id"] = result["project_id"]

	return response, nil
}

func readBody(body io.ReadCloser) (*PivotalActivity, error) {
	pm := &PivotalActivity{}
	defer func() {
		if body != nil {
			body.Close()
		}
	}()

	if err := json.NewDecoder(body).Decode(pm); err != nil {
		return nil, err
	}

	return pm, nil
}
