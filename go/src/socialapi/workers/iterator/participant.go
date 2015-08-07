package iterator

import (
	"fmt"
	"socialapi/models"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/logging"
)

const processCount = 100

type participantIterator func([]models.ChannelParticipant) error

func Participants(log logging.Logger, channelId int64, f participantIterator, d time.Duration) error {
	var errors []error

	for {

		var channelParticipants []models.ChannelParticipant

		m := models.ChannelParticipant{}
		// fetch all records, even deleted ones, because we are not gonna need
		// them anymore
		err := bongo.B.DB.
			Model(m).
			Table(m.BongoName()).
			Unscoped().
			Limit(processCount).
			Where("channel_id = ?", channelId).
			Find(&channelParticipants).Error

		// if we encounter an error do not continue, if we cant find any
		// result, it can be excluded from the error case, because since we
		// will not be able to process any message system will return
		if err != nil && err != bongo.RecordNotFound {
			return err
		}

		// we processed all channel participants, no need to continue anymore
		if len(channelParticipants) == 0 {
			log.Info("doesnt have any participants to process")
			break
		}

		err = f(channelParticipants)
		if err != nil {
			errors = append(errors, err)
		}

		// sleep for every `processCount` operation
		time.Sleep(d) // poor mans throttling strategy
	}

	// if error happens, return it, next time it will be re-tried
	if len(errors) != 0 {
		return fmt.Errorf("%+v", errors)
	}

	return nil
}
