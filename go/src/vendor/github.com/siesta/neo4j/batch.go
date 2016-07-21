package neo4j

import (
	"encoding/json"
	"errors"
	"reflect"
	"strconv"
)

// Batcher is the interface for structs for making them compatible with Batch.
type Batcher interface {
	getBatchQuery(operation string) (map[string]interface{}, error)
	mapBatchResponse(neo4j *Neo4j, data interface{}) (bool, error)
}

// Basic operation names
var (
	BatchGet          = "get"
	BatchCreate       = "create"
	BatchDelete       = "delete"
	BatchUpdate       = "update"
	BatchCreateUnique = "createUnique"
)

// Batch Base struct to support request
type Batch struct {
	Neo4j *Neo4j
	Stack []*BatchRequest
}

// BatchRequest All batch request structs will be encapslated in this struct
type BatchRequest struct {
	Operation string
	Data      Batcher
}

// BatchResponse All returning results from Neo4j will be in BatchResponse format
type BatchResponse struct {
	ID       int         `json:"id"`
	Location string      `json:"location"`
	Body     interface{} `json:"body"`
	From     string      `json:"from"`
}

// ManuelBatchRequest is here to support referance passing requests in a transaction
// For more information please check : http://docs.neo4j.org/chunked/stable/rest-api-batch-ops.html
type ManuelBatchRequest struct {
	To         string
	Body       map[string]interface{}
	StringBody string
	Response   interface{}
}

// GetManualBatchResponse Implements Batcher interface
func (neo4j *Neo4j) GetManualBatchResponse(mbr *ManuelBatchRequest, result interface{}) error {

	//get type of current value
	typeOfResult := reflect.TypeOf(result).String()
	typeOfResponse := reflect.TypeOf(mbr.Response).String()
	switch typeOfResult {
	//if we have an complex type, resolve it
	case "*[]neo4j.Node":
		if typeOfResponse != "[]interface {}" {
			return errors.New("Response is not an array")
		}

		tempResult := make([]Node, len(mbr.Response.([]interface{})))
		result = result.(*[]Node)
		arrayResult := mbr.Response.([]interface{})
		for i, value := range arrayResult {
			tempResult[i].mapBatchResponse(neo4j, value)
		}
		(*result.(*[]Node)) = tempResult
	case "*neo4j.Node":
		_, err := result.(*Node).mapBatchResponse(neo4j, mbr.Response)
		if err != nil {
			return err
		}
	case "*neo4j.Relationship":
		_, err := result.(*Relationship).mapBatchResponse(neo4j, mbr.Response)
		if err != nil {
			return err
		}
	case "*[]neo4j.Relationship":
		if typeOfResponse != "[]interface {}" {
			return errors.New("Response is not an array")
		}

		tempResult := make([]Relationship, len(mbr.Response.([]interface{})))
		result = result.(*[]Relationship)
		arrayResult := mbr.Response.([]interface{})
		for i, value := range arrayResult {
			tempResult[i].mapBatchResponse(neo4j, value)
		}
		(*result.(*[]Relationship)) = tempResult
	}

	return nil

}

// Implement Batcher interface
func (mbr *ManuelBatchRequest) getBatchQuery(operation string) (map[string]interface{}, error) {

	query := make(map[string]interface{})

	query["to"] = mbr.To

	if mbr.StringBody != "" && (len(mbr.StringBody) > 0) {
		query["body"] = mbr.StringBody
	} else {
		query["body"] = mbr.Body
	}

	switch operation {
	case BatchGet:
		query["method"] = "GET"
	case BatchUpdate:
		query["method"] = "PUT"
	case BatchCreate:
		query["method"] = "POST"
	case BatchDelete:
		query["method"] = "DELETE"
	case BatchCreateUnique:
		query["method"] = "POST"
		query["body"] = map[string]interface{}{
			"properties": mbr.Body,
		}
	}

	return query, nil
}

func (mbr *ManuelBatchRequest) mapBatchResponse(neo4j *Neo4j, data interface{}) (bool, error) {
	mbr.Response = data
	return true, nil
}

// GetLastIndex Returns last index of current stack
// This method can be used to obtain the latest index for creating
// manual batch requests or injecting the order number of pre-added request(s) id
func (batch *Batch) GetLastIndex() string {

	return strconv.Itoa(len(batch.Stack) - 1)
}

// NewBatch Creates New Batch request handler
func (neo4j *Neo4j) NewBatch() *Batch {
	return &Batch{
		Neo4j: neo4j,
		Stack: make([]*BatchRequest, 0),
	}
}

// Get request to Neo4j as batch
func (batch *Batch) Get(obj Batcher) *Batch {
	batch.addToStack(BatchGet, obj)

	return batch
}

// Create request to Neo4j as batch
func (batch *Batch) Create(obj Batcher) *Batch {
	batch.addToStack(BatchCreate, obj)

	return batch
}

// Delete request to Neo4j as batch
func (batch *Batch) Delete(obj Batcher) *Batch {
	batch.addToStack(BatchDelete, obj)

	return batch
}

// Update request to Neo4j as batch
func (batch *Batch) Update(obj Batcher) *Batch {
	batch.addToStack(BatchUpdate, obj)

	return batch
}

// CreateUnique Batch unique create request to Neo4j
func (batch *Batch) CreateUnique(obj Batcher, properties *Unique) *Batch {

	//encapsulating the object
	uniqueRequest := &UniqueRequest{
		Properties: properties,
		Data:       obj,
	}

	batch.addToStack(BatchCreateUnique, uniqueRequest)

	return batch
}

// Adds requests to stack
// Used internally to pile up the batch request
func (batch *Batch) addToStack(operation string, obj Batcher) {
	batchRequest := &BatchRequest{
		Operation: operation,
		Data:      obj,
	}

	batch.Stack = append(batch.Stack, batchRequest)
}

// Execute Prepares and sends the request to Neo4j
// If the request is successful then parses the response
func (batch *Batch) Execute() ([]*BatchResponse, error) {

	// if Neo4j instance is not created return an error
	if batch.Neo4j == nil {
		return nil, errors.New("Batch request is not created by NewBatch method!")
	}
	// cache batch stack length
	stackLength := len(batch.Stack)

	//create result array
	response := make([]*BatchResponse, stackLength)

	if stackLength == 0 {
		return response, nil
	}

	// prepare request
	request, err := prepareRequest(batch.Stack)
	if err != nil {
		return nil, err
	}

	encodedRequest, err := jsonEncode(request)
	res, err := batch.Neo4j.doBatchRequest("POST", batch.Neo4j.BatchURL, encodedRequest)
	if err != nil {
		return nil, err
	}

	err = json.Unmarshal([]byte(res), &response)
	if err != nil {
		return nil, err
	}

	// do mapping here for later usage
	batch.mapResponse(response)

	// do a clean
	batch.Stack = make([]*BatchRequest, 0)

	return response, nil
}

// prepares batch request as slice of map
func prepareRequest(stack []*BatchRequest) ([]map[string]interface{}, error) {
	request := make([]map[string]interface{}, len(stack))
	for i, value := range stack {
		// interface has this method getBatchQuery()
		query, err := value.Data.getBatchQuery(value.Operation)
		if err != nil {
			return nil, err
		}
		query["id"] = i
		request[i] = query
	}

	return request, nil
}

// map incoming response, it will update request's nodes and relationships
func (batch *Batch) mapResponse(response []*BatchResponse) {

	for _, val := range response {
		// id is an Neo4j batch request feature, it returns back the id that we send
		// so we can use it here to map results into our stack
		id := val.ID
		batch.Stack[id].Data.mapBatchResponse(batch.Neo4j, val.Body)
	}
}
