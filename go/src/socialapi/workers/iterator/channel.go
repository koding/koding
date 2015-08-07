package iterator

import (
	"fmt"
	"socialapi/models"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/logging"
)

type channelIterator func([]models.Channel) error

func Channels(
	log logging.Logger,
	groupName string,
	f channelIterator,
	d time.Duration,
) error {

	var errors []error
	m := models.Channel{}

	for {
		var channels []models.Channel

		// fetch all records, even deleted ones, because we are not gonna need
		// them anymore
		err := bongo.B.DB.
			Unscoped().
			Model(m).
			Table(m.TableName()).
			Limit(processCount).
			Where("group_name = ?", groupName). // dont process the group channel itself
			Find(&channels).Error

		// if we encounter an error do not continue, if we cant find any
		// result, it can be excluded from the error case, because since we
		// will not be able to process any message, system will return
		if err != nil && err != bongo.RecordNotFound {
			return err
		}

		// we processed all channel messages. or no message exits
		if len(channels) == 0 {
			log.Info("doesnt have any message lists for moving")
			break
		}

		err = f(channels)
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
