package eventexporter

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
)

type DruidExporter struct {
	Address string
}

type MetricEvents struct {
	EventName string   `json:"eventName"`
	Tags      []string `json:"tags"`
}

func NewDruidExporter(address string) *DruidExporter {
	return &DruidExporter{
		Address: address,
	}
}

func (d *DruidExporter) Send(m *Event) error {
	eventName, tags := eventSeperator(m)

	events := &MetricEvents{
		EventName: eventName,
		Tags:      tags,
	}

	b, err := json.Marshal(events)
	if err != nil {
		return err
	}

	return d.post(b)
}

func (d *DruidExporter) Close() error {
	return nil
}

func (d *DruidExporter) post(req []byte) error {
	if d.Address == "" {
		return ErrDruidAddressNotSet
	}

	resp, err := http.Post(d.Address, "application/json", bytes.NewBuffer(req))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	result, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	if resp.StatusCode != http.StatusOK {
		return errors.New(fmt.Sprintf("%s: %s", resp.Status, string(result)))
	}

	return nil
}
