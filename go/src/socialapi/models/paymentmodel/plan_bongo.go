package paymentmodel

import (
	"errors"

	"github.com/jinzhu/gorm"
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

var ErrTitleNotSet = errors.New("title not set")
var ErrIntervalNotSet = errors.New("interval not set")

func (p *Plan) ByTitleAndInterval() (bool, error) {
	if p.Title == "" {
		return false, ErrTitleNotSet
	}

	if p.Interval == "" {
		return false, ErrIntervalNotSet
	}

	selector := map[string]interface{}{
		"title":    p.Title,
		"interval": p.Interval,
	}

	err := p.One(bongo.NewQS(selector))
	if err == bongo.RecordNotFound {
		return false, nil
	}

	if err == gorm.RecordNotFound {
		return false, nil
	}

	if err != nil {
		return false, err
	}

	return true, nil
}
