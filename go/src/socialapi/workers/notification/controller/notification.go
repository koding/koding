package notification

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	socialapimodels "socialapi/models"
	"socialapi/workers/notification/models"
	"time"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

const (
	NOTIFICATION_TYPE_SUBSCRIBE   = "subscribe"
	NOTIFICATION_TYPE_UNSUBSCRIBE = "unsubscribe"
)

type Controller struct {
	log             logging.Logger
	rmqConn         *amqp.Connection
	notifierRmqConn *amqp.Connection
	cacheEnabled    bool
}

func (n *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	n.log.Error("an error occured: %s", err)
	delivery.Ack(false)

	return false
}

func New(rmq *rabbitmq.RabbitMQ, log logging.Logger, cacheEnabled bool) (*Controller, error) {
	rmqConn, err := rmq.Connect("NewNotificationWorkerController")
	if err != nil {
		return nil, err
	}

	nwc := &Controller{
		log:          log,
		rmqConn:      rmqConn.Conn(),
		cacheEnabled: cacheEnabled,
	}

	return nwc, nil
}

func (n *Controller) CreateReplyNotification(mr *socialapimodels.MessageReply) error {
	// fetch replier
	reply := socialapimodels.NewChannelMessage()
	if err := reply.ById(mr.ReplyId); err != nil {
		return err
	}

	cm := socialapimodels.NewChannelMessage()
	// notify message owner
	if err := cm.ById(mr.MessageId); err != nil {
		return err
	}

	if cm.TypeConstant != socialapimodels.ChannelMessage_TYPE_POST {
		return nil
	}

	rn := models.NewReplyNotification()
	rn.TargetId = mr.MessageId
	rn.NotifierId = reply.AccountId
	subscribedAt := time.Now()

	nc, err := models.CreateNotificationContent(rn)
	if err != nil {
		return err
	}

	// if it is not notifier's own message then add owner to subscribers
	if cm.AccountId != rn.NotifierId {
		n.subscribe(nc.Id, cm.AccountId, subscribedAt)
	}

	notifiedUsers, err := rn.GetNotifiedUsers(nc.Id)
	if err != nil {
		return err
	}

	mentionedUsers, err := n.CreateMentionNotification(reply)
	if err != nil {
		return err
	}

	notifiedUsers = filterRepliers(notifiedUsers, mentionedUsers)

	notifierSubscribed := false
	for _, recipient := range notifiedUsers {
		if recipient == rn.NotifierId {
			notifierSubscribed = true
		}
		n.notify(nc.Id, recipient, subscribedAt)
	}

	// if not subcribed, subscribe the actor to message
	if !notifierSubscribed {
		n.subscribe(nc.Id, rn.NotifierId, subscribedAt)
	}

	return nil
}

func (n *Controller) UnsubscribeMessage(data *socialapimodels.ChannelMessageList) error {
	return subscription(data, NOTIFICATION_TYPE_UNSUBSCRIBE)
}

func (n *Controller) SubscribeMessage(data *socialapimodels.ChannelMessageList) error {
	return subscription(data, NOTIFICATION_TYPE_SUBSCRIBE)
}

func subscription(cml *socialapimodels.ChannelMessageList, typeConstant string) error {
	c := socialapimodels.NewChannel()
	if err := c.ById(cml.ChannelId); err != nil {
		return err
	}

	if c.TypeConstant != socialapimodels.Channel_TYPE_PINNED_ACTIVITY {
		return nil
	}

	// user pinned (followed) a message
	nc := models.NewNotificationContent()
	nc.TargetId = cml.MessageId

	n := models.NewNotification()
	n.AccountId = c.CreatorId

	switch typeConstant {
	case NOTIFICATION_TYPE_SUBSCRIBE:
		return n.Subscribe(nc)
	case NOTIFICATION_TYPE_UNSUBSCRIBE:
		return n.Unsubscribe(nc)
	}

	return nil
}

// MentionNotification creates mention notifications for the related channel messages
func (n *Controller) MentionNotification(cm *socialapimodels.ChannelMessage) error {
	// Since the type of private channel messages is Private_Message,
	// we did not need to add another "is channel private" check
	if cm.TypeConstant != socialapimodels.ChannelMessage_TYPE_POST {
		return nil
	}

	mentionedUsers, err := n.CreateMentionNotification(cm)
	if err != nil {
		return err
	}

	if len(mentionedUsers) == 0 {
		return nil
	}

	rn := models.NewReplyNotification()
	rn.TargetId = cm.Id
	rn.NotifierId = cm.AccountId

	nc, err := models.CreateNotificationContent(rn)
	if err != nil {
		return err
	}

	for _, recipient := range mentionedUsers {
		n.notify(nc.Id, recipient, time.Now())
	}

	return nil
}

func (n *Controller) CreateMentionNotification(reply *socialapimodels.ChannelMessage) ([]int64, error) {
	mentionedUserIds := make([]int64, 0)
	usernames := reply.GetMentionedUsernames()

	// message does not contain any mentioned users
	if len(usernames) == 0 {
		return mentionedUserIds, nil
	}

	mentionedUserIds, err := fetchParticipantIds(usernames)
	if err != nil {
		return nil, err
	}

	for _, mentionedUser := range mentionedUserIds {
		if mentionedUser == reply.AccountId {
			continue
		}
		mn := models.NewMentionNotification()
		mn.TargetId = reply.Id
		mn.NotifierId = reply.AccountId
		nc, err := models.CreateNotificationContent(mn)
		if err != nil {
			return nil, err
		}

		notification := models.NewNotification()
		notification.NotificationContentId = nc.Id
		notification.AccountId = mentionedUser
		notification.ActivatedAt = time.Now() // enables notification immediately
		if err = notification.Upsert(); err != nil {
			n.log.Error("An error occurred while notifying user %d: %s", reply.AccountId, err.Error())
		}
	}

	return mentionedUserIds, nil
}

func (n *Controller) notify(contentId, notifierId int64, subscribedAt time.Time) {
	notification := buildNotification(contentId, notifierId, subscribedAt)
	if err := notification.Upsert(); err != nil {
		n.log.Error("An error occurred while notifying user %d: %s", notification.AccountId, err.Error())
	}
}

func (n *Controller) subscribe(contentId, notifierId int64, subscribedAt time.Time) {
	notification := buildNotification(contentId, notifierId, subscribedAt)
	notification.SubscribeOnly = true
	if err := notification.Create(); err != nil {
		n.log.Error("An error occurred while subscribing user %d: %s", notification.AccountId, err.Error())
	}
}

func buildNotification(contentId, notifierId int64, subscribedAt time.Time) *models.Notification {
	notification := models.NewNotification()
	notification.NotificationContentId = contentId
	notification.AccountId = notifierId
	notification.SubscribedAt = subscribedAt

	return notification
}

func (n *Controller) CreateInteractionNotification(i *socialapimodels.Interaction) error {
	cm := socialapimodels.NewChannelMessage()
	if err := cm.ById(i.MessageId); err != nil {
		return err
	}

	// user likes her own message, so we bypass notification
	if cm.AccountId == i.AccountId {
		return nil
	}

	in := models.NewInteractionNotification(i.TypeConstant)
	in.TargetId = i.MessageId
	in.NotifierId = i.AccountId
	nc, err := models.CreateNotificationContent(in)
	if err != nil {
		return err
	}

	notification := models.NewNotification()
	notification.NotificationContentId = nc.Id
	notification.AccountId = cm.AccountId // notify message owner
	notification.ActivatedAt = time.Now() // enables notification immediately
	if err = notification.Upsert(); err != nil {
		return fmt.Errorf("An error occurred while notifying user %d: %s", cm.AccountId, err.Error())
	}

	return nil
}

func (n *Controller) JoinChannel(cp *socialapimodels.ChannelParticipant) error {
	return processChannelParticipant(cp, models.NotificationContent_TYPE_JOIN)
}

func (n *Controller) LeaveChannel(cp *socialapimodels.ChannelParticipant) error {
	if cp.StatusConstant == socialapimodels.ChannelParticipant_STATUS_LEFT {
		return processChannelParticipant(cp, models.NotificationContent_TYPE_LEAVE)
	}

	return nil
}

func processChannelParticipant(cp *socialapimodels.ChannelParticipant, typeConstant string) error {
	c := socialapimodels.NewChannel()
	if err := c.ById(cp.ChannelId); err != nil {
		return err
	}

	switch c.TypeConstant {
	case socialapimodels.Channel_TYPE_GROUP:
		return interactGroup(cp, c, typeConstant)
	case socialapimodels.Channel_TYPE_FOLLOWERS:
		return interactFollow(cp, c)
	}

	return nil
}

func interactFollow(cp *socialapimodels.ChannelParticipant, c *socialapimodels.Channel) error {
	if cp.StatusConstant == socialapimodels.ChannelParticipant_STATUS_LEFT {
		return nil
	}
	nI := models.NewFollowNotification()
	nI.TargetId = cp.ChannelId
	nI.NotifierId = cp.AccountId
	nc, err := models.CreateNotificationContent(nI)
	if err != nil {
		return err
	}

	notification := models.NewNotification()
	notification.NotificationContentId = nc.Id
	notification.AccountId = c.CreatorId  // notify channel owner
	notification.ActivatedAt = time.Now() // enables notification immediately
	if err = notification.Upsert(); err != nil {
		return err
	}

	return nil
}

func interactGroup(cp *socialapimodels.ChannelParticipant, c *socialapimodels.Channel, typeConstant string) error {

	// user joins her own group, so we bypass notification
	if c.CreatorId == cp.AccountId {
		return nil
	}

	nI := models.NewGroupNotification(typeConstant)
	nI.TargetId = cp.ChannelId
	nI.NotifierId = cp.AccountId
	nc, err := models.CreateNotificationContent(nI)
	if err != nil {
		return err
	}

	//TODO all group admins (if there exists) should be notified
	notification := models.NewNotification()
	notification.NotificationContentId = nc.Id
	notification.AccountId = c.CreatorId  // notify channel owner
	notification.ActivatedAt = time.Now() // enables notification immediately
	if err = notification.Upsert(); err != nil {
		return err
	}

	return nil
}

// copy/paste
func fetchParticipantIds(participantNames []string) ([]int64, error) {
	participantIds := make([]int64, len(participantNames))
	for i, participantName := range participantNames {
		account, err := modelhelper.GetAccount(participantName)
		if err != nil {
			return nil, err
		}
		a := socialapimodels.NewAccount()
		a.Id = account.SocialApiId
		a.OldId = account.Id.Hex()
		// fetch or create social api id
		if a.Id == 0 {
			if err := a.FetchOrCreate(); err != nil {
				return nil, err
			}
		}
		participantIds[i] = a.Id
	}

	return participantIds, nil
}

func filterRepliers(repliers, mentionedUsers []int64) []int64 {
	mentionMap := map[int64]struct{}{}
	flattened := make([]int64, 0)
	if len(mentionedUsers) == 0 {
		return repliers
	}

	for _, user := range mentionedUsers {
		mentionMap[user] = struct{}{}
	}

	for _, replier := range repliers {
		if _, ok := mentionMap[replier]; !ok {
			flattened = append(flattened, replier)
		}
	}

	return flattened
}
