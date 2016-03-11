package dynamodb

import (
	"encoding/json"
	"errors"
	"github.com/crowdmob/goamz/dynamodb/dynamizer"
)

type DynamoQuery struct {
	TableName      string               `json:",omitempty"`
	ConsistentRead string               `json:",omitempty"`
	Item           dynamizer.DynamoItem `json:",omitempty"`
	Key            dynamizer.DynamoItem `json:",omitempty"`
	table          *Table
}

type DynamoResponse struct {
	Item dynamizer.DynamoItem `json:",omitempty"`
}

func NewDynamoQuery(t *Table) *DynamoQuery {
	q := &DynamoQuery{table: t}
	q.TableName = t.Name
	return q
}

func (q *DynamoQuery) AddKey(key *Key) error {
	// Add in the hash/range keys.
	keys, err := q.buildKeyMap(key)
	if err != nil {
		return err
	}
	q.Key = keys
	return nil
}

func (q *DynamoQuery) dynamoAttributeFromAttribute(a *Attribute, value string) (*dynamizer.DynamoAttribute, error) {
	da := &dynamizer.DynamoAttribute{}
	switch a.Type {
	case "S":
		da.S = new(string)
		*da.S = value
	case "N":
		da.N = value
	default:
		return nil, errors.New("Only string and numeric attributes are supported")
	}
	return da, nil
}

func (q *DynamoQuery) buildKeyMap(key *Key) (dynamizer.DynamoItem, error) {
	if key.HashKey == "" {
		return nil, errors.New("HaskKey is always required")
	}

	k := q.table.Key
	keyMap := make(dynamizer.DynamoItem)
	hashKey, herr := q.dynamoAttributeFromAttribute(k.KeyAttribute, key.HashKey)
	if herr != nil {
		return nil, herr
	}
	keyMap[k.KeyAttribute.Name] = hashKey
	if k.HasRange() {
		if key.RangeKey == "" {
			return nil, errors.New("RangeKey is required by the table")
		}
		rangeKey, rerr := q.dynamoAttributeFromAttribute(k.RangeAttribute, key.RangeKey)
		if rerr != nil {
			return nil, rerr
		}
		keyMap[k.RangeAttribute.Name] = rangeKey
	}
	return keyMap, nil
}

func (q *DynamoQuery) AddItem(key *Key, item dynamizer.DynamoItem) error {
	// Add in the hash/range keys.
	keys, err := q.buildKeyMap(key)
	if err != nil {
		return err
	}
	for k, v := range keys {
		item[k] = v
	}

	q.Item = item

	return nil
}

func (q *DynamoQuery) AddExclusiveStartKey(key *Key) error {
	panic("not implemented")
	return nil
}

func (q *DynamoQuery) AddExclusiveStartTableName(table string) error {
	panic("not implemented")
	return nil
}

func (q *DynamoQuery) SetConsistentRead(consistent bool) error {
	if consistent {
		q.ConsistentRead = "true" // string, not boolean
	} else {
		q.ConsistentRead = "" // omit for false
	}
	return nil
}

func (q *DynamoQuery) String() string {
	bytes, err := json.Marshal(q)
	if err != nil {
		panic(err) // TODO: need to change the interface to support returning error
	}
	return string(bytes)
}
