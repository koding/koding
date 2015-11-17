package notification

import (
	"fmt"
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
	log     logging.Logger
	rmqConn *amqp.Connection
}

func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred: %s", err)
	delivery.Ack(false)

	return false
}

func New(rmq *rabbitmq.RabbitMQ, log logging.Logger) *Controller {
	return &Controller{
		log:     log,
		rmqConn: rmq.Conn(),
	}
}

// CreateReplyNotification notifies main thread owner.
func (c *Controller) CreateReplyNotification(mr *socialapimodels.MessageReply) error {
	cm, err := socialapimodels.Cache.Message.ById(mr.MessageId)
	if err != nil {
		return err
	}

	if cm.TypeConstant != socialapimodels.ChannelMessage_TYPE_POST {
		return nil
	}

	// fetch replier
	reply, err := socialapimodels.Cache.Message.ById(mr.ReplyId)
	if err != nil {
		return err
	}

	groupChannel, err := reply.FetchParentChannel()
	if err != nil {
		return err
	}

	rn := models.NewReplyNotification()
	rn.TargetId = mr.MessageId
	rn.NotifierId = reply.AccountId
	rn.MessageId = reply.Id

	subscribedAt := time.Now().UTC()

	nc, err := models.CreateNotificationContent(rn)
	if err != nil {
		return err
	}

	// if it is not notifier's own message then add replier to subscribers
	// for further reply notifications
	if cm.AccountId != rn.NotifierId {
		c.subscribe(nc.Id, cm.AccountId, subscribedAt, groupChannel)
	}

	notifiedUsers, err := rn.GetNotifiedUsers(nc.Id)
	if err != nil {
		return err
	}

	mentionedUsers, err := c.CreateMentionNotification(reply, cm.Id)
	if err != nil {
		return err
	}

	// if a user is already subscribed to a post, and also mentioned in a reply
	// just send mention notification -no need for reply notification.
	notifiedUsers = filterRepliers(notifiedUsers, mentionedUsers)

	notifierSubscribed := false
	for _, recipient := range notifiedUsers {
		if recipient == rn.NotifierId {
			notifierSubscribed = true
		}
		c.notify(nc.Id, recipient, groupChannel, true)
	}

	if !notifierSubscribed {
		c.subscribe(nc.Id, rn.NotifierId, subscribedAt, groupChannel)
	}

	return nil
}

// func (n *Controller) UnsubscribeMessage(data *socialapimodels.ChannelMessageList) error {
// 	return subscription(data, NOTIFICATION_TYPE_UNSUBSCRIBE)
// }

//func subscription(cml *socialapimodels.ChannelMessageList, typeConstant string) error {
//    c := socialapimodels.NewChannel()
//    if err := c.ById(cml.ChannelId); err != nil {
//        return err
//    }

//    if c.TypeConstant != socialapimodels.Channel_TYPE_PINNED_ACTIVITY {
//        return nil
//    }

//     user pinned (followed) a message
//    nc := models.NewNotificationContent()
//    nc.TargetId = cml.MessageId

//    n := models.NewNotification()
//    n.AccountId = c.CreatorId

//    switch typeConstant {
//    case NOTIFICATION_TYPE_SUBSCRIBE:
//        return n.Subscribe(nc)
//    case NOTIFICATION_TYPE_UNSUBSCRIBE:
//        return n.Unsubscribe(nc)
//    }

//    return nil
//}

func (c *Controller) HandleMessage(cm *socialapimodels.ChannelMessage) error {
	if !socialapimodels.IsIn(cm.TypeConstant, socialapimodels.ChannelMessage_TYPE_POST, socialapimodels.ChannelMessage_TYPE_PRIVATE_MESSAGE) {
		return nil
	}

	_, err := c.CreateMentionNotification(cm, cm.Id)
	return err
}

func (c *Controller) DeleteNotification(cm *socialapimodels.ChannelMessage) error {
	nc := models.NewNotificationContent()
	contentIds, err := nc.FetchIdsByTargetId(cm.Id)
	if err != nil {
		return err
	}

	if len(contentIds) == 0 {
		return nil
	}

	return models.NewNotification().HideByContentIds(contentIds)
}

// CreateMentionNotification creates mention notifications for the related channel messages
func (c *Controller) CreateMentionNotification(cm *socialapimodels.ChannelMessage, targetId int64) ([]int64, error) {
	usernames, err := NewMentionExtractor(cm, c.log).Do()
	if err != nil {
		return nil, err
	}

	// message does not contain any mentioned users
	if len(usernames) == 0 {
		return nil, nil
	}

	mentionedUsers, err := socialapimodels.FetchAccountsByNicks(usernames)
	if err != nil {
		return nil, err
	}

	return c.handleUsernameMentions(cm, targetId, mentionedUsers)
}

func (c *Controller) handleUsernameMentions(cm *socialapimodels.ChannelMessage, targetId int64, mentionedUsers []socialapimodels.Account) ([]int64, error) {
	initialChannel, err := socialapimodels.Cache.Channel.ById(cm.InitialChannelId)
	if err != nil {
		return nil, err
	}

	groupChannel, err := socialapimodels.Cache.Channel.ByGroupName(initialChannel.GroupName) // it has internal caching
	if err != nil {
		return nil, err
	}

	mentionedUserIds := make([]int64, 0)

	for _, mentionedUser := range mentionedUsers {
		// if user mentions herself ignore it
		if mentionedUser.Id == cm.AccountId {
			continue
		}

		mn := models.NewMentionNotification()
		mn.TargetId = targetId
		mn.MessageId = cm.Id
		mn.NotifierId = cm.AccountId
		nc, err := models.CreateNotificationContent(mn)
		if err != nil {
			return nil, err
		}

		c.instantNotify(nc.Id, mentionedUser.Id, groupChannel, true)

		mentionedUserIds = append(mentionedUserIds, mentionedUser.Id)
	}

	return mentionedUserIds, nil
}

func (c *Controller) notify(contentId, notifierId int64, contextChannel *socialapimodels.Channel, checkForParticipation bool) {
	if checkForParticipation {
		isParticipant, err := isParticipant(notifierId, contextChannel)
		if err != nil {
			c.log.Error("Could not check participation info for user %d: %s", notifierId, err)
			return
		}

		// when mentioned user does not exist within the group, do not send notification
		if !isParticipant {
			return
		}
	}

	notification := newNotification(contentId, notifierId, time.Now().UTC())
	notification.ContextChannelId = contextChannel.Id
	if err := notification.Upsert(); err != nil {
		c.log.Error("An error occurred while notifying user %d: %s", notification.AccountId, err.Error())
	}
}

func (c *Controller) instantNotify(contentId, notifierId int64, contextChannel *socialapimodels.Channel, checkForParticipation bool) {
	// if we need to check for participation, do here
	if checkForParticipation {
		isParticipant, err := isParticipant(notifierId, contextChannel)
		if err != nil {
			c.log.Error("Could not check participation info for user %d: %s", notifierId, err)
			return
		}

		// when mentioned user does not exist within the group, do not send notification
		if !isParticipant {
			return
		}
	}

	notification := prepareActiveNotification(contentId, notifierId)
	notification.ContextChannelId = contextChannel.Id
	if err := notification.Upsert(); err != nil {
		c.log.Error("An error occurred while notifying user %d: %s", notification.AccountId, err.Error())
	}
}

func isParticipant(accountId int64, c *socialapimodels.Channel) (bool, error) {
	cp := socialapimodels.NewChannelParticipant()
	cp.ChannelId = c.Id

	return cp.IsParticipant(accountId)
}

func (c *Controller) notifyOnce(contentId, notifierId int64) {
	notification := prepareActiveNotification(contentId, notifierId)
	if err := notification.Create(); err != nil {
		c.log.Error("An error occurred while notifying user %d: %s", notification.AccountId, err.Error())
	}
}

func prepareActiveNotification(contentId, notifierId int64) *models.Notification {
	n := newNotification(contentId, notifierId, time.Now().UTC())
	n.ActivatedAt = time.Now().UTC()

	return n
}

func (n *Controller) subscribe(contentId, notifierId int64, subscribedAt time.Time, c *socialapimodels.Channel) {
	ntf := newNotification(contentId, notifierId, subscribedAt)
	ntf.SubscribeOnly = true
	ntf.ContextChannelId = c.Id
	if err := ntf.Create(); err != nil {
		n.log.Error("An error occurred while subscribing user %d: %s", ntf.AccountId, err.Error())
	}
}

func newNotification(contentId, notifierId int64, subscribedAt time.Time) *models.Notification {
	n := models.NewNotification()
	n.NotificationContentId = contentId
	n.AccountId = notifierId
	n.SubscribedAt = subscribedAt

	return n
}

func (c *Controller) CreateInteractionNotification(i *socialapimodels.Interaction) error {
	cm := socialapimodels.NewChannelMessage()
	if err := cm.ById(i.MessageId); err != nil {
		return err
	}

	// user likes her own message, so we bypass notification
	if cm.AccountId == i.AccountId {
		return nil
	}

	groupChannel, err := cm.FetchParentChannel()
	if err != nil {
		return err
	}

	isParticipant, err := isParticipant(cm.AccountId, groupChannel)
	if err != nil || !isParticipant {
		return err
	}

	in := models.NewInteractionNotification(i.TypeConstant)
	if cm.TypeConstant == socialapimodels.ChannelMessage_TYPE_POST {
		in.TargetId = i.MessageId
	} else {
		mr := socialapimodels.NewMessageReply()
		mr.ReplyId = i.MessageId

		cm, err := mr.FetchParent()
		if err != nil {
			return err
		}

		in.TargetId = cm.Id
	}

	in.MessageId = i.MessageId
	in.NotifierId = i.AccountId
	nc, err := models.CreateNotificationContent(in)
	if err != nil {
		return err
	}

	notification := models.NewNotification()
	notification.NotificationContentId = nc.Id
	notification.AccountId = cm.AccountId       // notify message owner
	notification.ActivatedAt = time.Now().UTC() // enables notification immediately
	notification.ContextChannelId = groupChannel.Id
	if err = notification.Upsert(); err != nil {
		return fmt.Errorf("An error occurred while notifying user %d: %s", cm.AccountId, err.Error())
	}

	return nil
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
