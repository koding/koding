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
	MessageAddedEventName       = "MessageAdded"
	MessageRemovedEventName     = "MessageRemoved"
	ChannelDeletedEventName     = "ChannelDeleted"
	ChannelUpdatedEventName     = "ChannelUpdated"

	// instance events
	ReplyRemovedEventName   = "ReplyRemoved"
	ReplyAddedEventName     = "ReplyAdded"
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

// MessageUpdated controls message updated status
// if an error occurred , returns error otherwise returns nil
func (f *Controller) MessageUpdated(cm *models.ChannelMessage) error {
	if len(cm.Token) == 0 {
		if err := cm.ById(cm.Id); err != nil {
			return err
		}
	}

	if err := f.sendInstanceEvent(cm, cm, UpdateInstanceEventName); err != nil {
		f.log.Error(err.Error())
		return err
	}

	return nil
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

	if c.TypeConstant == models.Channel_TYPE_ANNOUNCEMENT ||
		c.TypeConstant == models.Channel_TYPE_GROUP {
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
	if c.TypeConstant != models.Channel_TYPE_PRIVATE_MESSAGE &&
		c.TypeConstant != models.Channel_TYPE_COLLABORATION &&
		c.TypeConstant != models.Channel_TYPE_TOPIC {
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

		if c.TypeConstant == models.Channel_TYPE_PRIVATE_MESSAGE ||
			c.TypeConstant == models.Channel_TYPE_COLLABORATION {

			participantIds, err := c.FetchParticipantIds(&request.Query{})
			if err != nil {
				return notifiedParticipantIds, err
			}
			notifiedParticipantIds = append(notifiedParticipantIds, participantIds...)
		}
	}
	return notifiedParticipantIds, nil
}

// MessageReplySaved updates the channels , send messages in updated channel
// and sends messages which is added
func (f *Controller) MessageReplySaved(mr *models.MessageReply) error {
	f.sendReplyEventAsChannelUpdatedEvent(mr, channelUpdatedEventReplyAdded)
	f.sendReplyAddedEvent(mr)

	return nil
}

func (f *Controller) sendReplyAddedEvent(mr *models.MessageReply) error {
	parent, err := models.Cache.Message.ById(mr.MessageId)
	if err != nil {
		return err
	}

	// if reply is created now, it wont be in the cache
	// but fetch it from db and add to cache, we may use it later
	reply, err := models.Cache.Message.ById(mr.ReplyId)
	if err != nil {
		return err
	}

	cmc, err := reply.BuildEmptyMessageContainer()
	if err != nil {
		return err
	}

	cmc.Message.ClientRequestId = mr.ClientRequestId

	err = f.sendInstanceEvent(parent, cmc, ReplyAddedEventName)
	if err != nil {
		return err
	}

	return nil
}

func (f *Controller) sendReplyEventAsChannelUpdatedEvent(mr *models.MessageReply, eventType channelUpdatedEventType) error {
	parent, err := models.Cache.Message.ById(mr.MessageId)
	if err != nil {
		return err
	}

	// if reply is created now, it wont be in the cache
	// but fetch it from db and add to cache, we may use it later
	reply, err := models.Cache.Message.ById(mr.ReplyId)
	if err != nil {
		return err
	}

	cml := models.NewChannelMessageList()
	channels, err := cml.FetchMessageChannels(parent.Id)
	if err != nil {
		return err
	}

	if len(channels) == 0 {
		f.log.Error(
			"Message:(%d) is not in any channel, bu somehow we addd a reply??",
			parent.Id,
		)
		return nil
	}

	cue := &channelUpdatedEvent{
		// channel will be set in range loop
		Controller:           f,
		Channel:              nil,
		ParentChannelMessage: parent,
		ReplyChannelMessage:  reply,
		EventType:            eventType,
	}

	// send this event to all channels
	// that have this message
	for _, channel := range channels {
		cue.Channel = &channel
		// send this event to all channels
		// that have this message
		err := cue.notifyAllParticipants()
		if err != nil {
			f.log.Error("err %s", err.Error())
		}
	}

	return nil
}

func (f *Controller) MessageReplyDeleted(mr *models.MessageReply) error {
	f.sendReplyEventAsChannelUpdatedEvent(mr, channelUpdatedEventReplyRemoved)
	m, err := models.Cache.Message.ById(mr.MessageId)
	if err != nil {
		return err
	}

	if err := f.sendInstanceEvent(m, mr, ReplyRemovedEventName); err != nil {
		return err
	}

	return nil
}

// send message to the channel
func (f *Controller) MessageListSaved(cml *models.ChannelMessageList) error {
	c, err := models.Cache.Channel.ById(cml.ChannelId)
	if err != nil {
		return err
	}

	// populate cache
	cm, err := models.Cache.Message.ById(cml.MessageId)
	if err != nil {
		return err
	}

	cm.ClientRequestId = cml.ClientRequestId

	cm, err = cm.PopulatePayload()
	if err != nil {
		return err
	}

	cue := &channelUpdatedEvent{
		Controller:           f,
		Channel:              c,
		ParentChannelMessage: cm,
		EventType:            channelUpdatedEventMessageAddedToChannel,
	}

	if err := cue.notifyAllParticipants(); err != nil {
		return err
	}

	if err := f.sendChannelEvent(cml, cm, MessageAddedEventName); err != nil {
		return err
	}

	return nil
}

// ChannelMessageListUpdated event states that one of the channel_message_list
// record is updated, it means that one the pinned post's owner glanced it. - At
// least for now - If we decide on another giving another meaning on this event,
// we can rename the event.  PinnedPost's unread count is calculated from the
// last glanced reply's point. This message is user specific. There is no
// relation with channel participants or channel itself
func (f *Controller) ChannelMessageListUpdated(cml *models.ChannelMessageList) error {

	// find the user's pinned post channel
	// we need it for finding the account id
	c, err := models.Cache.Channel.ById(cml.ChannelId)
	if err != nil {
		return err
	}

	if c.TypeConstant != models.Channel_TYPE_PINNED_ACTIVITY {
		f.log.Error("please investigate here, we have updated the channel message list for a non-pinned post item %+v", c)
		return nil
	}

	// get the glanced message
	cm, err := models.Cache.Message.ById(cml.MessageId)
	if err != nil {
		return err
	}

	// No need to fetch the participant from database we are gonna use only the
	// account id
	cp := models.NewChannelParticipant()
	cp.AccountId = c.CreatorId
	cp.ChannelId = c.Id
	if err := cp.FetchParticipant(); err != nil {
		return err
	}

	cue := &channelUpdatedEvent{
		// inject controller for reaching to RMQ, log and other stuff
		Controller: f,

		// In which channel this event happened, we need groupName from the
		// channel because user can be in multiple groups, and all group-account
		// couples have separate channels
		Channel: c,

		// We need parentChannelMessage for calculating the unread count of it's replies
		ParentChannelMessage: cm,

		// ChannelParticipant is the receiver of this event
		ChannelParticipant: cp,

		// Assign event type
		EventType: channelUpdatedEventMessageUpdatedAtChannel,
	}

	if err := cue.sendForParticipant(); err != nil {
		return err
	}

	return nil
}

// PinnedChannelListUpdated handles the events of pinned channel lists'.  When a
// user glance a pinned message or when someone posts reply to a message we are
// updating the channel message lists
func (f *Controller) PinnedChannelListUpdated(pclue *models.PinnedChannelListUpdatedEvent) error {
	// find the user's pinned post channel
	// we need it for finding the account id
	c := pclue.Channel

	if &c == nil {
		f.log.Error("channel was nil, discarding the message %+v", pclue)
		return nil
	}

	if c.TypeConstant != models.Channel_TYPE_PINNED_ACTIVITY {
		f.log.Error("please investigate here, we have updated the channel message list for a non-pinned post item %+v", c)
		return nil
	}

	// No need to fetch the participant from database we are gonna use only the
	// account id
	cp := models.NewChannelParticipant()
	cp.AccountId = c.CreatorId
	cp.ChannelId = c.Id
	if err := cp.FetchParticipant(); err != nil {
		return err
	}

	cue := &channelUpdatedEvent{
		// inject controller for reaching to RMQ, log and other stuff
		Controller: f,

		// In which channel this event happened, we need groupName from the
		// channel because user can be in multiple groups, and all group-account
		// couples have separate channels
		Channel: &c,

		// We need parentChannelMessage for calculating the unread count of it's replies
		ParentChannelMessage: &pclue.Message,

		// We need to find out that if the reply is created by a troll
		ReplyChannelMessage: &pclue.Reply,

		// ChannelParticipant is the receiver of this event
		ChannelParticipant: cp,

		// Assign event type
		EventType: channelUpdatedEventReplyAdded,
	}

	if err := cue.sendForParticipant(); err != nil {
		return err
	}

	return nil
}

// todo - refactor this part
func (f *Controller) MessageListDeleted(cml *models.ChannelMessageList) error {
	c, err := models.Cache.Channel.ById(cml.ChannelId)
	if err != nil {
		return err
	}

	// Since we are making hard deletes, we no longer need to check the
	// message existency
	cm := models.NewChannelMessage()
	cm.Id = cml.MessageId

	cp := models.NewChannelParticipant()
	cp.AccountId = c.CreatorId

	cue := &channelUpdatedEvent{
		Controller:           f,
		Channel:              c,
		ParentChannelMessage: cm,
		ChannelParticipant:   cp,
		EventType:            channelUpdatedEventMessageRemovedFromChannel,
	}

	if err := cue.notifyAllParticipants(); err != nil {
		return err
	}

	// f.sendNotification(cp.AccountId, ChannelUpdateEventName, cue)

	if err := f.sendChannelEvent(cml, cm, MessageRemovedEventName); err != nil {
		return err
	}

	return nil
}

func (f *Controller) ChannelDeletedEvent(c *models.Channel) error {
	return f.publishToChannel(c.Id, ChannelDeletedEventName, &models.ChannelContainer{Channel: c})
}

func (f *Controller) ChannelUpdatedEvent(c *models.Channel) error {
	return f.publishToChannel(c.Id, ChannelUpdatedEventName, &models.ChannelContainer{Channel: c})
}

func (f *Controller) sendInstanceEvent(cm *models.ChannelMessage, body interface{}, eventName string) error {
	return realtimehelper.UpdateInstance(cm, eventName, body)
}

func (f *Controller) sendChannelEvent(cml *models.ChannelMessageList, cm *models.ChannelMessage, eventName string) error {
	cmc, err := cm.BuildEmptyMessageContainer()
	if err != nil {
		return err
	}

	return f.publishToChannel(cml.ChannelId, eventName, cmc)
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
