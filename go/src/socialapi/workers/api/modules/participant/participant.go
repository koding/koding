package participant

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"

	"github.com/koding/bongo"
	"github.com/koding/runner"
)

var ErrSkipActivity = errors.New("skip activity")

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)

	if query.Id == 0 {
		return response.NewBadRequest(errors.New("channel id is not set"))
	}

	c, err := models.ChannelById(query.Id)
	if err != nil {
		return response.NewBadRequest(err)
	}

	canOpen, err := c.CanOpen(query.AccountId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !canOpen {
		return response.NewAccessDenied(fmt.Errorf("user %d tried to open unattended channel %d", query.AccountId, query.Id))
	}

	return response.HandleResultAndError(
		fetchChannelParticipants(query),
	)
}

func AddMulti(u *url.URL, h http.Header, participants []*models.ChannelParticipant) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)

	if err := checkChannelPrerequisites(
		query.Id,
		query.AccountId,
		participants,
	); err != nil {
		return response.NewBadRequest(err)
	}

	ch := models.NewChannel()
	err := ch.ById(query.Id)
	if err != nil {
		return response.NewBadRequest(err)
	}

	for i := range participants {
		participant := models.NewChannelParticipant()
		participant.ChannelId = query.Id

		// prevent duplicate participant addition
		isParticipant, err := participant.IsParticipant(participants[i].AccountId)
		if err != nil {
			return response.NewBadRequest(err)
		}

		if isParticipant {
			continue
		}

		participant.AccountId = participants[i].AccountId

		if err := participant.Create(); err != nil {
			return response.NewBadRequest(err)
		}

		participants[i] = participant

		if err := addJoinActivity(query.Id, participant.AccountId, query.AccountId); err != nil {
			return response.NewBadRequest(err)
		}

	}

	go notifyParticipants(ch, models.ChannelParticipant_Added_To_Channel_Event, participants)

	return response.NewOK(participants)
}

func notifyParticipants(channel *models.Channel, event string, participants []*models.ChannelParticipant) {
	pe := models.NewParticipantEvent()
	pe.Id = channel.Id
	pe.Participants = participants
	pe.ChannelToken = channel.Token
	logger := runner.MustGetLogger()

	for _, participant := range participants {
		acc, err := models.Cache.Account.ById(participant.AccountId)
		if err != nil {
			logger.Error("Could not fetch account: %s", err)
		}
		pe.Tokens = append(pe.Tokens, acc.Token)
	}

	if err := bongo.B.PublishEvent(event, pe); err != nil {
		logger.Error("Could not notify channel participants: %s", err.Error())
	}

}

func RemoveMulti(u *url.URL, h http.Header, participants []*models.ChannelParticipant) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)

	if err := checkChannelPrerequisites(
		query.Id,
		query.AccountId,
		participants,
	); err != nil {
		return response.NewBadRequest(err)
	}

	ch := models.NewChannel()
	err := ch.ById(query.Id)
	if err != nil {
		return response.NewBadRequest(err)
	}

	for i := range participants {
		// if the requester is trying to remove some other user than themselves, and they are not the channel owner
		// return bad request
		if participants[i].AccountId != query.AccountId && query.AccountId != ch.CreatorId {
			return response.NewBadRequest(fmt.Errorf("User is not allowed to kick other users"))
		}

		participants[i].ChannelId = query.Id
		if err := participants[i].Delete(); err != nil {
			return response.NewBadRequest(err)
		}

		if err := addLeaveActivity(query.Id, participants[i].AccountId); err != nil {
			return response.NewBadRequest(err)
		}
	}

	// this could be moved into another worker, but i did not want to create a new worker that will be used
	// for just a few times
	go func() {
		if err := DeleteDesertedChannelMessages(query.Id); err != nil {
			runner.MustGetLogger().Error("Could not delete channel messages: %s", err.Error())
		}
	}()

	go notifyParticipants(ch, models.ChannelParticipant_Removed_From_Channel_Event, participants)

	return response.NewOK(participants)
}

func BlockMulti(u *url.URL, h http.Header, participants []*models.ChannelParticipant) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)

	if err := checkChannelPrerequisites(
		query.Id,
		query.AccountId,
		participants,
	); err != nil {
		return response.NewBadRequest(err)
	}

	ch := models.NewChannel()
	err := ch.ById(query.Id)
	if err != nil {
		return response.NewBadRequest(err)
	}

	for i := range participants {
		// if the requester is trying to remove some other user than themselves, and they are not the channel owner
		// return bad request
		if participants[i].AccountId != query.AccountId && query.AccountId != ch.CreatorId {
			return response.NewBadRequest(fmt.Errorf("User is not allowed to block other users"))
		}

		participants[i].ChannelId = query.Id
		if err := participants[i].Block(); err != nil {
			return response.NewBadRequest(err)
		}
	}

	// this could be moved into another worker, but i did not want to create a new worker that will be used
	// for just a few times
	go func() {
		if err := DeleteDesertedChannelMessages(query.Id); err != nil {
			runner.MustGetLogger().Error("Could not delete channel messages: %s", err.Error())
		}
	}()

	go notifyParticipants(ch, models.ChannelParticipant_Removed_From_Channel_Event, participants)

	return response.NewOK(participants)
}

func UnblockMulti(u *url.URL, h http.Header, participants []*models.ChannelParticipant) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)

	if err := checkChannelPrerequisites(
		query.Id,
		query.AccountId,
		participants,
	); err != nil {
		return response.NewBadRequest(err)
	}

	ch := models.NewChannel()
	err := ch.ById(query.Id)
	if err != nil {
		return response.NewBadRequest(err)
	}

	for i := range participants {
		// if the requester is trying to remove some other user than themselves, and they are not the channel owner
		// return bad request
		if participants[i].AccountId != query.AccountId && query.AccountId != ch.CreatorId {
			return response.NewBadRequest(fmt.Errorf("User is not allowed to unblock other users"))
		}

		participants[i].ChannelId = query.Id
		if err := participants[i].Unblock(); err != nil {
			return response.NewBadRequest(err)
		}
	}

	return response.NewOK(participants)
}

// DeletePrivateChannelMessages deletes all channel messages from a private message channel
// when there are no more participants
func DeleteDesertedChannelMessages(channelId int64) error {
	c := models.NewChannel()
	if err := c.ById(channelId); err != nil {
		return err
	}

	if c.TypeConstant != models.Channel_TYPE_PRIVATE_MESSAGE &&
		c.TypeConstant != models.Channel_TYPE_COLLABORATION {
		return nil
	}

	cp := models.NewChannelParticipant()
	cp.ChannelId = c.Id
	count, err := cp.FetchParticipantCount()
	if err != nil {
		return err
	}

	if count != 0 {
		return nil
	}

	// no need to keep the channel any more
	return c.Delete()
}

func UpdatePresence(u *url.URL, h http.Header, participant *models.ChannelParticipant) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)

	participant.ChannelId = query.Id
	// only requester can update their last seen date
	participant.AccountId = query.AccountId

	if err := checkChannelPrerequisites(
		query.Id,
		query.AccountId,
		[]*models.ChannelParticipant{participant},
	); err != nil {
		return response.NewBadRequest(err)
	}

	// @todo add a new function into participant just
	// for updating with lastSeenDate
	if err := participant.FetchParticipant(); err != nil {
		return response.NewBadRequest(err)
	}

	// glance the channel
	if err := participant.Glance(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(participant)
}

func checkChannelPrerequisites(channelId, requesterId int64, participants []*models.ChannelParticipant) error {
	if channelId == 0 || requesterId == 0 {
		return errors.New("values are not set")
	}

	if len(participants) == 0 {
		return errors.New("0 participant is given for participant operation")
	}

	c, err := models.ChannelById(channelId)
	if err != nil {
		return err
	}

	canOpen, err := c.CanOpen(requesterId)
	if err != nil {
		return err
	}

	if !canOpen {
		return errors.New("can not open channel")
	}

	if c.TypeConstant == models.Channel_TYPE_GROUP {
		return errors.New("can not add/remove participants for group channel")
	}

	if c.TypeConstant == models.Channel_TYPE_PINNED_ACTIVITY {
		return errors.New("can not add/remove participants for pinned activity channel")
	}

	if c.TypeConstant == models.Channel_TYPE_BOT {
		return errors.New("can not add/remove participants for bot channel")
	}

	if c.TypeConstant == models.Channel_TYPE_TOPIC {
		if len(participants) != 1 {
			return errors.New("you can not add only one participant into topic channel")
		}

		if participants[0].AccountId != requesterId {
			return errors.New("you can not add others into topic channel")
		}
	}

	// return early for non private message channels
	// no need to continue from here for other channels
	if c.TypeConstant != models.Channel_TYPE_PRIVATE_MESSAGE &&
		c.TypeConstant != models.Channel_TYPE_COLLABORATION &&
		c.TypeConstant != models.Channel_TYPE_GROUP {
		return nil
	}

	// check if requester is a participant of the private message channel
	cp := models.NewChannelParticipant()
	cp.ChannelId = channelId
	isParticipant, err := cp.IsParticipant(requesterId)
	if err != nil {
		return err
	}

	if !isParticipant {
		return fmt.Errorf("%d is not a participant of the channel %d, only participants can add/remove", requesterId, channelId)
	}

	return nil
}

func addJoinActivity(channelId, participantId, addedBy int64) error {

	c, err := fetchChannelWithValidation(channelId)
	if err != nil {
		if err == ErrSkipActivity {
			return nil
		}

		return err
	}

	pmr := &models.PrivateChannelRequest{AccountId: participantId}

	return pmr.AddJoinActivity(c, addedBy)
}

func addLeaveActivity(channelId, participantId int64) error {
	c, err := fetchChannelWithValidation(channelId)
	if err != nil {
		if err == ErrSkipActivity {
			return nil
		}

		return err
	}

	pmr := &models.PrivateChannelRequest{AccountId: participantId}

	return pmr.AddLeaveActivity(c)
}

// this function is tested via integration tests
func fetchChannelWithValidation(channelId int64) (*models.Channel, error) {
	c := models.NewChannel()
	if err := c.ById(channelId); err != nil {
		return nil, err
	}

	// add activity information for private message channel
	if c.TypeConstant != models.Channel_TYPE_PRIVATE_MESSAGE &&

		c.TypeConstant != models.Channel_TYPE_COLLABORATION {
		return nil, ErrSkipActivity
	}

	return c, nil
}

func fetchChannelParticipants(query *request.Query) ([]models.ChannelParticipantContainer, error) {
	cp := models.NewChannelParticipant()
	cp.ChannelId = query.Id

	participants, err := cp.List(query)
	if err != nil {
		return nil, err
	}

	cps := make([]models.ChannelParticipantContainer, len(participants))

	for i, participant := range participants {
		cpc, err := models.NewChannelParticipantContainer(participant)
		if err != nil {
			return cps, err
		}
		cps[i] = *cpc
	}

	return cps, nil
}
