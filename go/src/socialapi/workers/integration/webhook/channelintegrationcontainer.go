package webhook

import "socialapi/models"

type ChannelIntegrationContainer struct {
	ChannelIntegration *ChannelIntegration `json:"channelIntegration"`
	AccountOldId       string              `json:"accountOldId"`
	Integration        *Integration        `json:"integration,omitempty"`
	Channel            *models.Channel     `json:"channel"`
}

func NewChannelIntegrationContainer(ci *ChannelIntegration) *ChannelIntegrationContainer {
	return &ChannelIntegrationContainer{
		ChannelIntegration: ci,
	}
}

func (cic *ChannelIntegrationContainer) Populate() error {
	if cic.ChannelIntegration == nil {
		return ErrChannelIntegrationNotFound
	}

	ci := cic.ChannelIntegration
	c, err := models.Cache.Channel.ById(ci.ChannelId)
	if err != nil {
		return err
	}
	cic.Channel = c

	acc, err := models.Cache.Account.ById(ci.CreatorId)
	if err != nil {
		return err
	}
	cic.AccountOldId = acc.OldId

	return nil
}
