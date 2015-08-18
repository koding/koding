package gatherrun

import (
	"bytes"
	"encoding/json"
	"net/http"
)

// defaultKodingURI is the value to send gather data.
const defaultKodingURI = "https://koding.com/-/ingestor"

// Exporter defines the interface for sending gather data from
// user VMs to external server.
type Exporter interface {
	SendStats(*GatherStat) error
	SendError(*GatherError) error
}

//----------------------------------------------------------
// KodingExporter
//----------------------------------------------------------

// KodingExporter sends gather data from user VMs to Koding servers.
type KodingExporter struct {
	URI string
}

func NewKodingExporter() *KodingExporter {
	return &KodingExporter{URI: defaultKodingURI}
}

func (k *KodingExporter) SendStats(stats *GatherStat) error {
	return k.send("/ingest", stats)
}

func (k *KodingExporter) SendError(errors *GatherError) error {
	return k.send("/errors", errors)
}

func (k *KodingExporter) send(path string, output interface{}) error {
	buf := new(bytes.Buffer)

	err := json.NewEncoder(buf).Encode(output)
	if err != nil {
		return err
	}

	_, err = http.Post(k.URI+path, "application/json", buf)
	return err
}
