package bongo

type Modellable interface {
	// Id int64
	GetId() int64
	TableName() string
}

type Partial map[string]interface{}
