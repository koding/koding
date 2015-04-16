package webhook

import (
	"socialapi/models"
	"time"

	"github.com/koding/bongo"
)

const ChannelIntegrationBongoName = "integration.channel_integration"

func (i ChannelIntegration) GetId() int64 {
	return i.Id
}

func (i ChannelIntegration) BongoName() string {
	return ChannelIntegrationBongoName
}

func (i *ChannelIntegration) BeforeCreate() {
	i.CreatedAt = time.Now().UTC()
	i.UpdatedAt = time.Now().UTC()
	i.DeletedAt = models.ZeroDate()
}

func (i *ChannelIntegration) BeforeUpdate() {
	i.DeletedAt = models.ZeroDate()
	i.UpdatedAt = time.Now().UTC()
}

func (i *ChannelIntegration) ById(id int64) error {
	return bongo.B.ById(i, id)
}

func (i *ChannelIntegration) One(q *bongo.Query) error {
	return bongo.B.One(i, i, q)
}

func (i *ChannelIntegration) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(i, data, q)
}
