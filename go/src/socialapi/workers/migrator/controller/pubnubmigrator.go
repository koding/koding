package controller

import (
	"socialapi/models"
	realtimemodels "socialapi/workers/realtime/models"

	"github.com/koding/bongo"
)

func (mwc *Controller) GrantPublicAccess() {
	mwc.GrantChannelAccess()
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
			},
		)

	rows, err := query.Rows()
	if err != nil {
		panic(err)
	}
	defer rows.Close()

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
