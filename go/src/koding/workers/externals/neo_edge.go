package main

import (
	"fmt"
	neo "github.com/siesta/neo4j"
	"log"
	"time"
)

var (
	NEO_CONN_URL string
	NEO_CONN     *neo.Neo4j
)

// Represents two nodes & the relationship between the two in Mongo.
// Relationships always point from start to end.
type RelationData struct {
	StartId   string
	StartName string
	EndId     string
	EndName   string
	Name      string
	Timestamp time.Time
}

// Represents two nodes & the relationship between the two in Neo
// Relationships always point from start to end.
type NeoEdge struct {
	StartNode, EndNode *neo.Node
	Relationship       *neo.Relationship

	// Embedded info from external source.
	RelationData
}

func NewNeoEdge(relationData RelationData) *NeoEdge {
	return &NeoEdge{
		RelationData: relationData,
	}
}

func (r *NeoEdge) CreateNodes() error {
	batch := getNeoConnection().NewBatch()
	_, err := batch.
		CreateUnique(r.StartNode, uniqueHelper(r.getStartUniqueId())).
		CreateUnique(r.EndNode, uniqueHelper(r.getEndUniqueId())).
		Execute()

	return err
}

func (r *NeoEdge) CreateStartNode() (*neo.Node, error) {
	err := createNode(r.StartNode, r.getStartUniqueId())
	return r.StartNode, err
}

func (r *NeoEdge) CreateEndNode() (*neo.Node, error) {
	err := createNode(r.EndNode, r.getEndUniqueId())
	return r.EndNode, err
}

func uniqueHelper(id string) *neo.Unique {
	return &neo.Unique{
		IndexName: "koding",
		Key:       "id",
		Value:     id,
	}
}

func createNode(node *neo.Node, id string) error {
	batch := getNeoConnection().NewBatch()
	_, err := batch.CreateUnique(node, uniqueHelper(id)).Execute()

	return err
}

// Creates a relationship between start & end node.
func (r *NeoEdge) CreateRelationship() error {
	rltnshp := &neo.Relationship{
		StartNodeId: r.getStartId(),
		EndNodeId:   r.getEndId(),
		Type:        r.getRelationshipName(),
		Data:        strToInf{r.StartName: r.getStartId()},
	}

	err := getNeoConnection().Create(rltnshp)
	r.Relationship = rltnshp

	return err
}

func (r *NeoEdge) GetStartNodeFromIndex(indexName, id string) (*neo.Node, error) {
	manuelReq := &neo.ManuelBatchRequest{
		To:   fmt.Sprintf("/index/node/%s/id/%s", indexName, id),
		Body: strToInf{},
	}

	_, err := getNeoConnection().NewBatch().
		Get(manuelReq).
		Execute()

	var startNodes []neo.Node
	getNeoConnection().GetManualBatchResponse(manuelReq, &startNodes)

	if len(startNodes) == 0 {
		return nil, err
	}

	node := startNodes[0]
	r.StartNode = &node

	return &node, err
}

// Creates a linked list relationship between start & end node.
//
// Does the following:
//    * Gets the current `prev` relationship for start node.
//
//    These then happen in a single batch query:
//      * Deletes that relationship,
//      * Creates `prev` relationship between current end & old end nodes,
//      * Creates `prev` relationship between start & end nodes.
//
// If no `prev` relationship exists, it just does last item in list above.
func (r *NeoEdge) CreateLRelationship() error {
	prevRltnshps, err := r.GetLHeadRelationship()
	if err != nil {
		return err
	}

	data := strToInf{"source_id": r.getStartId()}

	startToEndToLRltnshp := &neo.Relationship{
		StartNodeId: r.getStartId(),
		EndNodeId:   r.getEndId(),
		Type:        r.getLRelationshipName(),
		Data:        data,
	}

	batch := getNeoConnection().NewBatch().
		Create(startToEndToLRltnshp)

	// if prev relationships exist for start node
	if len(prevRltnshps) > 0 {
		startToOldEndRltnshp := prevRltnshps[0]

		endToOldEndRltnsp := &neo.Relationship{
			StartNodeId: r.getEndId(),
			EndNodeId:   startToOldEndRltnshp.EndNodeId,
			Type:        r.getLRelationshipName(),
			Data:        data,
		}

		batch.Delete(&startToOldEndRltnshp).
			Create(endToOldEndRltnsp)
	}

	// sanity check
	if len(prevRltnshps) > 1 {
		log.Println("Too many prev relationships for node: ", r.getStartId())
	}

	_, err = batch.Execute()

	return err
}

// Gets the current linked list relationship after the start node.
func (r *NeoEdge) GetLHeadRelationship() ([]neo.Relationship, error) {
	rltnshps, err := getNeoConnection().GetAllTypedRelationships(r.StartNode, r.getLRelationshipName())

	return rltnshps, err
}

func getNeoConnection() *neo.Neo4j {
	NEO_CONN = neo.Connect(NEO_CONN_URL)

	return NEO_CONN
}

// Gets the current linked list head after the start node.
func (r *NeoEdge) getLHeadNode() {}

// Getters //

func (r *NeoEdge) getStartUniqueId() string {
	return r.RelationData.StartId
}

func (r *NeoEdge) getEndUniqueId() string {
	return r.RelationData.EndId
}

func (r *NeoEdge) getStartId() string {
	return r.StartNode.Id
}

func (r *NeoEdge) getEndId() string {
	return r.EndNode.Id
}

func (r *NeoEdge) getRelationshipName() string {
	return r.RelationData.Name
}

func (r *NeoEdge) getLRelationshipName() string {
	return "prev_" + r.getRelationshipName()
}

// Getters //
