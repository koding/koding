package messagelist

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"

	"github.com/koding/bongo"
)

func List(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	query := request.GetQuery(u)
	query = context.OverrideQuery(query)

	c, err := models.Cache.Channel.ById(channelId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !query.ShowExempt {
		query.ShowExempt = context.Client.Account.IsTroll
	}

	// if channel is exempt and user should see the
	// content, return not found err
	if c.MetaBits.Is(models.Troll) && !query.ShowExempt {
		return response.NewNotFound()
	}

	canOpen, err := c.CanOpen(query.AccountId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !canOpen {
		return response.NewAccessDenied(
			fmt.Errorf(
				"account (%d) tried to retrieve the unattended private channel (%d)",
				query.AccountId,
				c.Id,
			))
	}

	cml := models.NewChannelMessageList()
	cml.ChannelId = c.Id

	return response.HandleResultAndError(
		cml.List(query, false),
	)
}

func Count(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}
	if channelId == 0 {
		return response.NewBadRequest(errors.New("channel id is not set"))
	}

	count, err := models.NewChannelMessageList().Count(channelId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	res := new(models.CountResponse)
	res.TotalCount = count

	return response.NewOK(res)
}

// this is a TEMP function just for @usirin
func TempList(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	query := request.GetQuery(u)
	query = context.OverrideQuery(query)

	c, err := models.Cache.Channel.ById(channelId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// if channel is exempt and user should see the
	// content, return not found err
	if !query.ShowExempt {
		query.ShowExempt = context.Client.Account.IsTroll
	}

	if c.MetaBits.Is(models.Troll) && !query.ShowExempt {
		return response.NewNotFound()
	}

	// check if channel is accessible by the requester
	canOpen, err := c.CanOpen(query.AccountId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !canOpen {
		return response.NewAccessDenied(
			fmt.Errorf(
				"account (%d) tried to retrieve the unattended private channel (%d)",
				query.AccountId,
				c.Id,
			))
	}

	bq := &bongo.Query{
		Selector: map[string]interface{}{
			"initial_channel_id": c.Id,
		},
		Pagination: *bongo.NewPagination(query.Limit, query.Skip),
		Pluck:      "id",
	}

	bq.AddScope(models.SortedByCreatedAt)
	bq.AddScope(models.RemoveTrollContent(c, query.ShowExempt))
	bq.AddScope(models.ExcludeFields(query.Exclude))
	bq.AddScope(models.TillTo(query.From))

	bqq := bongo.B.BuildQuery(models.NewChannelMessage(), bq)
	var messages []int64
	if err := bongo.CheckErr(
		bqq.Pluck(bq.Pluck, &messages),
	); err != nil {
		return response.NewBadRequest(err)
	}

	// get the messages in regarding channel
	cmcs, err := models.
		NewChannelMessageList().
		PopulateChannelMessages(
			messages, query,
		)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// reduce replies
	replyIds := make([]int64, 0)
	for i := range cmcs {
		cmc := cmcs[i]
		if cmc.Message.TypeConstant == models.ChannelMessage_TYPE_REPLY {
			replyIds = append(replyIds, cmc.Message.Id)
		}
	}

	if len(replyIds) == 0 {
		return response.NewOK(cmcs)
	}

	// select replies
	var mrs []models.MessageReply
	gerr := bongo.B.
		BuildQuery(models.NewMessageReply(), &bongo.Query{}).
		Where("reply_id in (?)", replyIds).
		Find(&mrs)

	if err := bongo.CheckErr(gerr); err != nil {
		return response.NewBadRequest(err)
	}

	// set their parent ids
	for j, mr := range mrs {
		for i := range cmcs {
			if mr.ReplyId == cmcs[i].Message.Id {
				cmcs[i].ParentID = mrs[j].MessageId
			}
		}
	}

	// send response
	return response.NewOK(cmcs)
}
