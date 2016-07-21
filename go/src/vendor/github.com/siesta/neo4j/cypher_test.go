package neo4j

import (
	"fmt"
	"testing"
)

func TestSendCypherQuery(t *testing.T) {
	neo4jConnection := Connect("")
	node := &Node{}
	node2 := &Node{}

	batchNode := neo4jConnection.NewBatch()
	batchNode.Create(node)
	batchNode.Create(node2)
	_, err := batchNode.Execute()
	if err != nil {
		t.Error(err)
	}

	cypher := &Cypher{
		Query: map[string]string{
			"query": fmt.Sprintf(`
        START k=node(%v, %v)
        return id(k) as eventNodeId
		  `, node.ID, node2.ID),
		},
		Payload: map[string]interface{}{},
	}

	batch := neo4jConnection.NewBatch()
	batch.Create(cypher)
	_, err = batch.Execute()
	if err != nil {
		t.Error(err)
	}

	if cypher.Payload.(map[string]interface{})["data"] == nil {
		t.Error("no data")
	}
}

func TestSendCypherQueryWithNoResults(t *testing.T) {
	neo4jConnection := Connect("")

	cypher := &Cypher{
		Query: map[string]string{
			"query": fmt.Sprintf(`
        START k=node(%v)
        return k
		  `),
		},
	}

	batch := neo4jConnection.NewBatch()
	batch.Create(cypher)
	batch.Execute()

	if cypher.Payload != nil {
		t.Error("Got cypher results")
	}
}
