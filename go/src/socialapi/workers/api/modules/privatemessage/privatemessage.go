package privatemessage

import (
	"errors"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"

	"github.com/VerbalExpressions/GoVerbalExpressions"
	"github.com/koding/bongo"
)

var mentionRegex = verbalexpressions.New().
	Find("@").
	BeginCapture().
	Word().
	EndCapture().
	Regex()

func extractParticipants(body string) []string {
	flattened := make([]string, 0)

	res := mentionRegex.FindAllStringSubmatch(body, -1)
	if len(res) == 0 {
		return flattened
	}

	participants := map[string]struct{}{}
	// remove duplicate mentions
	for _, ele := range res {
		participants[ele[1]] = struct{}{}
	}

	for participant := range participants {
		flattened = append(flattened, participant)
	}

	return flattened
}

func fetchParticipantIds(participantNames []string) ([]int64, error) {
	participantIds := make([]int64, len(participantNames))
	for i, participantName := range participantNames {
		account, err := modelhelper.GetAccount(participantName)
		if err != nil {
			return nil, err
		}
		a := models.NewAccount()
		a.Id = account.SocialApiId
		a.OldId = account.Id.Hex()
		// fetch or create social api id
		if a.Id == 0 {
			if err := a.FetchOrCreate(); err != nil {
				return nil, err
			}
		}
		participantIds[i] = a.Id
	}

	return participantIds, nil
}

func Send(u *url.URL, h http.Header, req *models.PrivateMessageRequest) (int, http.Header, interface{}, error) {
	if req.AccountId == 0 {
		return helpers.NewBadRequestResponse(errors.New("AcccountId is not defined"))
	}

	if len(req.Recipients) == 0 {
		return helpers.NewBadRequestResponse(errors.New("You should define your recipients"))
	}

	if req.GroupName == "" {
		req.GroupName = models.Channel_KODING_NAME
	}

	//// first create the channel
	c := models.NewPrivateMessageChannel(req.AccountId, req.GroupName)
	if err := c.Create(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	cm := models.NewChannelMessage()
	cm.Body = req.Body
	cm.TypeConstant = models.ChannelMessage_TYPE_PRIVATE_MESSAGE
	cm.AccountId = req.AccountId
	cm.InitialChannelId = c.Id
	if err := cm.Create(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	_, err := c.AddMessage(cm.Id)
	if err != nil {
		// todo this should be internal server error
		return helpers.NewBadRequestResponse(err)
	}

	// append creator to the recipients
	req.Recipients = append(req.Recipients, req.AccountId)
	for _, participantId := range req.Recipients {
		_, err := c.AddParticipant(participantId)
		if err != nil {
			return helpers.NewBadRequestResponse(err)
		}
	}

	cmc := models.NewChannelContainer()
	cmc.Channel = *c
	cmc.IsParticipant = true
	cmc.LastMessage = cm
	cmc.ParticipantCount = len(participantIds)
	cmc.ParticipantsPreview = participantIds

	return helpers.NewOKResponse(cmc)
}

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	q := helpers.GetQuery(u)

	channels, err := getPrivateMessageChannels(q)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	populatedChannels := models.PopulateChannelContainers(channels, q.AccountId)

	for i, populatedChannel := range populatedChannels {
		cp := models.NewChannelParticipant()
		cp.ChannelId = populatedChannel.Channel.Id

		// add participant preview
		cpList, err := cp.ListAccountIds(5)
		if err != nil {
			return helpers.NewBadRequestResponse(err)
		}
		populatedChannels[i].ParticipantsPreview = cpList

		// add last message of the channel
		cm, err := populatedChannel.Channel.FetchLastMessage()
		if err != nil {
			return helpers.NewBadRequestResponse(err)
		}
		populatedChannels[i].LastMessage = cm
	}

	return helpers.NewOKResponse(populatedChannels)

}

func getPrivateMessageChannels(q *models.Query) ([]models.Channel, error) {
	// build query for
	c := models.NewChannel()
	channelIds := make([]int64, 0)
	rows, err := bongo.B.DB.Table(c.TableName()).
		Select("api.channel_participant.channel_id").
		Joins("left join api.channel_participant on api.channel_participant.channel_id = api.channel.id").
		Where("api.channel_participant.account_id = ? and "+
		"api.channel.group_name = ? and "+
		"api.channel.type_constant = ? and "+
		"api.channel_participant.status_constant = ?",
		q.AccountId,
		q.GroupName,
		models.Channel_TYPE_PRIVATE_MESSAGE,
		models.ChannelParticipant_STATUS_ACTIVE).
		Limit(q.Limit).
		Offset(q.Skip).
		Rows()
	defer rows.Close()
	if err != nil {
		return nil, err
	}

	var channelId int64
	for rows.Next() {
		rows.Scan(&channelId)
		channelIds = append(channelIds, channelId)
	}

	channels, err := c.FetchByIds(channelIds)
	if err != nil {
		return nil, err
	}

	return channels, nil
}
