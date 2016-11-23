package main

import (
	"time"

	elastigo "github.com/mattbaird/elastigo/lib"
)

type Exporter interface {
	Send(string, map[string]interface{}) error
}

//----------------------------------------------------------
// EsExporter
//----------------------------------------------------------

const (
	ES_DOMAIN        = "fcd741dd72ad8998000.qbox.io"
	ES_PORT          = "443"
	ES_TIME_FORMAT   = time.RFC3339
	ES_TIMESTAMP_KEY = "@timestamp"
	ES_INDEX_NAME    = "gather_metrics"
	ES_PROTOCOL      = "https"
)

// EsExporter exports data to ElasticSearch.
type EsExporter struct {
	Client *elastigo.Conn
	Index  string
}

func NewEsExporter(domain, port string) *EsExporter {
	es := &EsExporter{Index: ES_INDEX_NAME}

	client := elastigo.NewConn()
	client.Domain = domain
	client.Port = port
	client.Protocol = ES_PROTOCOL

	es.Client = client

	return es
}

func (es *EsExporter) Send(docType string, data map[string]interface{}) error {
	data[ES_TIMESTAMP_KEY] = time.Now().Format(ES_TIME_FORMAT)

	_, err := es.Client.Index(es.Index, docType, "", nil, data)
	return err
}
