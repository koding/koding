package topic

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/iterator"
	"time"

	"github.com/koding/bongo"
)

// sleepTimeForMoveParticipant holds sleeping tim per processCount, with current
// code, processParticipantMoveOperation will generate at least 100 events to
// system
var sleepTimeForMoveParticipant = time.Second * 1

// moveParticipants moves the participants of the leaf node to the root node it
// doesnt update the lastSeenAt time of the participants on channels if the user
// already a participant of the root node, just removes the participation from
// leaf node, if user only participant of the leaf node updates the current
// participation with the new root node's channel id, it is always safe to
// return error whever we encounter one
func (c *Controller) moveParticipants(cl *models.ChannelLink) error {
	log := c.log.New("rootId", cl.RootId, "leafId", cl.LeafId)

	f := c.processParticipantMoveOperation(cl)
	return iterator.Participants(log, cl.LeafId, f, sleepTimeForMoveParticipant)
}

func (c *Controller) processParticipantMoveOperation(cl *models.ChannelLink) func([]models.ChannelParticipant) error {
	return func(channelParticipants []models.ChannelParticipant) error {
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
}
