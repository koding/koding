package participant

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
	"time"

	"github.com/cenkalti/backoff"
	"github.com/koding/bongo"
	"github.com/koding/runner"
)

var ErrSkipActivity = errors.New("skip activity")

func List(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	query := context.OverrideQuery(request.GetQuery(u))

	if query.Id == 0 {
		return response.NewBadRequest(errors.New("channel id is not set"))
	}

	c, err := models.Cache.Channel.ById(query.Id)
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

func AddMulti(u *url.URL, h http.Header, participants []*models.ChannelParticipant, context *models.Context) (int, http.Header, interface{}, error) {
	query := context.OverrideQuery(request.GetQuery(u))

	bo := backoff.NewExponentialBackOff()
	bo.InitialInterval = time.Millisecond * 50
	bo.MaxInterval = time.Millisecond * 100
	bo.MaxElapsedTime = time.Second * 2

	ticker := backoff.NewTicker(bo)
	defer ticker.Stop()

	var err error
	var ch *models.Channel
	var cps []*models.ChannelParticipant
	for range ticker.C {
		ch, cps, err = addMultiFunc(query, participants)
		if err != nil {
			continue
		}
		break
	}

	if err != nil {
		return response.NewBadRequest(err)
	}

	go notifyParticipants(ch, models.ChannelParticipant_Added_To_Channel_Event, cps)

	return response.NewOK(cps)
}

func addMultiFunc(query *request.Query, participants []*models.ChannelParticipant) (*models.Channel, []*models.ChannelParticipant, error) {
	if err := checkChannelPrerequisites(
		query.Id,
		query.AccountId,
		participants,
	); err != nil {
		return nil, nil, err
	}

	ch := models.NewChannel()
	err := ch.ById(query.Id)
	if err != nil {
		return nil, nil, err
	}

	for i := range participants {
		participant := models.NewChannelParticipant()
		participant.ChannelId = query.Id

		// prevent duplicate participant addition
		isParticipant, err := participant.IsParticipant(participants[i].AccountId)
		if err != nil {
			return nil, nil, err
		}

		if isParticipant {
			continue
		}

		participant.AccountId = participants[i].AccountId
		//We can add users with requestpending status
		if participants[i].StatusConstant != "" {
			participant.StatusConstant = participants[i].StatusConstant
		}

		if err := participant.Create(); err != nil {
			return nil, nil, err
		}

		participants[i] = participant
	}

	return ch, participants, nil
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

func RemoveMulti(u *url.URL, h http.Header, participants []*models.ChannelParticipant, context *models.Context) (int, http.Header, interface{}, error) {
	query := context.OverrideQuery(request.GetQuery(u))

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

	isAdmin, err := modelhelper.IsAdmin(context.Client.Account.Nick, context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	for i := range participants {
		// if the requester is trying to remove some other user than themselves, and they are not the channel owner
		// return bad request
		if participants[i].AccountId != query.AccountId && query.AccountId != ch.CreatorId {

			if !isAdmin {
				return response.NewBadRequest(fmt.Errorf("User is not allowed to kick other users"))
			}

		}

		participants[i].ChannelId = query.Id
		if err := participants[i].Delete(); err != nil {
			return response.NewBadRequest(err)
		}
	}

	go notifyParticipants(ch, models.ChannelParticipant_Removed_From_Channel_Event, participants)

	return response.NewOK(participants)
}

func BlockMulti(u *url.URL, h http.Header, participants []*models.ChannelParticipant, context *models.Context) (int, http.Header, interface{}, error) {
	query := context.OverrideQuery(request.GetQuery(u))

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

	isAdmin, err := modelhelper.IsAdmin(context.Client.Account.Nick, context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	for i := range participants {
		// if the requester is trying to remove some other user than themselves, and they are not the channel owner
		// return bad request
		if participants[i].AccountId != query.AccountId && query.AccountId != ch.CreatorId {
			if !isAdmin {
				return response.NewBadRequest(fmt.Errorf("User is not allowed to block other users"))
			}
		}

		participants[i].ChannelId = query.Id
		if err := participants[i].Block(); err != nil {
			return response.NewBadRequest(err)
		}
	}

	go notifyParticipants(ch, models.ChannelParticipant_Removed_From_Channel_Event, participants)

	return response.NewOK(participants)
}

func UnblockMulti(u *url.URL, h http.Header, participants []*models.ChannelParticipant, context *models.Context) (int, http.Header, interface{}, error) {
	query := context.OverrideQuery(request.GetQuery(u))

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

	isAdmin, err := modelhelper.IsAdmin(context.Client.Account.Nick, context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	for i := range participants {
		// if the requester is trying to remove some other user than themselves, and they are not the channel owner
		// return bad request
		if participants[i].AccountId != query.AccountId && query.AccountId != ch.CreatorId {
			if !isAdmin {
				return response.NewBadRequest(fmt.Errorf("User is not allowed to unblock other users"))
			}
		}

		participants[i].ChannelId = query.Id
		if err := participants[i].Unblock(); err != nil {
			return response.NewBadRequest(err)
		}
	}

	return response.NewOK(participants)
}

func UpdatePresence(u *url.URL, h http.Header, participant *models.ChannelParticipant, context *models.Context) (int, http.Header, interface{}, error) {
	query := context.OverrideQuery(request.GetQuery(u))

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

func AcceptInvite(u *url.URL, h http.Header, participant *models.ChannelParticipant, ctx *models.Context) (int, http.Header, interface{}, error) {

	query := ctx.OverrideQuery(request.GetQuery(u))

	participant.StatusConstant = models.ChannelParticipant_STATUS_ACTIVE
	cp, err := updateStatus(participant, query, ctx)
	if err != nil {
		return response.NewBadRequest(err)
	}
	ch := models.NewChannel()
	if err := ch.ById(query.Id); err != nil {
		return response.NewBadRequest(err)
	}

	go notifyParticipants(ch, models.ChannelParticipant_Added_To_Channel_Event, []*models.ChannelParticipant{cp})

	return response.NewDefaultOK()
}

func RejectInvite(u *url.URL, h http.Header, participant *models.ChannelParticipant, ctx *models.Context) (int, http.Header, interface{}, error) {

	query := ctx.OverrideQuery(request.GetQuery(u))
	participant.StatusConstant = models.ChannelParticipant_STATUS_LEFT
	cp, err := updateStatus(participant, query, ctx)
	if err != nil {
		return response.NewBadRequest(err)
	}

	ch := models.NewChannel()

	if err := ch.ById(query.Id); err != nil {
		return response.NewBadRequest(err)
	}

	go notifyParticipants(ch, models.ChannelParticipant_Removed_From_Channel_Event, []*models.ChannelParticipant{cp})

	return response.NewDefaultOK()
}

func updateStatus(participant *models.ChannelParticipant, query *request.Query, ctx *models.Context) (*models.ChannelParticipant, error) {

	if ok := ctx.IsLoggedIn(); !ok {
		return nil, models.ErrNotLoggedIn
	}

	query.AccountId = ctx.Client.Account.Id

	cp := models.NewChannelParticipant()
	cp.ChannelId = query.Id

	// check if the user is invited
	isInvited, err := cp.IsInvited(query.AccountId)
	if err != nil {
		return nil, err
	}

	if !isInvited {
		return nil, errors.New("uninvited user error")
	}

	cp.StatusConstant = participant.StatusConstant
	// update the status
	if err := cp.Update(); err != nil {
		return nil, err
	}

	return cp, nil
}

func checkChannelPrerequisites(channelId, requesterId int64, participants []*models.ChannelParticipant) error {
	if channelId == 0 || requesterId == 0 {
		return fmt.Errorf("values are not set. channelId: %d, requesterId: %d", channelId, requesterId)
	}

	if len(participants) == 0 {
		return errors.New("0 participant is given for participant operation")
	}

	c, err := models.Cache.Channel.ById(channelId)
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

	// admins can add users into group channels
	// if c.TypeConstant == models.Channel_TYPE_GROUP {
	// 	return errors.New("can not add/remove participants for group channel")
	// }

	// return early for non private message channels
	// no need to continue from here for other channels
	if c.TypeConstant != models.Channel_TYPE_COLLABORATION &&
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

// this function is tested via integration tests
func fetchChannelWithValidation(channelId int64) (*models.Channel, error) {
	c := models.NewChannel()
	if err := c.ById(channelId); err != nil {
		return nil, err
	}

	// add activity information for private message channel
	if c.TypeConstant != models.Channel_TYPE_COLLABORATION {
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
