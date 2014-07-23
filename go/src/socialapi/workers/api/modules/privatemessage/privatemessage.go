package privatemessage

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"

	"github.com/koding/bongo"
)

var ErrAccountIdNotSet = errors.New("acccountId is not defined")

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
		a.Nick = account.Profile.Nickname
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

func appendCreatorIdIntoParticipantList(participants []int64, authorId int64) []int64 {
	for _, participant := range participants {
		if participant == authorId {
			return participants
		}
	}

	return append(participants, authorId)
}

func Init(u *url.URL, h http.Header, req *models.PrivateMessageRequest) (int, http.Header, interface{}, error) {
	if req.AccountId == 0 {
		return response.NewBadRequest(ErrAccountIdNotSet)
	}

	cm := models.NewChannelMessage()
	cm.Body = req.Body
	participantIds, err := fetchParticipantIds(req.Recipients)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// append creator to the recipients
	participantIds = appendCreatorIdIntoParticipantList(participantIds, req.AccountId)

	// author and atleast one recipient should be in the
	// recipient list
	if len(participantIds) < 1 {
		// user can send private message to themself
		return response.NewBadRequest(errors.New("you should define your recipients"))
	}

	if req.GroupName == "" {
		req.GroupName = models.Channel_KODING_NAME
	}

	//// first create the channel
	c := models.NewPrivateMessageChannel(req.AccountId, req.GroupName)
	if err := c.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	cm.TypeConstant = models.ChannelMessage_TYPE_PRIVATE_MESSAGE
	cm.AccountId = req.AccountId
	cm.InitialChannelId = c.Id
	if err := cm.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	messageContainer, err := cm.BuildEmptyMessageContainer()
	if err != nil {
		return response.NewBadRequest(err)
	}

	_, err = c.AddMessage(cm.Id)
	if err != nil {
		return response.NewBadRequest(err)
	}

	for _, participantId := range participantIds {
		_, err := c.AddParticipant(participantId)
		if err != nil {
			return response.NewBadRequest(err)
		}
	}

	cmc := models.NewChannelContainer()
	cmc.Channel = c
	cmc.IsParticipant = true
	cmc.LastMessage = messageContainer
	cmc.ParticipantCount = len(participantIds)
	participantOldIds, err := models.FetchAccountOldsIdByIdsFromCache(participantIds)
	if err != nil {
		return response.NewBadRequest(err)
	}

	cmc.ParticipantsPreview = participantOldIds

	return response.NewOK(cmc)
}

func Send(u *url.URL, h http.Header, req *models.PrivateMessageRequest) (int, http.Header, interface{}, error) {
	if req.AccountId == 0 {
		return response.NewBadRequest(ErrAccountIdNotSet)
	}

	// check channel existence
	c := models.NewChannel()
	if err := c.ById(req.ChannelId); err != nil {
		return response.NewBadRequest(err)
	}

	// check if sender is whether a participant of conversation
	cp := models.NewChannelParticipant()
	cp.ChannelId = c.Id
	cp.AccountId = req.AccountId
	if err := cp.FetchParticipant(); err != nil {
		return response.NewBadRequest(err)
	}

	// add private message
	cm := models.NewChannelMessage()
	cm.Body = req.Body
	cm.TypeConstant = models.ChannelMessage_TYPE_PRIVATE_MESSAGE
	cm.AccountId = req.AccountId
	cm.InitialChannelId = c.Id
	if err := cm.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	if _, err := c.AddMessage(cm.Id); err != nil {
		return response.NewBadRequest(err)
	}

	messageContainer, err := cm.BuildEmptyMessageContainer()
	if err != nil {
		return response.NewBadRequest(err)
	}

	cmc := models.NewChannelContainer()
	cmc.Channel = c
	cmc.IsParticipant = true
	cmc.LastMessage = messageContainer

	return response.NewOK(cmc)
}

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	q := request.GetQuery(u)

	if q.AccountId == 0 || q.GroupName == "" {
		return response.NewBadRequest(errors.New("request is not valid"))
	}

	channelList, err := getPrivateMessageChannels(q)
	if err != nil {
		return response.NewBadRequest(err)
	}

	cc := models.NewChannelContainers()
	if err := cc.Fetch(channelList, q); err != nil {
		return response.NewBadRequest(err)
	}

	cc.AddIsParticipant(q.AccountId)

	// TODO this should be in the channel cache by default
	cc.AddLastMessage()
	cc.AddUnreadCount(q.AccountId)

	return response.HandleResultAndError(cc, cc.Err())
}

func getPrivateMessageChannels(q *request.Query) ([]models.Channel, error) {
	// build query for
	c := models.NewChannel()
	channelIds := make([]int64, 0)
	query := bongo.B.DB.
		Model(c).
		Table(c.TableName()).
		Select("api.channel_participant.channel_id").
		Joins("left join api.channel_participant on api.channel_participant.channel_id = api.channel.id").
		Where("api.channel_participant.account_id = ? and "+
		"api.channel.group_name = ? and "+
		"api.channel.type_constant = ? and "+
		"api.channel_participant.status_constant = ?",
		q.AccountId,
		q.GroupName,
		models.Channel_TYPE_PRIVATE_MESSAGE,
		models.ChannelParticipant_STATUS_ACTIVE)

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
