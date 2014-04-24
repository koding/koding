package account

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
)

func ListChannels(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	query := helpers.GetQuery(u)

	accountId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if query.Type == "" {
		query.Type = models.Channel_TYPE_TOPIC
	}

	a := &models.Account{Id: accountId}
	channels, err := a.FetchChannels(query)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewOKResponse(models.PopulateChannelContainers(channels, accountId))
}

func ListProfileFeed(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	// query := helpers.GetQuery(u)

	// accountId, err := helpers.GetURIInt64(u, "id")
	// if err != nil {
	// 	return helpers.NewBadRequestResponse(err)
	// }

	// /// Get Group Channel
	// selector := map[string]interface{}{
	// 	"group_name":    query.GroupName,
	// 	"type_constant": models.Channel_TYPE_GROUP,
	// }

	// c := models.NewChannel()
	// if err := c.One(bongo.NewQS(selector)); err != nil {
	// 	return helpers.NewBadRequestResponse(err)
	// }

	// var results []models.ChannelMessage
	// cm := models.NewChannelMessage()
	// bongo.B.DB.Table(cm.TableName()).
	// 	Select("api.channel_message.*").
	// 	Joins("left join api.channel_message_list on api.channel_message.id = api.channel_message_list.message_id").
	// 	Scan(&results)
	// /// Fetch Messages that are created by account
	// var cml ChannelMessageList = models.NewChannelMessageList()
	// cmlQuery := &bongo.Query{
	// 	Selector: map[string]interface{}{
	// 		"channel_id": c.Id,
	// 	},
	// 	Sort: map[string]interface{}{
	// 		"added_at": "DESC",
	// 	},
	// 	Limit: query.Limit,
	// 	Skip:  query.Skip,
	// 	Pluck: "message_id",
	// }

	// var messageIds []int64
	// if err := cml.Some(&messageIds, cmlQuery); err != nil {
	// 	return helpers.NewBadRequestResponse(err)
	// }

	// /// Fetch messages
	// cm := models.NewChannelMessage()
	// messages, err := cm.FetchByIds(messageIds)
	// if err != nil {
	// 	return helpers.NewBadRequestResponse(err)
	// }

	return helpers.NewOKResponse(nil)
}

func Follow(u *url.URL, h http.Header, req *models.Account) (int, http.Header, interface{}, error) {
	targetId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	cp, err := req.Follow(targetId)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewOKResponse(cp)
}

func Register(u *url.URL, h http.Header, req *models.Account) (int, http.Header, interface{}, error) {

	if err := req.FetchOrCreate(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewOKResponse(req)
}

func Unfollow(u *url.URL, h http.Header, req *models.Account) (int, http.Header, interface{}, error) {
	targetId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if err := req.Unfollow(targetId); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	// req shouldnt be returned?
	return helpers.NewOKResponse(req)
}
