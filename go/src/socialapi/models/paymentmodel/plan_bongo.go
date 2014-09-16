package paymentmodel

import (
	"errors"

	"github.com/koding/bongo"
)

func (p Plan) GetId() int64 {
	return p.Id
}

func (Plan) TableName() string {
	return "api.payment_plan"
}

//----------------------------------------------------------
// Crud methods
//----------------------------------------------------------

func (p *Plan) One(q *bongo.Query) error {
	return bongo.B.One(p, p, q)
}

func (p *Plan) Create() error {
	return bongo.B.Create(p)
}

var NameNotSet = errors.New("name not set")

func (p *Plan) ByName() (bool, error) {
	if p.Name == "" {
		return false, NameNotSet
	}

	selector := map[string]interface{}{"name": p.Name}

	err := p.One(bongo.NewQS(selector))
	if err == bongo.RecordNotFound {
		return false, nil
	}

	return true, nil
}
