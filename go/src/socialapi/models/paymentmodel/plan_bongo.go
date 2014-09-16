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

var ErrTitleNotSet = errors.New("title not set")

func (p *Plan) ByTitle() (bool, error) {
	if p.Title == "" {
		return false, ErrTitleNotSet
	}

	selector := map[string]interface{}{"title": p.Title}

	err := p.One(bongo.NewQS(selector))
	if err == bongo.RecordNotFound {
		return false, nil
	}

	return true, nil
}
