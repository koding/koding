package topic

import (
	"fmt"
	"socialapi/models"

	"github.com/koding/bongo"
)

// moveParticipants moves the participants of the leaf node to the root node it
// doesnt update the lastSeenAt time of the participants on channels if the user
// already a participant of the root node, just removes the participation from
// leaf node, if user only participant of the leaf node updates the current
// participation with the new root node's channel id, it is always safe to
// return error whever we encounter one
func (c *Controller) moveParticipants(cl *models.ChannelLink) error {
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
			Where("channel_id = ?", cl.LeafId).
			Find(&channelParticipants).Error

		// if we encounter an error do not continue, if we cant find any
		// result, it can be excluded from the error case, because since we
		// will not be able to process any message system will return
		if err != nil && err != bongo.RecordNotFound {
			return err
		}

		// we processed all channel participants, no need to continue anymore
		if len(channelParticipants) == 0 {
			c.log.Info("doesnt have any participants to process")
			break
		}

		err = c.processParticipantMoveOperation(cl, channelParticipants)
		if err != nil {
			errors = append(errors, err)
		}
	}

	// if error happens, return it, next time it will be re-tried
	if len(errors) != 0 {
		return fmt.Errorf("%+v", errors)
	}

	return nil
}

func (c *Controller) processParticipantMoveOperation(
	cl *models.ChannelLink,
	channelParticipants []models.ChannelParticipant,
) error {
	var erroredChannelParticipants []models.ChannelParticipant
	m := models.ChannelParticipant{}

	for i, channelParticipant := range channelParticipants {
		// fetch the root channel's participant, if exists
		rootParticipation := models.NewChannelParticipant()
		rootParticipation.ChannelId = cl.RootId
		rootParticipation.AccountId = channelParticipant.AccountId
		err := rootParticipation.FetchParticipant()
		if err != nil && err != bongo.RecordNotFound {
			// dont append to erroredChannelParticipants because we need the
			// data here
			return err
		}

		// if the user is not the participant of root node, update the
		// current ChannelParticipant record with the root node's channel id
		if err == bongo.RecordNotFound {
			channelParticipant.ChannelId = cl.RootId
			if err := channelParticipant.Update(); err != nil {
				c.log.Error("Err while swapping channel ids %s", err.Error())
				erroredChannelParticipants = append(erroredChannelParticipants, channelParticipants[i])
			}

		} else {
			// if we get here it means the user is a member of the new root node
			// if the user is already participant of root channel, delete the
			// leaf node participation

			if err := bongo.B.
				Unscoped().
				Table(m.BongoName()).
				Delete(channelParticipant).
				Error; err != nil {
				c.log.Error("Err while deleting the channel participation %s", err.Error())
				erroredChannelParticipants = append(erroredChannelParticipants, channelParticipants[i])
				continue
			}
		}

		// send deleted event
		bongo.B.AfterDelete(channelParticipants[i])
	}

	// if error happens, return it, next time it will be re-tried
	if len(erroredChannelParticipants) != 0 {
		return fmt.Errorf("some errors: %v", erroredChannelParticipants)
	}

	return nil
}
