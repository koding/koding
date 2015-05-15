package algoliaconnector

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"strconv"
	"time"

	"labix.org/v2/mgo"
)

func (f *Controller) AccountCreated(data *models.Account) error {
	user, err := modelhelper.GetUser(data.Nick)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	if err == mgo.ErrNotFound {
		f.log.Error("user %+v is not found in mongodb", data)
		return nil
	}

	return f.insert(IndexAccounts, map[string]interface{}{
		"objectID": data.OldId,
		"nick":     data.Nick,
		"email":    user.Email,
		"_tags":    []string{f.kodingChannelId},
	})
}

func (f *Controller) AccountUpdated(data *models.Account) error {
	user, err := modelhelper.GetUser(data.Nick)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	if err == mgo.ErrNotFound {
		f.log.Error("user %+v is not found in mongodb", data)
		return nil
	}

	record, err := f.get(IndexAccounts, data.OldId)
	if err != nil &&
		!IsAlgoliaError(err, ErrAlgoliaObjectIdNotFoundMsg) &&
		!IsAlgoliaError(err, ErrAlgoliaIndexNotExistMsg) {
		return err
	}

	// algolia partial update works like this, if item exists updates it, if
	// they cant find any document with objectID, they create it
	if record == nil {
		return f.AccountCreated(data)
	}

	return f.partialUpdate(IndexAccounts, map[string]interface{}{
		"objectID": data.OldId,
		"nick":     data.Nick,
		"email":    user.Email,
	})
}

// ParticipantUpdated operates with the participant deleted/created events, adds
// to algolia if the state is active, else removes from algolia
func (f *Controller) ParticipantUpdated(p *models.ChannelParticipant) error {
	// This code is commented out and stays here just for future referance,
	// channel participant table is the only one that we are not soft deleting
	// records, and marking status as left, we dont have a notion
	// channel_participant_delete, handle accordingly

	// // if status of the participant is active, then add user
	// if p.StatusConstant == models.ChannelParticipant_STATUS_ACTIVE {
	// 	return f.handleParticipantOperation(p)
	// }

	err := f.handleParticipantOperation(p)
	if err != nil {
		f.log.Error("err while handling participant updated event: %s", err.Error())
	}

	return err
}

// ParticipantCreated operates with the participant createad event, adds new tag
// to the algolia document
func (f *Controller) ParticipantCreated(p *models.ChannelParticipant) error {
	err := f.handleParticipantOperation(p)
	if err != nil {
		f.log.Error("err while handling participant created event: %s", err.Error())
	}

	return err
}

func (f *Controller) handleParticipantOperation(p *models.ChannelParticipant) error {
	if p.ChannelId == 0 {
		return nil
	}

	if p.AccountId == 0 {
		return nil
	}

	a := models.NewAccount()
	if err := a.ById(p.AccountId); err != nil {
		f.log.Error("err while fetching account: %s", err.Error())
		return nil
	}

	if a.Id == 0 {
		f.log.Critical("account found but id is 0 %+v", a)
		return nil
	}

	record, err := f.get(IndexAccounts, a.OldId)
	if err != nil &&
		!IsAlgoliaError(err, ErrAlgoliaObjectIdNotFoundMsg) &&
		!IsAlgoliaError(err, ErrAlgoliaIndexNotExistMsg) {
		return err
	}

	if record == nil {
		// first create the account
		if err := f.AccountCreated(a); err != nil {
			return err
		}

		// make sure account is there, before start processing it
		err := makeSureAccount(f, a.OldId, func(record map[string]interface{}, err error) bool {
			if err != nil {
				return false
			}

			if record == nil {
				return false
			}

			return true
		})
		if err != nil {
			return err
		}
	}

	record, err = f.get(IndexAccounts, a.OldId)
	if err != nil {
		return err
	}

	cp := models.NewChannelParticipant()
	ids, err := cp.FetchAllParticipatedChannelIds(a.Id)
	if err != nil {
		return err
	}

	// fetch all channels of account, there is a race condition when a user
	// joins to multiple channels, due to algolia's eventual consistency,
	// obtained tags are not up-to-date
	var channelIds []string
	for _, id := range ids {
		channelIds = append(channelIds, strconv.FormatInt(id, 10))
	}

	return f.partialUpdate(IndexAccounts, map[string]interface{}{
		"objectID": a.OldId,
		"_tags":    channelIds,
	})
}

var errDeadline = errors.New("deadline reached")

// makeSureAccount checks if the given id's get request returns the desired err,
// it will re-try every 100ms until deadline of 2 minutes reached. Algolia
// doesnt index the records right away, so try to go to a desired state
func makeSureAccount(handler *Controller, id string, f func(map[string]interface{}, error) bool) error {
	deadLine := time.After(time.Minute * 2)
	tick := time.Tick(time.Millisecond * 100)
	for {
		select {
		case <-tick:
			record, err := handler.get(IndexAccounts, id)
			if f(record, err) {
				return nil
			}
		case <-deadLine:
			return errDeadline
		}
	}
}
