package neo4j

import (
	"encoding/json"
	"errors"
	"fmt"
)

// Node struct
type Node struct {
	ID      string
	Data    map[string]interface{}
	Payload *NodeResponse
}

// NodeResponse struct for mapping nodes returned for Neo4J server
type NodeResponse struct {
	PagedTraverse              string                 `json:"paged_traverse"`
	OutgoingRelationships      string                 `json:"outgoing_relationships"`
	Traverse                   string                 `json:"traverse"`
	AllTypedRelationships      string                 `json:"all_typed_relationships"`
	Property                   string                 `json:"property"`
	AllRelationships           string                 `json:"all_relationships"`
	Self                       string                 `json:"self"`
	Properties                 string                 `json:"properties"`
	OutgoingTypedRelationships string                 `json:"outgoing_typed_relationships"`
	IncomingRelationships      string                 `json:"incoming_relationships"`
	IncomingTypedRelationships string                 `json:"incoming_typed_relationships"`
	CreateRelationship         string                 `json:"create_relationship"`
	Data                       map[string]interface{} `json:"data"`
}

func (node *Node) mapBatchResponse(neo4j *Neo4j, data interface{}) (bool, error) {
	encodedData, err := jsonEncode(data)
	payload, err := node.decodeResponse(encodedData)
	if err != nil {
		return false, err
	}
	id, err := getIDFromURL(neo4j.NodeURL, payload.Self)
	if err != nil {
		return false, nil
	}
	node.ID = id
	node.Data = payload.Data
	node.Payload = payload

	return true, nil
}

func (node *Node) getBatchQuery(operation string) (map[string]interface{}, error) {
	switch operation {
	case BatchGet:
		query, err := prepareNodeGetBatchMap(node)
		return query, err
	case BatchUpdate:
		query, err := prepareNodeUpdateBatchMap(node)
		return query, err
	case BatchCreate:
		query, err := prepareNodeCreateBatchMap(node)
		return query, err
	case BatchDelete:
		query, err := prepareNodeDeleteBatchMap(node)
		return query, err
	case BatchCreateUnique:
		query, err := prepareNodeCreateUniqueBatchMap(node)
		return query, err
	}
	return map[string]interface{}{}, nil

}

func prepareNodeGetBatchMap(n *Node) (map[string]interface{}, error) {
	query := make(map[string]interface{})

	if n.ID == "" {
		return query, errors.New("Id field is empty")
	}

	query["method"] = "GET"
	query["to"] = fmt.Sprintf("/node/%s", n.ID)

	return query, nil
}

func prepareNodeDeleteBatchMap(n *Node) (map[string]interface{}, error) {
	query := make(map[string]interface{})

	if n.ID == "" {
		return query, errors.New("Id not valid")
	}

	query["method"] = "DELETE"
	query["to"] = fmt.Sprintf("/node/%s", n.ID)

	return query, nil
}

func prepareNodeCreateBatchMap(n *Node) (map[string]interface{}, error) {
	return map[string]interface{}{
		"method": "POST",
		"to":     "/node",
		"body":   n.Data,
	}, nil
}

func prepareNodeUpdateBatchMap(n *Node) (map[string]interface{}, error) {
	query := make(map[string]interface{})

	if n.ID == "" {
		return query, errors.New("Id not valid")
	}

	query["method"] = "PUT"
	query["to"] = fmt.Sprintf("/node/%s/properties", n.ID)
	query["body"] = n.Data

	return query, nil
}

func prepareNodeCreateUniqueBatchMap(n *Node) (map[string]interface{}, error) {
	return map[string]interface{}{
		"method": "POST",
		"to":     "/index/node",
		"body": map[string]interface{}{
			"properties": n.Data,
		},
	}, nil
}

func (node *Node) encodeData() (string, error) {
	result, err := jsonEncode(node.Data)
	return result, err
}

func (node *Node) decodeResponse(data string) (*NodeResponse, error) {
	nodeResponse := &NodeResponse{}

	err := json.Unmarshal([]byte(data), nodeResponse)
	if err != nil {
		return nil, err
	}

	return nodeResponse, nil
}
