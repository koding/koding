package gather

import (
	"time"

	"github.com/mattbaird/elastigo/lib"
)

const (
	ES_TIME_FORMAT   = time.RFC3339
	ES_TIMESTAMP_KEY = "@timestamp"

	ES_METRIC_INDEX = "gather"
	ES_ERROR_INDEX  = "errors"

	DEFAULT_ES_PORT = "9200"
	DEFAULT_ES_PROT = "http"
	DEFAULT_ES_TYPE = "document"
)

type EsExporter struct {
	Protocol, Host string
	Port           int
	Index, Type    string

	Client *elastigo.Conn
}

func NewEsExporter(host, index string) *EsExporter {
	esClient := elastigo.NewConn()
	esClient.Domain = host
	esClient.Port = DEFAULT_ES_PORT
	esClient.Protocol = DEFAULT_ES_PROT

	return &EsExporter{Index: index, Type: DEFAULT_ES_TYPE, Client: esClient}
}

func (es *EsExporter) SendResult(results []interface{}, o Options) error {
	var topError error

	for _, r := range results {
		strToInf, ok := r.(map[string]interface{})
		if ok {
			strToInf[ES_TIMESTAMP_KEY] = time.Now().Format(ES_TIME_FORMAT)
		}

		if _, err := es.Client.Index(es.Index, es.Type, "", nil, r); err != nil {
			topError = err
		}
	}

	return topError
}

func (es *EsExporter) SendError(err error, o Options) error {
	if err == nil {
		return ErrErrorIsEmpty
	}

	data := map[string]interface{}{
		"error":          err,
		ES_TIMESTAMP_KEY: time.Now().Format(ES_TIME_FORMAT),
	}

	_, err = es.Client.Index(ES_ERROR_INDEX, DEFAULT_ES_TYPE, "", nil, data)
	return err
}
