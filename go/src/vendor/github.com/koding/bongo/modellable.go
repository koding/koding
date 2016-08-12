package bongo

type Modellable interface {
	// Id int64
	GetId() int64
	BongoName() string
}

type Partial map[string]interface{}
