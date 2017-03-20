package client

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
)

type Events []Event

type Event struct {
	Key          string      `json:"key"`
	Count        int         `json:"count"`
	Sum          float64     `json:"sum,omitempty"`
	Dur          int         `json:"dur,omitempty"`
	Segmentation interface{} `json:"segmentation,omitempty"`
}

func (c *Client) WriteEvent(appKey, deviceId string, events Events) error {
	values := url.Values{}
	values.Add("app_key", appKey)
	values.Add("device_id", deviceId)

	evs, err := json.Marshal(events)
	if err != nil {
		return err
	}
	values.Add("events", string(evs))

	return c.do(http.MethodGet, "/i", values, nil)
}

// BulkData holds the bulk data
type BulkDatas []BulkData

type BulkData struct {
	DeviceID string  `json:"device_id"`
	AppKey   string  `json:"app_key"`
	Events   []Event `json:"events"`
}

// WriteEventWithBulk wip Don't use
func (c *Client) WriteEventWithBulk(appKey string, bulk BulkDatas) error {
	values := url.Values{}
	values.Add("app_key", appKey)

	b := new(bytes.Buffer)
	err := json.NewEncoder(b).Encode(bulk)
	if err != nil {
		return err
	}

	u := c.createURL("/i/bulk", values)

	req, err := http.NewRequest(http.MethodPost, u.String(), nil)
	req.Header.Set("Content-Type", "application/json")
	if err != nil {
		return err
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	response, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("Errvar", err)
		return err
	}

	fmt.Println(string(response))

	return nil
}
