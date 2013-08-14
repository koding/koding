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

func (r *Relationship) mapBatchResponse(neo4j *Neo4j, data interface{}) (bool, error) {
	// because data is a map, convert back to Json
	encodedData, err := jsonEncode(data)
	result, err := r.decode(neo4j, encodedData)

	return result, err
}

func (r *Relationship) getBatchQuery(operation string) (map[string]interface{}, error) {

	query := make(map[string]interface{})

	switch operation {
	case BATCH_GET:
		query, err := prepareRelationshipGetBatchMap(r)
		return query, err
	case BATCH_UPDATE:
		query, err := prepareRelationshipUpdateBatchMap(r)
		return query, err
	case BATCH_CREATE:
		query, err := prepareRelationshipCreateBatchMap(r)
		return query, err
	case BATCH_DELETE:
		query, err := prepareRelationshipDeleteBatchMap(r)
		return query, err
	case BATCH_CREATE_UNIQUE:
		query, err := prepareRelationshipCreateUniqueBatchMap(r)
		return query, err
	}
	return query, nil
}

func prepareRelationshipGetBatchMap(r *Relationship) (map[string]interface{}, error) {
	query := make(map[string]interface{})

	if r.Id == "" {
		return query, errors.New("Id not valid")
	}

	query["method"] = "GET"
	query["to"] = fmt.Sprintf("/relationship/%s", r.Id)

	return query, nil
}

func prepareRelationshipDeleteBatchMap(r *Relationship) (map[string]interface{}, error) {
	query := make(map[string]interface{})

	if r.Id == "" {
		return query, errors.New("Id not valid")
	}

	query["method"] = "DELETE"
	query["to"] = fmt.Sprintf("/relationship/%s", r.Id)

	return query, nil
}

func prepareRelationshipCreateBatchMap(r *Relationship) (map[string]interface{}, error) {

	query := make(map[string]interface{})

	if r.StartNodeId == "" {
		return query, errors.New("Start Node Id not valid")
	}

	if r.EndNodeId == "" {
		return query, errors.New("End Node Id not valid")
	}

	if r.Type == "" {
		return query, errors.New("Relationship type is not valid")
	}

	url := fmt.Sprintf("/node/%s/relationships", r.StartNodeId)
	endNodeUrl := fmt.Sprintf("/node/%s", r.EndNodeId)

	return map[string]interface{}{
		"method": "POST",
		"to":     url,
		"body": map[string]interface{}{
			"to":   endNodeUrl,
			"type": r.Type,
			"data": r.Data,
		},
	}, nil
}

func prepareRelationshipCreateUniqueBatchMap(r *Relationship) (map[string]interface{}, error) {
	query := make(map[string]interface{})

	if r.StartNodeId == "" {
		return query, errors.New("Start Node Id not valid")
	}

	if r.EndNodeId == "" {
		return query, errors.New("End Node Id not valid")
	}

	if r.Type == "" {
		return query, errors.New("Relationship type is not valid")
	}

	startUrl := fmt.Sprintf("/node/%s", r.StartNodeId)
	endNodeUrl := fmt.Sprintf("/node/%s", r.EndNodeId)

	return map[string]interface{}{
		"method": "POST",
		"to":     "/index/relationships",
		"body": map[string]interface{}{
			"start":      startUrl,
			"end":        endNodeUrl,
			"type":       r.Type,
			"properties": r.Data,
		},
	}, nil
}

func prepareRelationshipUpdateBatchMap(r *Relationship) (map[string]interface{}, error) {
	query := make(map[string]interface{})

	if r.Id == "" {
		return query, errors.New("Id not valid")
	}

	query = map[string]interface{}{
		"method": "PUT",
		"to":     fmt.Sprintf("/relationship/%s/properties", r.Id),
		"body":   r.Data,
	}

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

func getRelationships(neo4j *Neo4j, node *Node, direction string) ([]Relationship, error) {
	if node.Id == "" {
		return nil, errors.New("Id is not given")
	}

	customReq := &ManuelBatchRequest{}
	customReq.To = fmt.Sprintf("/node/%s/relationships/%s", node.Id, direction)
	neo4j.NewBatch().Get(customReq).Execute()
	result := []Relationship{}
	err := neo4j.GetManualBatchResponse(customReq, &result)
	if err != nil {
		return nil, err
	}
	return result, nil
}

func (r *Relationship) encodeData() (string, error) {
	result, err := jsonEncode(r.Data)
	return result, err
}

func (r *Relationship) decode(neo4j *Neo4j, data string) (bool, error) {
	payload := &RelationshipResponse{}

	// Map json to our RelationshipResponse struct
	err := json.Unmarshal([]byte(data), payload)
	if err != nil {
		return false, err
	}

	// Map returning result to our relationship struct
	err = mapRelationship(neo4j, r, payload)
	if err != nil {
		return false, err
	}

	return true, nil
}

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
