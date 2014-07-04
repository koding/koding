package participant

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
	"time"
)

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		fmt.Println(err)
		return response.NewBadRequest(err)
	}

	req := models.NewChannelParticipant()
	req.ChannelId = channelId
	return response.HandleResultAndError(
		req.List(request.GetQuery(u)),
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

	for i := range participants {
		participant := models.NewChannelParticipant()
		participant.AccountId = participants[i].AccountId
		participant.ChannelId = query.Id

		if err := participant.Create(); err != nil {
			return response.NewBadRequest(err)
		}

		participants[i] = participant
	}

	return response.NewOK(participants)
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

	for i := range participants {
		participants[i].ChannelId = query.Id
		if err := participants[i].Delete(); err != nil {
			return response.NewBadRequest(err)
		}
	}

	return response.NewOK(participants)
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

	participant.LastSeenAt = time.Now().UTC()

	if err := participant.Update(); err != nil {
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

	if c.TypeConstant == models.Channel_TYPE_GROUP {
		return errors.New("can not add/remove participants for pinned activity channel")
	}

	if c.TypeConstant == models.Channel_TYPE_PINNED_ACTIVITY {
		return errors.New("can not add/remove participants for pinned activity channel")
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
	if c.TypeConstant != models.Channel_TYPE_PRIVATE_MESSAGE {
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
