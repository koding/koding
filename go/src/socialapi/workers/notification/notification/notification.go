package notification

import (
	"fmt"
	socialapimodels "socialapi/models"
	"socialapi/workers/notification/models"
	"time"

	"github.com/koding/bongo"
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
}

func (n *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	n.log.Error("an error occured: %s", err)
	delivery.Ack(false)

	return false
}

func New(rmq *rabbitmq.RabbitMQ, log logging.Logger) (*Controller, error) {
	rmqConn, err := rmq.Connect("NewNotificationWorkerController")
	if err != nil {
		return nil, err
	}

	nwc := &Controller{
		log:     log,
		rmqConn: rmqConn.Conn(),
	}

	return nwc, nil
}

// this is temporary method used for hiding private message notifications
// previously created. Once it is run in all servers, it will be deleted
func HidePMNotifications() {
	// n.log.Debug("hiding pm notifications")
	fmt.Println("hiding pm notifications")
	var ids []int64
	nc := models.NewNotificationContent()
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"type_constant": models.NotificationContent_TYPE_PM,
		},
		Pluck: "id",
	}

	if err := nc.Some(&ids, query); err != nil {
		fmt.Printf("Could not hide pm notifications: %s \n", err)
		return
	}

	if len(ids) == 0 {
		return
	}

	ntf := models.NewNotification()

	updateSql := "UPDATE " + ntf.TableName() + ` set "activated_at" = ? WHERE "notification_content_id" in (?)`

	err := bongo.B.DB.Exec(updateSql, time.Time{}, ids).Error
	if err != nil {
		fmt.Printf("Could not hide pm notifications: %s \n", err)
	}
}

// CreateReplyNotification notifies main thread owner.
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
	rn.MessageId = reply.Id

	subscribedAt := time.Now()

	nc, err := models.CreateNotificationContent(rn)
	if err != nil {
		return err
	}

	// if it is not notifier's own message then add replier to subscribers
	// for further reply notifications
	if cm.AccountId != rn.NotifierId {
		n.subscribe(nc.Id, cm.AccountId, subscribedAt)
	}

	notifiedUsers, err := rn.GetNotifiedUsers(nc.Id)
	if err != nil {
		return err
	}

	mentionedUsers, err := n.CreateMentionNotification(reply, cm.Id)
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
		n.notify(nc.Id, recipient)
	}

	if !notifierSubscribed {
		n.subscribe(nc.Id, rn.NotifierId, subscribedAt)
	}

	return nil
}

// func (n *Controller) UnsubscribeMessage(data *socialapimodels.ChannelMessageList) error {
// 	return subscription(data, NOTIFICATION_TYPE_UNSUBSCRIBE)
// }

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

func (n *Controller) HandleMessage(cm *socialapimodels.ChannelMessage) error {
	switch cm.TypeConstant {
	case socialapimodels.ChannelMessage_TYPE_POST:
		_, err := n.CreateMentionNotification(cm, cm.Id)
		return err
	case socialapimodels.ChannelMessage_TYPE_PRIVATE_MESSAGE:
		return n.privateMessageNotification(cm)
	default:
		return nil
	}
}

func (n *Controller) privateMessageNotification(cm *socialapimodels.ChannelMessage) error {
	if cm.TypeConstant != socialapimodels.ChannelMessage_TYPE_PRIVATE_MESSAGE {
		return nil
	}

	// fetch participants
	cp := socialapimodels.NewChannelParticipant()
	cp.ChannelId = cm.InitialChannelId
	time.Sleep(3 * time.Second)
	participantIds, err := cp.ListAccountIds(0)
	if err != nil {
		return err
	}

	if len(participantIds) == 0 {
		n.log.Warning("Private channel participant count cannot be 0")
		return nil
	}

	pn := models.NewPMNotification()
	pn.TargetId = cm.InitialChannelId
	pn.NotifierId = cm.AccountId
	nc, err := models.CreateNotificationContent(pn)
	if err != nil {
		return err
	}

	for _, participant := range participantIds {
		if cm.AccountId != participant {
			n.notifyOnce(nc.Id, participant)
		}
	}

	return nil
}

// CreateMentionNotification creates mention notifications for the related channel messages
func (n *Controller) CreateMentionNotification(reply *socialapimodels.ChannelMessage, targetId int64) ([]int64, error) {
	mentionedUserIds := make([]int64, 0)
	usernames := reply.GetMentionedUsernames()

	// message does not contain any mentioned users
	if len(usernames) == 0 {
		return mentionedUserIds, nil
	}

	mentionedUsers, err := socialapimodels.FetchAccountsByNicks(usernames)
	if err != nil {
		return nil, err
	}

	for _, mentionedUser := range mentionedUsers {
		// if user mentions herself ignore it
		if mentionedUser.Id == reply.AccountId {
			continue
		}
		mn := models.NewMentionNotification()
		mn.TargetId = targetId
		mn.MessageId = reply.Id
		mn.NotifierId = reply.AccountId
		nc, err := models.CreateNotificationContent(mn)
		if err != nil {
			return nil, err
		}

		n.instantNotify(nc.Id, mentionedUser.Id)

		mentionedUserIds = append(mentionedUserIds, mentionedUser.Id)
	}

	return mentionedUserIds, nil
}

func (n *Controller) notify(contentId, notifierId int64) {
	notification := buildNotification(contentId, notifierId, time.Now())
	if err := notification.Upsert(); err != nil {
		n.log.Error("An error occurred while notifying user %d: %s", notification.AccountId, err.Error())
	}
}

func (n *Controller) instantNotify(contentId, notifierId int64) {
	notification := prepareActiveNotification(contentId, notifierId)
	if err := notification.Upsert(); err != nil {
		n.log.Error("An error occurred while notifying user %d: %s", notification.AccountId, err.Error())
	}
}

func (n *Controller) notifyOnce(contentId, notifierId int64) {
	notification := prepareActiveNotification(contentId, notifierId)
	if err := notification.Create(); err != nil {
		n.log.Error("An error occurred while notifying user %d: %s", notification.AccountId, err.Error())
	}
}

func prepareActiveNotification(contentId, notifierId int64) *models.Notification {
	notification := buildNotification(contentId, notifierId, time.Now())
	notification.ActivatedAt = time.Now()

	return notification
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
