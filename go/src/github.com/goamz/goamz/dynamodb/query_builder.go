package dynamodb

import (
	"encoding/json"
)

type msi map[string]interface{}
type Query struct {
	buffer msi
}

func NewEmptyQuery() *Query {
	return &Query{msi{}}
}

func NewQuery(t *Table) *Query {
	q := &Query{msi{}}
	q.addTable(t)
	return q
}

// This way of specifing the key is used when doing a Get.
// If rangeKey is "", it is assumed to not want to be used
func (q *Query) AddKey(t *Table, key *Key) {
	k := t.Key
	keymap := msi{
		k.KeyAttribute.Name: msi{
			k.KeyAttribute.Type: key.HashKey},
	}
	if k.HasRange() {
		keymap[k.RangeAttribute.Name] = msi{k.RangeAttribute.Type: key.RangeKey}
	}

	q.buffer["Key"] = keymap
}

func keyAttributes(t *Table, key *Key) msi {
	k := t.Key

	out := msi{}
	out[k.KeyAttribute.Name] = msi{k.KeyAttribute.Type: key.HashKey}
	if k.HasRange() {
		out[k.RangeAttribute.Name] = msi{k.RangeAttribute.Type: key.RangeKey}
	}
	return out
}

func (q *Query) AddAttributesToGet(attributes []string) {
	if len(attributes) == 0 {
		return
	}

	q.buffer["AttributesToGet"] = attributes
}

func (q *Query) ConsistentRead(c bool) {
	if c == true {
		q.buffer["ConsistentRead"] = "true" //String "true", not bool true
	}
}

func (q *Query) AddGetRequestItems(tableKeys map[*Table][]Key) {
	requestitems := msi{}
	for table, keys := range tableKeys {
		keyslist := []msi{}
		for _, key := range keys {
			keyslist = append(keyslist, keyAttributes(table, &key))
		}
		requestitems[table.Name] = msi{"Keys": keyslist}
	}
	q.buffer["RequestItems"] = requestitems
}

func (q *Query) AddWriteRequestItems(tableItems map[*Table]map[string][][]Attribute) {
	b := q.buffer

	b["RequestItems"] = func() msi {
		out := msi{}
		for table, itemActions := range tableItems {
			out[table.Name] = func() interface{} {
				out2 := []interface{}{}
				for action, items := range itemActions {
					for _, attributes := range items {
						Item_or_Key := map[bool]string{true: "Item", false: "Key"}[action == "Put"]
						out2 = append(out2, msi{action + "Request": msi{Item_or_Key: attributeList(attributes)}})
					}
				}
				return out2
			}()
		}
		return out
	}()
}

func (q *Query) AddCreateRequestTable(description TableDescriptionT) {
	b := q.buffer

	attDefs := []interface{}{}
	for _, attr := range description.AttributeDefinitions {
		attDefs = append(attDefs, msi{
			"AttributeName": attr.Name,
			"AttributeType": attr.Type,
		})
	}
	b["AttributeDefinitions"] = attDefs
	b["KeySchema"] = description.KeySchema
	b["TableName"] = description.TableName
	b["ProvisionedThroughput"] = msi{
		"ReadCapacityUnits":  int(description.ProvisionedThroughput.ReadCapacityUnits),
		"WriteCapacityUnits": int(description.ProvisionedThroughput.WriteCapacityUnits),
	}

	localSecondaryIndexes := []interface{}{}

	for _, ind := range description.LocalSecondaryIndexes {
		localSecondaryIndexes = append(localSecondaryIndexes, msi{
			"IndexName":  ind.IndexName,
			"KeySchema":  ind.KeySchema,
			"Projection": ind.Projection,
		})
	}

	if len(localSecondaryIndexes) > 0 {
		b["LocalSecondaryIndexes"] = localSecondaryIndexes
	}
}

func (q *Query) AddDeleteRequestTable(description TableDescriptionT) {
	b := q.buffer
	b["TableName"] = description.TableName
}

func (q *Query) AddKeyConditions(comparisons []AttributeComparison) {
	q.buffer["KeyConditions"] = buildComparisons(comparisons)
}

func (q *Query) AddLimit(limit int64) {
	q.buffer["Limit"] = limit
}
func (q *Query) AddSelect(value string) {
	q.buffer["Select"] = value
}

func (q *Query) AddIndex(value string) {
	q.buffer["IndexName"] = value
}

/*
   "ScanFilter":{
       "AttributeName1":{"AttributeValueList":[{"S":"AttributeValue"}],"ComparisonOperator":"EQ"}
   },
*/
func (q *Query) AddScanFilter(comparisons []AttributeComparison) {
	q.buffer["ScanFilter"] = buildComparisons(comparisons)
}

func (q *Query) AddParallelScanConfiguration(segment int, totalSegments int) {
	q.buffer["Segment"] = segment
	q.buffer["TotalSegments"] = totalSegments
}

func buildComparisons(comparisons []AttributeComparison) msi {
	out := msi{}

	for _, c := range comparisons {
		avlist := []interface{}{}
		for _, attributeValue := range c.AttributeValueList {
			avlist = append(avlist, msi{attributeValue.Type: attributeValue.Value})
		}
		out[c.AttributeName] = msi{
			"AttributeValueList": avlist,
			"ComparisonOperator": c.ComparisonOperator,
		}
	}

	return out
}

// The primary key must be included in attributes.
func (q *Query) AddItem(attributes []Attribute) {
	q.buffer["Item"] = attributeList(attributes)
}

func (q *Query) AddUpdates(attributes []Attribute, action string) {
	updates := msi{}
	for _, a := range attributes {
		au := msi{
			"Value": msi{
				a.Type: map[bool]interface{}{true: a.SetValues, false: a.Value}[a.SetType()],
			},
			"Action": action,
		}
		// Delete 'Value' from AttributeUpdates if Type is not Set
		if action == "DELETE" && !a.SetType() {
			delete(au, "Value")
		}
		updates[a.Name] = au
	}

	q.buffer["AttributeUpdates"] = updates
}

func (q *Query) AddExpected(attributes []Attribute) {
	expected := msi{}
	for _, a := range attributes {
		value := msi{}
		if a.Exists != "" {
			value["Exists"] = a.Exists
		}
		// If set Exists to false, we must remove Value
		if value["Exists"] != "false" {
			value["Value"] = msi{a.Type: map[bool]interface{}{true: a.SetValues, false: a.Value}[a.SetType()]}
		}
		expected[a.Name] = value
	}
	q.buffer["Expected"] = expected
}

func attributeList(attributes []Attribute) msi {
	b := msi{}
	for _, a := range attributes {
		//UGH!!  (I miss the query operator)
		b[a.Name] = msi{a.Type: map[bool]interface{}{true: a.SetValues, false: a.Value}[a.SetType()]}
	}
	return b
}

func (q *Query) addTable(t *Table) {
	q.addTableByName(t.Name)
}

func (q *Query) addTableByName(tableName string) {
	q.buffer["TableName"] = tableName
}

func (q *Query) String() string {
	bytes, _ := json.Marshal(q.buffer)
	return string(bytes)
}
