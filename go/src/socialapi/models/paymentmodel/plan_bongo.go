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

var ErrDuplicatePlan = errors.New(
	`pq: duplicate key value violates unique constraint "payment_plan_name"`,
)

func (p *Plan) Create() error {
	err := bongo.B.Create(p)
	if err != nil && err.Error() != ErrDuplicatePlan.Error() {
		return err
	}

	return nil
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
