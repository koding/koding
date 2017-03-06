package realtime

import (
	mongomodels "koding/db/models"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/api/realtimehelper"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

const (
	NotificationEventName       = "NotificationAdded"
	ChannelUpdateEventName      = "ChannelUpdateHappened"
	RemovedFromChannelEventName = "RemovedFromChannel"
	AddedToChannelEventName     = "AddedToChannel"
	ChannelDeletedEventName     = "ChannelDeleted"
	ChannelUpdatedEventName     = "ChannelUpdated"

	// instance events
	UpdateInstanceEventName = "updateInstance"
)

var mongoAccounts map[int64]*mongomodels.Account

func init() {
	mongoAccounts = make(map[int64]*mongomodels.Account)
}

// Controller holds required instances for processing events
type Controller struct {
	// logging instance
	log logging.Logger

	// connection to RMQ
	rmqConn *amqp.Connection
}

// NotificationEvent holds required data for notifcation processing
type NotificationEvent struct {
	// Holds routing key for notification dispatching
	Event string `json:"event"`

	// Content of the notification
	Content NotificationContent `json:"contents"`
}

// NotificationContent holds required data for notification events
type NotificationContent struct {
	// TypeConstant holds the type of a notification
	// But in some cases, this property can hold the status of the
	// notification, like "delivered" and "read"
	TypeConstant string `json:"type"`

	TargetId int64  `json:"targetId,string"`
	ActorId  string `json:"actorId"`
}

type ParticipantContent struct {
	AccountId    int64  `json:"accountId,string"`
	AccountOldId string `json:"accountOldId"`
	ChannelId    int64  `json:"channelId"`
}

// DefaultErrHandler controls the errors, return false if an error occurred
func (r *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	r.log.Error("an error occurred deleting realtime event", err)
	delivery.Ack(false)
	return false
}

// New Creates a new controller for realtime package
func New(rmq *rabbitmq.RabbitMQ, log logging.Logger) *Controller {
	ffc := &Controller{
		log:     log,
		rmqConn: rmq.Conn(),
	}

	return ffc
}

// ChannelParticipantUpdatedEvent is fired when we update any info of the
// channel participant
// We are updating status_constant while removing user from the channel
// but regarding operation has another event, so we are gonna ignore it
func (f *Controller) ChannelParticipantUpdatedEvent(cp *models.ChannelParticipant) error {
	// if status of the participant is left, then just notify the current user
	if cp.StatusConstant != models.ChannelParticipant_STATUS_ACTIVE {
		f.log.Info("Ignoring participant (%d) event: %s", cp.AccountId, cp.StatusConstant)
		return nil
	}

	// fetch the channel that user is updated
	c, err := models.Cache.Channel.ById(cp.ChannelId)
	if err != nil {
		return err
	}

	cue := &channelUpdatedEvent{
		Controller:         f,
		Channel:            c,
		EventType:          channelUpdatedEventChannelParticipantUpdated,
		ChannelParticipant: cp,
	}

	return cue.sendForParticipant()
}

// ChannelParticipantRemoved is fired when we remove any info of channel participant
func (f *Controller) ChannelParticipantRemoved(pe *models.ParticipantEvent) error {
	return f.sendChannelParticipantEvent(pe, RemovedFromChannelEventName)
}

// ChannelParticipantAdded is fired when we add any info of channel participant
func (f *Controller) ChannelParticipantsAdded(pe *models.ParticipantEvent) error {
	return f.sendChannelParticipantEvent(pe, AddedToChannelEventName)
}

// sendChannelParticipantEvent sends update message with newly added/removed participant
// information
// TODO we can send this information with just a single message
func (f *Controller) sendChannelParticipantEvent(pe *models.ParticipantEvent, eventName string) error {

	c, err := models.Cache.Channel.ById(pe.Id)
	if err != nil {
		f.log.Error("Could not fetch participated channel %d: %s", pe.Id, err)
		return nil
	}

	if c.TypeConstant == models.Channel_TYPE_GROUP {
		return nil
	}

	// send notification to the user(added user)
	go f.notifyChannelParticipants(c, pe, eventName)

	// channel must be notified with newly added/removed participants
	for _, participant := range pe.Participants {
		acc, err := models.Cache.Account.ById(participant.AccountId)
		if err != nil {
			f.log.Error("Could update fetch participant old id: %s", err)
			continue
		}

		pc := &ParticipantContent{
			AccountId:    participant.AccountId,
			AccountOldId: acc.OldId,
			ChannelId:    pe.Id,
		}

		// send this event to the channel itself- this must happen just for newly added accounts
		if err := f.publishToChannel(pe.Id, eventName, pc); err != nil {
			f.log.Error("Could update channel with participant information: %s", err)
		}
	}

	return nil
}

// notifyParticipants notifies related participants when they join/leave private channel
// or follow/unfollow a topic.
// this is used for updating sidebar.
func (f *Controller) notifyChannelParticipants(c *models.Channel, pe *models.ParticipantEvent, eventName string) {
	if c.TypeConstant != models.Channel_TYPE_COLLABORATION {
		return
	}

	notifiedParticipantIds, err := f.fetchNotifiedParticipantIds(c, pe, eventName)
	if err != nil {
		f.log.Error("Could not fetch participants: %s", err)
		return
	}

	for _, participantId := range notifiedParticipantIds {
		cc := models.NewChannelContainer()
		err = cc.PopulateWith(*c, participantId)
		if err != nil {
			f.log.Error("Could not create channel container for participant %d: %s", pe.Id, err)
			continue
		}

		if err = f.sendNotification(
			participantId,
			c.GroupName,
			eventName,
			cc,
		); err != nil {
			f.log.Error("Ignoring err %s ", err.Error())
		}
	}
}

func (f *Controller) fetchNotifiedParticipantIds(c *models.Channel, pe *models.ParticipantEvent, eventName string) ([]int64, error) {
	notifiedParticipantIds := make([]int64, 0)

	// notify added/removed participants
	for _, participant := range pe.Participants {
		notifiedParticipantIds = append(notifiedParticipantIds, participant.AccountId)
	}

	// When a user is removed from a private channel notify all channel participants to
	// make them update their sidebar channel list.
	if eventName == RemovedFromChannelEventName {

		if c.TypeConstant == models.Channel_TYPE_COLLABORATION {

			participantIds, err := c.FetchParticipantIds(&request.Query{})
			if err != nil {
				return notifiedParticipantIds, err
			}
			notifiedParticipantIds = append(notifiedParticipantIds, participantIds...)
		}
	}
	return notifiedParticipantIds, nil
}

func (f *Controller) ChannelDeletedEvent(c *models.Channel) error {
	return f.publishToChannel(c.Id, ChannelDeletedEventName, &models.ChannelContainer{Channel: c})
}

func (f *Controller) ChannelUpdatedEvent(c *models.Channel) error {
	return f.publishToChannel(c.Id, ChannelUpdatedEventName, &models.ChannelContainer{Channel: c})
}

// publishToChannel receives channelId eventName and data to be published
// it fechessecret names from mongo db a publihes to each of them
// message is sent as a json message
// this function is not idempotent
func (f *Controller) publishToChannel(channelId int64, eventName string, data interface{}) error {
	ch, err := models.Cache.Channel.ById(channelId)
	if err != nil {
		return err
	}

	return realtimehelper.PushMessage(ch, eventName, data)
}

func (f *Controller) sendNotification(
	accountId int64, groupName string, eventName string, data interface{},
) error {
	account, err := models.Cache.Account.ById(accountId)
	if err != nil {
		return err
	}

	return realtimehelper.NotifyUser(account, eventName, data, groupName)
}
