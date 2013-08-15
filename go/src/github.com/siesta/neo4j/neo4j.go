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

// Connect creates the basic structure to send requests to neo4j rest endpoint.
// This will enable communication with only one server
//
// It is using  Golang HTTP Package inside, so it will re-use the persistent
// TCP connection to given server.
//
// This method is generally called only once for Server
// Close method is not required and not implemented
//
// The connection string should be provided as;
//
//     [http://][host][:port]
//
// For example;
//
//     http://127.0.0.1:7474
//
// If you pass empty string it will try to connect;
//
//     http://127.0.0.1:7474
//
// TODO implement cluster connection
func Connect(url string) *Neo4j {
	if url == "" {
		url = "http://127.0.0.1:7474"
	}

	baseUrl := url + "/db/data"
	// TODO get neo4j service root from neo4j itself
	// http://docs.neo4j.org/chunked/stable/rest-api-service-root.html
	return &Neo4j{
		Client:          http.DefaultClient,
		BaseUrl:         baseUrl,
		NodeUrl:         baseUrl + "/node",
		BatchUrl:        baseUrl + "/batch",
		IndexNodeUrl:    baseUrl + "/index/node",
		RelationshipUrl: baseUrl + "/relationship",
	}
}

// This is the basic Get method for all types
// It accepts only Bacther Interface
// Node and Relationship structs implement this interface
//
// Example usages;
//
// Node:
//     neo4jConnection := Connect("")
//     node := &Node{}
//     node.Id = "2229"
//     err := neo4jConnection.Get(node)
//     fmt.Println(node)
//
// Relationship:
//    neo4jConnection := Connect("")
//    rel             := &Relationship{}
//    rel.Id          = "2229"
//    neo4jConnection.get(rel)
func (neo4j *Neo4j) Get(obj Batcher) error {
	_, err := neo4j.NewBatch().Get(obj).Execute()

	return err
}

// Relationship:
//    dataRel         := make(map[string]interface{})
//    dataRel["RelData"] = "DataOfTheRelationship"
//
//    neo4jConnection := Connect("")
//    rel             := &Relationship{}
//    rel.Data        = dataRel
//    rel.Type        = "sampleType"
//    rel.StartNodeId = node.Id
//    rel.EndNodeId   = node2.Id
//
//    neo4jConnection.get(rel)
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
