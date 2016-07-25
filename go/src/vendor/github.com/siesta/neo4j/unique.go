package neo4j

import (
	"errors"
)

// var (
// 	UniquenessGetOrCreate  = "get_or_create"
// 	UniquenessCreateOrFail = "create_or_fail"
// )

// Unique struct
type Unique struct {
	IndexName  string
	Uniqueness string
	Key        string
	Value      string
}

// UniqueRequest struct used in Batch operations
type UniqueRequest struct {
	Properties *Unique
	Data       Batcher
}

// Implement Batcher interface
func (ur *UniqueRequest) getBatchQuery(operation string) (map[string]interface{}, error) {

	if ur.Properties.IndexName == "" {
		query := make(map[string]interface{})
		return query, errors.New("Index name is empty")
	}

	query, err := ur.Data.getBatchQuery(operation)
	if err != nil {
		return query, err
	}

	// to-do add unique parameter passing
	// http://localhost:7474/db/data/index/relationship/knowledge/?uniqueness=get_or_create
	// uniqueness := ur.Properties.Uniqueness
	// if ur.Properties.Uniqueness == "" {
	// 	uniqueness = UniquenessGetOrCreate
	// }

	query["to"] = query["to"].(string) + "/" + ur.Properties.IndexName + "?unique" //=" + uniqueness
	body := query["body"].(map[string]interface{})
	body["key"] = ur.Properties.Key
	body["value"] = ur.Properties.Value
	query["body"] = body

	return query, nil
}

func (ur *UniqueRequest) mapBatchResponse(neo4j *Neo4j, data interface{}) (bool, error) {
	result, err := ur.Data.mapBatchResponse(neo4j, data)
	return result, err
}
