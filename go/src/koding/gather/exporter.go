package main

import (
	"time"

	elastigo "github.com/mattbaird/elastigo/lib"
)

type Exporter interface {
	Send(string, map[string]interface{}) error
}

type EsExporter struct {
	Client *elastigo.Conn
	Index  string
}

func NewEsExporter(domain, port string) *EsExporter {
	es := &EsExporter{Index: "gather_metrics"}

	client := elastigo.NewConn()
	client.Domain = domain
	client.Port = port
	client.Protocol = "https"

	es.Client = client

	return es
}

func (es *EsExporter) Send(docType string, data map[string]interface{}) error {
	data["@timestamp"] = time.Now().Format(time.RFC3339)

	_, err := es.Client.Index(es.Index, docType, "", nil, data)
	return err
}
