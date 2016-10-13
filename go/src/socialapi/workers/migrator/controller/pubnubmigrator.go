package controller

import (
	"socialapi/models"
	realtimemodels "socialapi/workers/realtime/models"

	"github.com/koding/bongo"
)

func (mwc *Controller) GrantPublicAccess() {
	mwc.GrantChannelAccess()
	mwc.GrantMessageAccess()
}

func (mwc *Controller) GrantChannelAccess() {
	mwc.log.Notice("Granting public access for channels")
	c := models.NewChannel()
	query := bongo.B.DB.
		Model(c).
		Table(c.BongoName()).
		Select("api.channel.token").
		Where(
			`api.channel.type_constant IN (?)`,
			[]string{
				models.Channel_TYPE_GROUP,
				models.Channel_TYPE_TOPIC,
				models.Channel_TYPE_ANNOUNCEMENT,
			},
		)

	rows, err := query.Rows()
	defer rows.Close()
	if err != nil {
		panic(err)
	}

	if rows == nil {
		return
	}

	var token string
	for rows.Next() {
		rows.Scan(&token)
		channel := realtimemodels.Channel{
			Token: token,
		}

		err := mwc.pubnub.GrantPublicAccess(realtimemodels.NewPrivateMessageChannel(channel))
		if err != nil {
			mwc.log.Error("Could not grant public access to token %s: %s", token, err)
		}
	}
}

func (mwc *Controller) GrantMessageAccess() {
	mwc.log.Notice("Granting public access for messages")

	c := models.NewChannelMessage()
	query := bongo.B.DB.
		Model(c).
		Table(c.BongoName()).
		Select("api.channel_message.token")

	rows, err := query.Rows()
	defer rows.Close()
	if err != nil {
		panic(err)
	}

	if rows == nil {
		return
	}

	var token string
	for rows.Next() {
		rows.Scan(&token)
		channel := realtimemodels.UpdateInstanceMessage{
			Token: token,
		}

		err := mwc.pubnub.GrantPublicAccess(realtimemodels.NewMessageUpdateChannel(channel))
		if err != nil {
			mwc.log.Error("Could not grant public access to token %s: %s", token, err)
		}
	}
}
