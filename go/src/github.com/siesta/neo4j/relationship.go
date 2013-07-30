package neo4j

import (
	"encoding/json"
	"errors"
	"fmt"
)

type Relationship struct {
	Id          string
	StartNodeId string
	EndNodeId   string
	Type        string
	Data        map[string]interface{}
	Payload     *RelationshipResponse
}

type RelationshipResponse struct {
	Start      string                 `json:"start"`
	Property   string                 `json:"property"`
	Self       string                 `json:"self"`
	Properties string                 `json:"properties"`
	Type       string                 `json:"type"`
	End        string                 `json:"end"`
	Data       map[string]interface{} `json:"data"`
}

func (neo4j *Neo4j) GetRelationshipTypes() ([]string, error) {

	url := fmt.Sprintf("%s/types", neo4j.RelationshipUrl)
	result := make([]string, 0)
	response, err := neo4j.doRequest("GET", url, "")
	if err != nil {
		return result, err
	}

	err = json.Unmarshal([]byte(response), &result)
	if err != nil {
		return result, err
	}

	return result, err
}

func (relationship *Relationship) mapBatchResponse(neo4j *Neo4j, data interface{}) (bool, error) {
	// because data is a map, convert back to Json
	encodedData, err := jsonEncode(data)
	result, err := relationship.decode(neo4j, encodedData)

	return result, err
}

func (relationship *Relationship) getBatchQuery(operation string) (map[string]interface{}, error) {

	query := make(map[string]interface{})

	switch operation {
	case BATCH_GET:
		query, err := prepareRelationshipGetBatchMap(relationship)
		return query, err
	case BATCH_UPDATE:
		query, err := prepareRelationshipUpdateBatchMap(relationship)
		return query, err
	case BATCH_CREATE:
		query, err := prepareRelationshipCreateBatchMap(relationship)
		return query, err
	case BATCH_DELETE:
		query, err := prepareRelationshipDeleteBatchMap(relationship)
		return query, err
	case BATCH_CREATE_UNIQUE:
		query, err := prepareRelationshipCreateUniqueBatchMap(relationship)
		return query, err
	}
	return query, nil
}

func prepareRelationshipGetBatchMap(relationship *Relationship) (map[string]interface{}, error) {

	query := make(map[string]interface{})

	if relationship.Id == "" {
		return query, errors.New("Id not valid")
	}

	query["method"] = "GET"
	query["to"] = "/relationship/" + relationship.Id

	return query, nil
}

func prepareRelationshipDeleteBatchMap(relationship *Relationship) (map[string]interface{}, error) {

	query := make(map[string]interface{})

	if relationship.Id == "" {
		return query, errors.New("Id not valid")
	}

	query["method"] = "DELETE"
	query["to"] = "/relationship/" + relationship.Id

	return query, nil
}

func prepareRelationshipCreateBatchMap(relationship *Relationship) (map[string]interface{}, error) {

	query := make(map[string]interface{})

	if relationship.StartNodeId == "" {
		return query, errors.New("Start Node Id not valid")
	}

	if relationship.EndNodeId == "" {
		return query, errors.New("End Node Id not valid")
	}

	if relationship.Type == "" {
		return query, errors.New("Relationship type is not valid")
	}

	url := "/node/" + relationship.StartNodeId + "/relationships"

	endNodeUrl := "/node/" + relationship.EndNodeId

	query["method"] = "POST"
	query["to"] = url

	body := make(map[string]interface{})
	body["to"] = endNodeUrl
	body["type"] = relationship.Type
	body["data"] = relationship.Data
	query["body"] = body
	return query, nil
}

func prepareRelationshipCreateUniqueBatchMap(relationship *Relationship) (map[string]interface{}, error) {

	query := make(map[string]interface{})

	if relationship.StartNodeId == "" {
		return query, errors.New("Start Node Id not valid")
	}

	if relationship.EndNodeId == "" {
		return query, errors.New("End Node Id not valid")
	}

	if relationship.Type == "" {
		return query, errors.New("Relationship type is not valid")
	}

	startUrl := "/node/" + relationship.StartNodeId

	endNodeUrl := "/node/" + relationship.EndNodeId

	query["method"] = "POST"
	query["to"] = "/index/relationship"
	query["body"] = map[string]interface{}{
		"start":      startUrl,
		"end":        endNodeUrl,
		"type":       relationship.Type,
		"properties": relationship.Data,
	}

	return query, nil
}

func prepareRelationshipUpdateBatchMap(relationship *Relationship) (map[string]interface{}, error) {

	query := make(map[string]interface{})

	if relationship.Id == "" {
		return query, errors.New("Id not valid")
	}

	query["method"] = "PUT"
	query["to"] = "/node/" + relationship.Id + "/properties"
	query["body"] = relationship.Data
	return query, nil
}

func (neo4j *Neo4j) GetOutgoingRelationships(node *Node) ([]Relationship, error) {
	res, err := getRelationships(neo4j, node, "out")
	return res, err
}

func (neo4j *Neo4j) GetAllRelationships(node *Node) ([]Relationship, error) {
	res, err := getRelationships(neo4j, node, "all")
	return res, err
}

func (neo4j *Neo4j) GetIncomingRelationships(node *Node) ([]Relationship, error) {
	res, err := getRelationships(neo4j, node, "in")
	return res, err
}

func (neo4j *Neo4j) GetOutgoingTypedRelationships(node *Node, relType string) ([]Relationship, error) {
	res, err := getRelationships(neo4j, node, fmt.Sprintf("out/%s", relType))
	return res, err
}

func (neo4j *Neo4j) GetAllTypedRelationships(node *Node, relType string) ([]Relationship, error) {
	res, err := getRelationships(neo4j, node, fmt.Sprintf("all/%s", relType))
	return res, err
}

func (neo4j *Neo4j) GetIncomingTypedRelationships(node *Node, relType string) ([]Relationship, error) {
	res, err := getRelationships(neo4j, node, fmt.Sprintf("in/%s", relType))
	return res, err
}

func getRelationships(neo4j *Neo4j, node *Node, rel string) ([]Relationship, error) {

	if node.Id == "" {
		return nil, errors.New("Id is not given")
	}

	customReq := &ManuelBatchRequest{}
	customReq.To = fmt.Sprintf("/node/%s/relationships/%s", node.Id, rel)
	neo4j.NewBatch().Get(customReq).Execute()
	result := []Relationship{}
	err := neo4j.GetManualBatchResponse(customReq, &result)
	if err != nil {
		return nil, err
	}
	return result, nil
}

func (relationship *Relationship) encodeData() (string, error) {
	result, err := jsonEncode(relationship.Data)
	return result, err
}

func (relationship *Relationship) decode(neo4j *Neo4j, data string) (bool, error) {

	payload := &RelationshipResponse{}

	// Map json to our RelationshipResponse struct
	err := json.Unmarshal([]byte(data), payload)
	if err != nil {
		return false, err
	}

	// Map returning result to our relationship struct
	err = mapRelationship(neo4j, relationship, payload)
	if err != nil {
		return false, err
	}

	return true, nil
}

// func (relationship *[]Relationship) decodeArray(neo4j *Neo4j, data string) (bool, error) {

// 	payload := []RelationshipResponse{}

// 	err := jsonDecode(data, &payload)
// 	// err := json.Unmarshal([]byte(data), payload)
// 	if err != nil {
// 		return false, err
// 	}

// 	for k, v := range payload {
// 		err := mapRelationship(neo4j, relationship, &payload)
// 		if err != nil {
// 			return false, err
// 		}
// 	}

// 	return true, nil
// }

func mapRelationship(neo4j *Neo4j, relationship *Relationship, payload *RelationshipResponse) error {

	relationshipId, err := getIdFromUrl(neo4j.RelationshipUrl, payload.Self)
	if err != nil {
		return err
	}

	startNodeId, err := getIdFromUrl(neo4j.NodeUrl, payload.Start)
	if err != nil {
		return err
	}

	endNodeId, err := getIdFromUrl(neo4j.NodeUrl, payload.End)
	if err != nil {
		return err
	}

	relationship.Id = relationshipId
	relationship.StartNodeId = startNodeId
	relationship.EndNodeId = endNodeId
	relationship.Type = payload.Type
	relationship.Data = payload.Data
	relationship.Payload = payload

	return nil

}
