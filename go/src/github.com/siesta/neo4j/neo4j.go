package neo4j

import (
	"net/http"
)

type Neo4j struct {
	Client          *http.Client
	BaseUrl         string
	NodeUrl         string
	BatchUrl        string
	RelationshipUrl string
	IndexNodeUrl    string
}

func Connect(url string) *Neo4j {
	if url == "" {
		url = "http://127.0.0.1:7474"
	}

	baseUrl := url + "/db/data"
	return &Neo4j{
		Client:          http.DefaultClient,
		BaseUrl:         baseUrl,
		NodeUrl:         baseUrl + "/node",
		BatchUrl:        baseUrl + "/batch",
		IndexNodeUrl:    baseUrl + "/index/node",
		RelationshipUrl: baseUrl + "/relationship",
	}
}

func (neo4j *Neo4j) Get(obj Batcher) error {

	_, err := neo4j.NewBatch().Get(obj).Execute()

	return err
}

func (neo4j *Neo4j) Create(obj Batcher) error {

	_, err := neo4j.NewBatch().Create(obj).Execute()

	return err
}

func (neo4j *Neo4j) Delete(obj Batcher) error {

	_, err := neo4j.NewBatch().Delete(obj).Execute()

	return err
}

func (neo4j *Neo4j) Update(obj Batcher) error {

	_, err := neo4j.NewBatch().Update(obj).Execute()

	return err
}
