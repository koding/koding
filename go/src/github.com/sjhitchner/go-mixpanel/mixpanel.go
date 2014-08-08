// Golang Mixpanel Client Implementation
//
// https://mixpanel.com/help/reference/http
//
//
package mixpanel

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"strings"
	"time"
)

const (
	MIXPANEL_BASE_URL    = "http://api.mixpanel.com"
	MIXPANEL_DATE_FORMAT = "2006-01-02T15:04:05"
)

type MixPanel interface {
	Track(event *Event) error
	Update(update *Update) error
}

// Create mixpanel client
func NewMixpanel(token string) *MixpanelClient {
	return NewMixpanelWithUrl(token, MIXPANEL_BASE_URL)
}

// Create mixpanel client
func NewMixpanelWithUrl(token string, url string) *MixpanelClient {
	return &MixpanelClient{token, url}
}

// Client struct
type MixpanelClient struct {
	token   string
	baseUrl string
}

func (m *MixpanelClient) Track(event *Event) error {
	event.setToken(m.token)

	if err := m.makeRequest("track", event); err != nil {
		return err
	}

	return nil
}

func (m *MixpanelClient) Update(update *Update) error {
	update.setToken(m.token)

	if err := m.makeRequest("engage", update); err != nil {
		return err
	}

	return nil
}

//TODO Handle different types of requests
// data - A Base 64 encoded JSON event object, with a name and properties
// ip - 1 or 0 If present and equal to 1, Mixpanel will use the ip address of the incoming request as a distinct_id if none is provided in the event.
// redirect - url If present, Mixpanel will serve a redirect to the given url as a response to the request. This is useful when tracking clicks in an email or text message.
// img - 1 or 0 If present and equal to 1, Mixpanel will serve a 1x1 transparent pixel image as a response to the request. This is useful for tracking page loads and email opens.
// callback - function name If present, Mixpanel will serve a response of type text/javascript, containing a call to a function with the given name. This is useful for reacting to Mixpanel track events in JavaScript.
// verbose - 1 or 0 If present and equal to 1, Mixpanel will respond with a JSON Object describing the success or failure of the tracking call. The returned object will have two keys: "status", with the value 1 on success and 0 on failure, and "error", with a string-valued error message if the request wasn't successful. verbose=1 is useful for debugging your Mixpanel implementation.
func (m *MixpanelClient) makeRequest(action string, obj interface{}) error {

	payload, err := m.encodePayload(obj)
	if err != nil {
		return err
	}

	uri := fmt.Sprintf("%s/%s/?data=%s", m.baseUrl, action, payload)

	log.Println(uri)

	client := new(http.Client)
	req, err := http.NewRequest("GET", uri, nil)
	if err != nil {
		return err
	}

	resp, err := client.Do(req)
	if err != nil {
		return err
	}

	defer resp.Body.Close()
	bytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	if strings.TrimSpace(string(bytes)) != "1" {
		return fmt.Errorf("Call to [%s] failed", uri)
	}

	return nil
}

func (m *MixpanelClient) encodePayload(obj interface{}) (string, error) {
	fmt.Println("X", obj)

	b, err := json.MarshalIndent(obj, "", "  ")
	if err != nil {
		return "", err
	}
	log.Printf("payload:\n%v\n", string(b))
	return base64.StdEncoding.EncodeToString(b), nil
}

func time2String(value time.Time) string {
	return value.UTC().Format(MIXPANEL_DATE_FORMAT)
}
