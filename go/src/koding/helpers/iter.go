package helpers

import "koding/db/mongodb/modelhelper"

type iterOptions struct {
	Skip              int
	Limit             int
	Filter            modelhelper.Selector
	CollectionName    string
	F                 func(result interface{})
	MaxIterationCount int
	DataType          interface{}
}

func NewIterOptions(collectionName string) *iterOptions {
	return &iterOptions{
		Skip:              0,
		Limit:             1000,
		Filter:            modelhelper.Selector{},
		CollectionName:    collectionName,
		MaxIterationCount: 50,
	}
}
