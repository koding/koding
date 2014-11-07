package paymentmodels

import (
	"errors"

	"github.com/koding/bongo"
)

func (p Plan) GetId() int64 {
	return p.Id
}

func (Plan) BongoName() string {
	return "payment.plan"
}

//----------------------------------------------------------
// Crud methods
//----------------------------------------------------------

func NewPlan() *Plan {
	return &Plan{}
}

func (p *Plan) ById(id int64) error {
	return bongo.B.ById(p, id)
}

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
