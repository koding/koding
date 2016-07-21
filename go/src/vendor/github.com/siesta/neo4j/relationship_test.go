package neo4j

import (
	"testing"
)

func TestGetAllRelationships(t *testing.T) {
	neo4jConnection := Connect("")

	data := make(map[string]interface{})
	data["hede"] = "debe"

	node := &Node{}
	node.Data = data
	node2 := &Node{}
	node2.Data = data

	//create batch request for node
	batch := neo4jConnection.NewBatch()
	batch.Create(node)
	batch.Create(node2)
	batch.Execute()

	batch = neo4jConnection.NewBatch()
	relationship := crateRelationship(neo4jConnection, node, node2)
	batch.Create(relationship)
	//type2
	relationship2 := crateRelationship(neo4jConnection, node, node2)
	relationship2.Type = "sampleType2"
	batch.Create(relationship2)
	//type3
	relationship3 := crateRelationship(neo4jConnection, node, node2)
	relationship3.Type = "sampleType3"
	batch.Create(relationship3)
	//rel2
	relationship4 := crateRelationship(neo4jConnection, node2, node)
	relationship4.Type = "sampleType3"
	batch.Create(relationship4)
	//rel
	relationship5 := crateRelationship(neo4jConnection, node2, node)
	relationship5.Type = "sampleType4"
	batch.Create(relationship5)
	_, err := batch.Execute()
	if err != nil {
		t.Error(err)
	}

	res, err := neo4jConnection.GetAllRelationships(node)
	if err != nil {
		t.Error(err)
	}

	if len(res) != 5 {
		t.Error(len(res), "error node all rel response", err)
	}

	res, err = neo4jConnection.GetAllRelationships(node2)
	if err != nil {
		t.Error(err)
	}

	if len(res) != 5 {
		t.Error(len(res), "error node2 all rel response", err)
	}

	res, err = neo4jConnection.GetIncomingRelationships(node)
	if err != nil {
		t.Error(err)
	}

	if len(res) != 2 {
		t.Error(len(res), "error on response", err)
	}

	res, err = neo4jConnection.GetIncomingRelationships(node2)
	if err != nil {
		t.Error(err)
	}

	if len(res) != 3 {
		t.Error(len(res), "error on response", err)
	}

	res, err = neo4jConnection.GetOutgoingRelationships(node)
	if err != nil {
		t.Error(err)
	}

	if len(res) != 3 {
		t.Error(len(res), "error on response", err)
	}

	res, err = neo4jConnection.GetOutgoingRelationships(node2)
	if err != nil {
		t.Error(err)
	}

	if len(res) != 2 {
		t.Error(len(res), "error on response", err)
	}

	res, err = neo4jConnection.GetAllTypedRelationships(node, "sampleType3")
	if err != nil {
		t.Error(err)
	}

	if len(res) != 2 {
		t.Error(len(res), "error on response", err)
	}

	res, err = neo4jConnection.GetAllTypedRelationships(node2, "sampleType4")
	if err != nil {
		t.Error(err)
	}

	if len(res) != 1 {
		t.Error(len(res), "error on response", err)
	}

	res, err = neo4jConnection.GetIncomingTypedRelationships(node, "sampleType3")
	if err != nil {
		t.Error(err)
	}

	if len(res) != 1 {
		t.Error(len(res), "error on response", err)
	}

	res, err = neo4jConnection.GetIncomingTypedRelationships(node2, "sampleType4")
	if err != nil {
		t.Error(err)
	}
	//there is no incoming relaetionship
	if len(res) != 0 {
		t.Error(len(res), "error on response", err)
	}

	res, err = neo4jConnection.GetOutgoingTypedRelationships(node, "sampleType3")
	if err != nil {
		t.Error(err)
	}

	if len(res) != 1 {
		t.Error(len(res), "error on response", err)
	}

	res, err = neo4jConnection.GetOutgoingTypedRelationships(node2, "sampleType4")
	if err != nil {
		t.Error(err)
	}
	//there is no incoming relaetionship
	if len(res) != 1 {
		t.Error(len(res), "error on response", err)
	}

}

func crateRelationship(neo4j *Neo4j, node *Node, node2 *Node) *Relationship {

	//create relationship
	relationship := &Relationship{}
	dataRel := make(map[string]interface{})
	dataRel["dada"] = "gaga"
	relationship.Data = dataRel
	relationship.Type = "sampleType"
	relationship.StartNodeID = node.ID
	relationship.EndNodeID = node2.ID

	return relationship

}
