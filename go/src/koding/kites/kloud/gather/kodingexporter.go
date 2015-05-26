package gather

import (
	"bytes"
	"fmt"
	"net/http"
)

var defaultKodingURI = "https://koding.com/gatherinjestor"

type KodingExporter struct {
	URI string
}

func NewKodingExporter() *KodingExporter {
	return &KodingExporter{URI: defaultKodingURI}
}

func (k *KodingExporter) SendResult(results []interface{}, o Options) error {
	buf := bytes.NewBuffer(nil)

	_, err := http.Post(k.URI+"/stats", "application/json", buf)
	return err
}

func (k *KodingExporter) SendError(err error, o Options) error {
	if err == nil {
		return ErrErrorIsEmpty
	}

	req := []byte(fmt.Sprintf(`{"error":%s"}`))
	buf := bytes.NewBuffer(req)

	_, err = http.Post(k.URI+"/errors", "application/json", buf)
	return err
}
