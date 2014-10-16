package paymentmodel

import (
	"errors"

	"github.com/koding/bongo"
)

func (p Plan) GetId() int64 {
	return p.Id
}

func (Plan) TableName() string {
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

func (p *Plan) ByProviderId(providerId, provider string) error {
	selector := map[string]interface{}{
		"provider_plan_id": providerId,
		"provider":         provider,
	}

	err := p.Find(selector)
	return err
}

var ErrTitleNotSet = errors.New("title not set")
var ErrIntervalNotSet = errors.New("interval not set")

func (p *Plan) ByTitleAndInterval() error {
	if p.Title == "" {
		return ErrTitleNotSet
	}

	if p.Interval == "" {
		return ErrIntervalNotSet
	}

	selector := map[string]interface{}{
		"title":    p.Title,
		"interval": p.Interval,
	}

	err := p.One(bongo.NewQS(selector))
	return err
}

func (p *Plan) Find(selector map[string]interface{}) error {
	err := p.One(bongo.NewQS(selector))
	return err
}
