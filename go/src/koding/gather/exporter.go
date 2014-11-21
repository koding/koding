package main

import elastigo "github.com/mattbaird/elastigo/lib"

type Exporter interface {
	Create(string, []byte) error
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

func (es *EsExporter) Create(docType string, data []byte) error {
	_, err := es.Client.Index(es.Index, docType, "", nil, data)
	return err
}
