package webhook

import (
	"socialapi/models"
	"time"

	"github.com/koding/bongo"
)

const IntegrationBongoName = "integration.integration"

func (i Integration) GetId() int64 {
	return i.Id
}

func (i Integration) BongoName() string {
	return IntegrationBongoName
}

func (i *Integration) BeforeCreate() {
	i.CreatedAt = time.Now().UTC()
	i.UpdatedAt = time.Now().UTC()
	i.DeletedAt = models.ZeroDate()
}

func (i *Integration) BeforeUpdate() {
	i.DeletedAt = models.ZeroDate()
	i.UpdatedAt = time.Now().UTC()
}

func (i *Integration) ById(id int64) error {
	return bongo.B.ById(i, id)
}

func (i *Integration) One(q *bongo.Query) error {
	return bongo.B.One(i, i, q)
}

func (i *Integration) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(i, data, q)
}
