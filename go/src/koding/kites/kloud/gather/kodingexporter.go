package gather

import (
	"bytes"
	"encoding/json"
	"koding/db/models"
	"net/http"
)

var defaultKodingURI = "https://koding.com/-/gatherinjestor"

type KodingExporter struct {
	URI string
}

func NewKodingExporter() *KodingExporter {
	return &KodingExporter{URI: defaultKodingURI}
}

func (k *KodingExporter) SendResult(output *models.GatherStat) error {
	return k.send("/stats", output)
}

func (k *KodingExporter) SendError(output *models.GatherError) error {
	return k.send("/errors", output)
}

func (k *KodingExporter) send(path string, output interface{}) error {
	buf := bytes.NewBuffer(nil)

	err := json.NewEncoder(buf).Encode(output)
	if err != nil {
		return err
	}

	_, err = http.Post(k.URI+path, "application/json", buf)
	return err
}
