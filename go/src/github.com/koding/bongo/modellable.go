package bongo

type Modellable interface {
	// Id int64
	GetId() int64
	TableName() string
	Self() Modellable
}

type Partial map[string]interface{}
