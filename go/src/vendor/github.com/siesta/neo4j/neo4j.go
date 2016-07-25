package neo4j

import (
	"net/http"
	"net/url"
)

// Neo4j base struct
type Neo4j struct {
	Client            *http.Client
	BaseURL           string
	NodeURL           string
	BatchURL          string
	RelationshipURL   string
	IndexNodeURL      string
	BasicAuthUser     string
	BasicAuthPassword string
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
func Connect(urlString string) *Neo4j {
	if urlString == "" {
		urlString = "http://127.0.0.1:7474"
	}

	var username string
	var password string
	var baseURL string

	u, parseErr := url.Parse(urlString)
	if parseErr != nil {
		baseURL = urlString + "/db/data"
		username = ""
		password = ""
	} else {

		if u.User != nil {
			p, ok := u.User.Password()
			if ok {
				username, password = u.User.Username(), p
			} else {
				username, password = "", ""
			}
			baseURL = u.Scheme + "://" + u.Host + "/db/data"
		} else {
			baseURL = urlString + "/db/data"
			username = ""
			password = ""
		}

	}

	// TODO get neo4j service root from neo4j itself
	// http://docs.neo4j.org/chunked/stable/rest-api-service-root.html
	return &Neo4j{
		Client:            http.DefaultClient,
		BaseURL:           baseURL,
		NodeURL:           baseURL + "/node",
		BatchURL:          baseURL + "/batch",
		IndexNodeURL:      baseURL + "/index/node",
		RelationshipURL:   baseURL + "/relationship",
		BasicAuthUser:     username,
		BasicAuthPassword: password,
	}
}

// Get This is the basic Get method for all types
// It accepts only Batcher Interface
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
//    neo4jConnection.Get(rel)
func (neo4j *Neo4j) Get(obj Batcher) error {
	_, err := neo4j.NewBatch().Get(obj).Execute()

	return err
}

// Create is the basic Create method for all types
// It accepts only Batcher Interface
// Example Usages;
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
//    neo4jConnection.Get(rel)
func (neo4j *Neo4j) Create(obj Batcher) error {
	_, err := neo4j.NewBatch().Create(obj).Execute()

	return err
}

// Delete is the basic Delete method for all types
// It accepts only Batcher Interface
func (neo4j *Neo4j) Delete(obj Batcher) error {
	_, err := neo4j.NewBatch().Delete(obj).Execute()

	return err
}

// Update is the basic Update method for all types
// It accepts only Batcher Interface
func (neo4j *Neo4j) Update(obj Batcher) error {
	_, err := neo4j.NewBatch().Update(obj).Execute()

	return err
}
