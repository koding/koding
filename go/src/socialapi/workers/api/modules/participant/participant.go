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

func Add(u *url.URL, h http.Header, participants []*models.ChannelParticipant) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)
	channelId := query.Id

	if err := checkChannelPrerequisites(channelId, query.AccountId, participants); err != nil {
		return response.NewBadRequest(err)
	}

	for i := range participants {
		participant := models.NewChannelParticipant()
		participant.AccountId = participants[i].AccountId
		participant.ChannelId = channelId

		if err := participant.Create(); err != nil {
			return response.NewBadRequest(err)
		}

		participants[i] = participant
	}

	return response.NewOK(participants)
}

func Delete(u *url.URL, h http.Header, participants []*models.ChannelParticipant) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)
	channelId := query.Id

	if err := checkChannelPrerequisites(channelId, query.AccountId, participants); err != nil {
		return response.NewBadRequest(err)
	}

	for i := range participants {
		participants[i].ChannelId = channelId
		if err := participants[i].Delete(); err != nil {
			return response.NewBadRequest(err)
		}
	}

	return response.NewOK(participants)
}

func Presence(u *url.URL, h http.Header, participants []*models.ChannelParticipant) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)
	channelId := query.Id

	if err := checkChannelPrerequisites(channelId, query.AccountId, participants); err != nil {
		return response.NewBadRequest(err)
	}

	for i := range participants {

		participants[i].ChannelId = channelId
		if err := participants[i].FetchParticipant(); err != nil {
			return response.NewBadRequest(err)
		}

		participants[i].LastSeenAt = time.Now().UTC()

		if err := participants[i].Update(); err != nil {
			return response.NewBadRequest(err)
		}
	}

	return response.NewOK(participants)
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

	// if requester tries to add participant into pinned activity channel
	// return error
	if c.TypeConstant == models.Channel_TYPE_PINNED_ACTIVITY {
		return errors.New("can not add/remove participants for pinned activity channel")
	}

	// return early for non private message channels
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
