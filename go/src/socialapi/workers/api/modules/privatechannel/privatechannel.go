package privatechannel

import (
	"errors"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

func Init(u *url.URL, h http.Header, req *models.ChannelRequest, ctx *models.Context) (int, http.Header, interface{}, error) {
	// check if user logged in or not
	if !ctx.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	req.AccountId = ctx.Client.Account.Id
	req.GroupName = ctx.GroupName

	return response.HandleResultAndError(req.Create())
}

func Send(u *url.URL, h http.Header, req *models.ChannelRequest, ctx *models.Context) (int, http.Header, interface{}, error) {
	// check if user logged in or not
	if !ctx.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	req.AccountId = ctx.Client.Account.Id
	req.GroupName = ctx.GroupName

	return response.HandleResultAndError(req.Send())
}

func List(u *url.URL, h http.Header, _ interface{}, ctx *models.Context) (int, http.Header, interface{}, error) {
	// check if user logged in or not
	if !ctx.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}
	query := request.GetQuery(u)
	q := ctx.OverrideQuery(query)
	channelList, err := getPrivateChannels(q)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(buildContainer(channelList, q))
}

func Search(u *url.URL, h http.Header, _ interface{}, ctx *models.Context) (int, http.Header, interface{}, error) {
	// check if user logged in or not
	if !ctx.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	query := request.GetQuery(u)
	q := ctx.OverrideQuery(query)

	if q.Name == "" {
		return response.NewBadRequest(errors.New("search string not set"))
	}

	channelList, err := getPrivateChannels(q)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(buildContainer(channelList, q))
}

func Count(u *url.URL, h http.Header, _ interface{}, ctx *models.Context) (int, http.Header, interface{}, error) {
	// check if user logged in or not
	if !ctx.IsLoggedIn() {
		return response.NewBadRequest(models.ErrNotLoggedIn)
	}

	q := request.GetQuery(u)
	qry := ctx.OverrideQuery(q)

	query := getUserChannelsQuery(qry)

	// add exempt clause if needed
	if !q.ShowExempt {
		query = query.Where("api.channel.meta_bits = ?", models.Safe)
	}

	var count int
	query = query.Count(&count)
	if query.Error != nil {
		return response.NewBadRequest(query.Error)
	}

	res := new(models.CountResponse)
	res.TotalCount = count

	return response.NewOK(res)
}

func buildContainer(channelList []models.Channel, q *request.Query) (*models.ChannelContainers, error) {
	cc := models.NewChannelContainers()
	if err := cc.Fetch(channelList, q); err != nil {
		return cc, err
	}

	cc.AddIsParticipant(q.AccountId)

	// TODO this should be in the channel cache by default
	cc.AddLastMessage(q.AccountId)
	cc.AddUnreadCount(q.AccountId)

	return cc, cc.Err()
}

func getUserChannelsQuery(q *request.Query) *gorm.DB {
	c := models.NewChannel()

	if q.Type == "" {
		q.Type = models.Channel_TYPE_PRIVATE_MESSAGE
	}

	return bongo.B.DB.
		Model(c).
		Table(c.BongoName()).
		Select("api.channel_participant.channel_id").
		Joins("left join api.channel_participant on api.channel_participant.channel_id = api.channel.id").
		Where("api.channel_participant.account_id = ? and "+
			"api.channel.group_name = ? and "+
			"api.channel.type_constant = ? and "+
			"api.channel_participant.status_constant = ?",
			q.AccountId,
			q.GroupName,
			q.Type,
			models.ChannelParticipant_STATUS_ACTIVE)
}

func getPrivateChannels(q *request.Query) ([]models.Channel, error) {
	// build query for
	if q.AccountId == 0 || q.GroupName == "" {
		return nil, errors.New("request is not valid")
	}

	c := models.NewChannel()
	channelIds := make([]int64, 0)

	query := getUserChannelsQuery(q)

	if q.Name != "" {
		// use 'ilike' for case-insensitive search
		query = query.Where("api.channel.purpose ilike ?", "%"+q.Name+"%")
	}

	// add exempt clause if needed
	if !q.ShowExempt {
		query = query.Where("api.channel.meta_bits = ?", models.Safe)
	}

	query = query.Limit(q.Limit).
		Offset(q.Skip).
		Order("api.channel.updated_at DESC")

	rows, err := query.Rows()
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	for rows.Next() {
		var channelId int64
		err := rows.Scan(&channelId)
		if err == nil {
			channelIds = append(channelIds, channelId)
		}
	}

	channels, err := c.FetchByIds(channelIds)
	if err != nil {
		return nil, err
	}

	return channels, nil
}
