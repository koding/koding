package neo4j

import (
	"reflect"
	"strconv"
	"testing"
)

func TestDefaultConnection(t *testing.T) {
	neo4jConnection := Connect("")

	if neo4jConnection.Client == nil {
		t.Error("Connection client is not set")
	}

	if neo4jConnection.BaseURL == "" {
		t.Error("BaseUrl is not set")
	}

	if neo4jConnection.NodeURL == "" {
		t.Error("NodeUrl is not set")
	}

	if neo4jConnection.RelationshipURL == "" {
		t.Error("RelationshipUrl is not set")
	}

	if neo4jConnection.IndexNodeURL == "" {
		t.Error("IndexNodeUrl is not set")
	}
}

func TestGetNodeWithEmptyID(t *testing.T) {
	neo4jConnection := Connect("")

	node := &Node{}
	node.ID = ""
	err := neo4jConnection.Get(node)
	if err == nil {
		t.Error("Error is nil")
	}
}

func TestGetNodeWithInvalidID(t *testing.T) {
	neo4jConnection := Connect("")

	node := &Node{}
	node.ID = "asdfasdfas"
	err := neo4jConnection.Get(node)
	if err == nil {
		t.Error("Error is nil")
	}
}

func TestGetNodeReturnsErrorObjectOnError(t *testing.T) {
	neo4jConnection := Connect("")

	node := &Node{}
	node.ID = "asdfasdfas"
	err := neo4jConnection.Get(node)
	if err == nil {
		t.Error("There must be error")
	}

	tt := reflect.TypeOf(err).String()
	// find a better way to check this
	if tt != "*errors.errorString" {
		t.Error("Error is not valid!")
	}
}

func TestGetNodeWithIntMaxID(t *testing.T) {
	maxInt := strconv.Itoa(int(^uint(0) >> 1))
	neo4jConnection := Connect("")

	node := &Node{}
	node.ID = maxInt
	if err := neo4jConnection.Get(node); err == nil {
		t.Error("There must be error")
	}
}

func checkForSetValues(t *testing.T, node *Node, err error) {
	if err != nil {
		t.Error("Error is not nil on valid test")
	}

	if node == nil {
		t.Error("Node is nil on valid test")
	}

	if node.Payload == nil {
		return
	}
	if node.Payload.PagedTraverse == "" {
		t.Error("PagedTraverse on valid node is nil")
	}
	if node.Payload.OutgoingRelationships == "" {
		t.Error("OutgoingRelationships on valid node is nil")
	}

	if node.Payload.Traverse == "" {
		t.Error("Traverse on valid node is nil")
	}

	if node.Payload.AllTypedRelationships == "" {
		t.Error("AllTypedRelationships on valid node is nil")
	}

	if node.Payload.Property == "" {
		t.Error("Property on valid node is nil")
	}

	if node.Payload.AllRelationships == "" {
		t.Error("AllRelationships on valid node is nil")
	}

	if node.Payload.Self == "" {
		t.Error("Self on valid node is nil")
	}

	if node.Payload.Properties == "" {
		t.Error("Properties on valid node is nil")
	}

	if node.Payload.OutgoingTypedRelationships == "" {
		t.Error("OutgoingTypedRelationships on valid node is nil")
	}

	if node.Payload.IncomingRelationships == "" {
		t.Error("IncomingRelationships on valid node is nil")
	}

	if node.Payload.IncomingTypedRelationships == "" {
		t.Error("IncomingTypedRelationships on valid node is nil")
	}

	if node.Payload.CreateRelationship == "" {
		t.Error("CreateRelationship on valid node is nil")
	}
}

func checkForNil(t *testing.T, node *Node) {

	if node.ID != "" {
		t.Error("ID is set")
	}

	if node.Data != nil {
		t.Error("node data is not nil")
	}

	if node.Payload.PagedTraverse != "" {
		t.Error("PagedTraverse on valid node is not nil")
	}
	if node.Payload.OutgoingRelationships != "" {
		t.Error("OutgoingRelationships on valid node is not nil")
	}

	if node.Payload.Traverse != "" {
		t.Error("Traverse on valid node is not nil")
	}

	if node.Payload.AllTypedRelationships != "" {
		t.Error("AllTypedRelationships on valid node is not nil")
	}

	if node.Payload.Property != "" {
		t.Error("Property on valid node is not nil")
	}

	if node.Payload.AllRelationships != "" {
		t.Error("AllRelationships on valid node is not nil")
	}

	if node.Payload.Self != "" {
		t.Error("Self on valid node is not nil")
	}

	if node.Payload.Properties != "" {
		t.Error("Properties on valid node is not nil")
	}

	if node.Payload.OutgoingTypedRelationships != "" {
		t.Error("OutgoingTypedRelationships on valid node is not nil")
	}

	if node.Payload.IncomingRelationships != "" {
		t.Error("IncomingRelationships on valid node is not nil")
	}

	if node.Payload.IncomingTypedRelationships != "" {
		t.Error("IncomingTypedRelationships on valid node is not nil")
	}

	if node.Payload.CreateRelationship != "" {
		t.Error("CreateRelationship on valid node is not nil")
	}
}

func TestCreateNodeWithPassingInvalidObject(t *testing.T) {
	t.Log("complete this method")
}

func TestCreateNodeWithPassingValidObjectAndData(t *testing.T) {

	node := &Node{}
	data := make(map[string]interface{})
	data["stringData"] = "firstData"
	data["integerData"] = 3
	data["floatData"] = 3.0
	node.Data = data

	neo4jConnection := Connect("")

	err := neo4jConnection.Create(node)

	testCreatedNodeDeafultvalues(t, node, err)
	t.Log("test integer values, all numbers are in float64 format")

	if node.Data["stringData"] != "firstData" {
		t.Error("string value has changed")
	}

	checkForSetValues(t, node, err)

}

func TestCreateNodeWithPassingValidObjectAndEmptyData(t *testing.T) {

	node := &Node{}
	neo4jConnection := Connect("")

	err := neo4jConnection.Create(node)
	if err != nil {
		t.Error(err)
	}

	testCreatedNodeDeafultvalues(t, node, err)

	if len(node.Data) != 0 {
		t.Error("node data len must be 0")
	}

	checkForSetValues(t, node, err)
}

func testCreatedNodeDeafultvalues(t *testing.T, node *Node, err error) {

	if err != nil {
		t.Error("node creation returned err")
	}

	if node.ID == "" {
		t.Error("Assigning node id doesnt work")
	}
}

func TestUpdateNodeWithEmptyID(t *testing.T) {

	node := &Node{}
	neo4jConnection := Connect("")
	err := neo4jConnection.Update(node)
	if err == nil {
		t.Error("Error is nil")
	}
}

func TestBatchApiWithNode(t *testing.T) {
	neo4jConnection := Connect("")
	node := &Node{}
	data := make(map[string]interface{})
	data["CreateNodeWithBatch"] = "dataa"
	node.Data = data

	err := neo4jConnection.Create(node)
	if err != nil {
		t.Error("Error is not nil", err)
	}

	if node.ID == "" {
		t.Error("Node id is nil")
	}

	if node.Data["CreateNodeWithBatch"] != "dataa" {
		t.Error("Node data is nil")
	}

	node.Data = nil

	err = neo4jConnection.Get(node)
	if err != nil {
		t.Error("Error is not nil")
	}

	if node.Data["CreateNodeWithBatch"] != "dataa" {
		t.Error("Node data is nil")
	}

	node.Data["UpdateNodeWithBatch"] = "tadaa"

	err = neo4jConnection.Update(node)
	if err != nil {
		t.Error("Update returned error", err)
	}

	if len(node.Data) != 2 {
		t.Error("Data length must be 2")
	}

	if node.Data["UpdateNodeWithBatch"] != "tadaa" {
		t.Error("Update didnt updated data properly ")
	}

	if err := neo4jConnection.Delete(node); err != nil {
		t.Error("Error while deleting node", err)
	}

	if err := neo4jConnection.Get(node); err == nil {
		t.Error("Getting deleted node succeeded")
	}

}

func TestBatchApiWithRelationship(t *testing.T) {

	neo4jConnection := Connect("")

	node := &Node{}
	node.Data = map[string]interface{}{
		"hede": "debe",
	}

	if err := neo4jConnection.Create(node); err != nil {
		t.Error("Error while creating node", err)
	}

	node2 := node
	if err := neo4jConnection.Create(node2); err != nil {
		t.Error("Error while creating node", err)
	}

	//create relationship
	relationship := &Relationship{}
	dataRel := make(map[string]interface{})
	dataRel["dada"] = "gaga"
	relationship.Data = dataRel
	relationship.Type = "sampleType"
	relationship.StartNodeID = node.ID
	relationship.EndNodeID = node2.ID

	if err := neo4jConnection.Create(relationship); err != nil {
		t.Error("Error while creating relationship", err)
	}

	if relationship.ID == "" {
		t.Error("Relationship is not created or id is not assigned")
	}

	// update relationship
	relationship.Data["updatingRelationship"] = "update data"

	if err := neo4jConnection.Update(relationship); err != nil {
		t.Error("Error while creating relationship", err)
	}

	if relationship.Data["updatingRelationship"] != "update data" {
		t.Error("Update is not completed successfully")
	}

	if relationship.ID == "" {
		t.Error("ID is missing after update")
	}

	// delete relationship
	if err := neo4jConnection.Delete(relationship); err != nil {
		t.Error("Error while deleting relationship", err)
	}

	if err := neo4jConnection.Get(relationship); err == nil {
		t.Error("Deleted relationship returned result", err)
	}
}
