package webhook

import (
	"socialapi/models"
	"time"

	"github.com/koding/bongo"
)

const TeamIntegrationBongoName = "integration.team_integration"

func (i TeamIntegration) GetId() int64 {
	return i.Id
}

func (i TeamIntegration) BongoName() string {
	return TeamIntegrationBongoName
}

func (i *TeamIntegration) BeforeCreate() {
	i.CreatedAt = time.Now().UTC()
	i.UpdatedAt = time.Now().UTC()
	i.DeletedAt = models.ZeroDate()
}

func (i *TeamIntegration) BeforeUpdate() {
	i.DeletedAt = models.ZeroDate()
	i.UpdatedAt = time.Now().UTC()
}

func (i *TeamIntegration) ById(id int64) error {
	return bongo.B.ById(i, id)
}

func (i *TeamIntegration) One(q *bongo.Query) error {
	return bongo.B.One(i, i, q)
}

func (i *TeamIntegration) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(i, data, q)
}
