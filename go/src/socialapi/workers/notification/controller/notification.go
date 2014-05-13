package notification

import (
	"encoding/json"
	"errors"
	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/koding/worker"
	"github.com/streadway/amqp"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"labix.org/v2/mgo"
	socialapimodels "socialapi/models"
	"socialapi/workers/notification/models"
	"time"
)

type Action func(*NotificationWorkerController, []byte) error

type NotificationWorkerController struct {
	routes          map[string]Action
	log             logging.Logger
	rmqConn         *amqp.Connection
	notifierRmqConn *amqp.Connection
	cacheEnabled    bool
}

type NotificationEvent struct {
	RoutingKey string              `json:"routingKey"`
	Event      string              `json:"event"`
	Content    NotificationContent `json:"contents"`
}

type NotificationContent struct {
	TypeConstant string `json:"type"`
	TargetId     int64  `json:"targetId"`
	ActorId      int64  `json:"actorId"`
}

func (n *NotificationWorkerController) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	n.log.Error("an error occured: %s", err)
	delivery.Ack(false)

	return false
}

func NewNotificationWorkerController(rmq *rabbitmq.RabbitMQ, log logging.Logger, cacheEnabled bool) (*NotificationWorkerController, error) {
	rmqConn, err := rmq.Connect("NewNotificationWorkerController")
	if err != nil {
		return nil, err
	}

	notifierRmqConn, err := rmq.Connect("NotifierWorkerController")
	if err != nil {
		return nil, err
	}

	nwc := &NotificationWorkerController{
		log:             log,
		rmqConn:         rmqConn.Conn(),
		notifierRmqConn: notifierRmqConn.Conn(),
		cacheEnabled:    cacheEnabled,
	}

	routes := map[string]Action{
		"api.message_reply_created":         (*NotificationWorkerController).CreateReplyNotification,
		"api.interaction_created":           (*NotificationWorkerController).CreateInteractionNotification,
		"notification.notification_created": (*NotificationWorkerController).NotifyUser,
		"notification.notification_updated": (*NotificationWorkerController).NotifyUser,
		"api.channel_participant_created":   (*NotificationWorkerController).JoinGroup,
		"api.channel_participant_updated":   (*NotificationWorkerController).LeaveGroup,
	}

	nwc.routes = routes

	return nwc, nil
}

// copy/paste
func (n *NotificationWorkerController) HandleEvent(event string, data []byte) error {
	n.log.Debug("New Event Received %s", event)
	handler, ok := n.routes[event]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	return handler(n, data)
}

func (n *NotificationWorkerController) CreateReplyNotification(data []byte) error {
	mr, err := mapMessageToMessageReply(data)
	if err != nil {
		return err
	}

	// fetch replier
	cm := socialapimodels.NewChannelMessage()
	if err := cm.ById(mr.ReplyId); err != nil {
		return err
	}

	rn := models.NewReplyNotification()
	rn.TargetId = mr.MessageId
	rn.NotifierId = cm.AccountId
	subscribedAt := time.Now()

	nc, err := models.CreateNotificationContent(rn)
	if err != nil {
		return err
	}

	cm = socialapimodels.NewChannelMessage()
	// notify message owner
	if err = cm.ById(mr.MessageId); err != nil {
		return err
	}

	// if it is not notifier's own message then add owner to subscribers
	if cm.AccountId != rn.NotifierId {
		n.createNotification(nc.Id, cm.AccountId, subscribedAt)
	}

	notifiedUsers, err := rn.GetNotifiedUsers(nc.Id)
	if err != nil {
		return err
	}

	notifierSubscribed := false
	for _, recipient := range notifiedUsers {
		if recipient == rn.NotifierId {
			notifierSubscribed = true
		}
		n.createNotification(nc.Id, recipient, subscribedAt)
	}

	// if not subcribed, subscribe the actor to message
	if !notifierSubscribed {
		n.createNotification(nc.Id, rn.NotifierId, subscribedAt)
	}

	return nil
}

func (n *NotificationWorkerController) createNotification(contentId, notifierId int64, subscribedAt time.Time) {
	notification := models.NewNotification()
	notification.NotificationContentId = contentId
	notification.AccountId = notifierId
	notification.SubscribedAt = subscribedAt
	if err := notification.Create(); err != nil {
		n.log.Error("An error occurred while notifying user %d: %s", notifierId, err.Error())
	}
}

func (n *NotificationWorkerController) CreateInteractionNotification(data []byte) error {
	i, err := mapMessageToInteraction(data)
	if err != nil {
		return err
	}

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
	if err = notification.Create(); err != nil {
		n.log.Error("An error occurred while notifying user %d: %s", cm.AccountId, err.Error())
	}

	return nil
}

// TODO how this is handled, it looks like it needs refactoring
func (n *NotificationWorkerController) NotifyUser(data []byte) error {
	channel, err := n.notifierRmqConn.Channel()
	if err != nil {
		return errors.New("channel connection error")
	}
	defer channel.Close()

	notification, err := mapMessageToNotification(data)
	if err != nil {
		return err
	}

	// fetch notification content and get event type
	nc, err := notification.FetchContent()
	if err != nil {
		return err
	}

	nI, err := models.CreateNotificationContentType(nc.TypeConstant)
	if err != nil {
		return err
	}

	nI.SetTargetId(nc.TargetId)
	// ac, err := nt.FetchActors()
	// if err != nil {
	// 	return err
	// }

	// var actorId int64
	// if len(ac.LatestActors) > 0 {
	// 	actorId = ac.LatestActors[0]
	// }

	// go func() {
	// 	if n.cacheEnabled {
	// 		notificationCache := cache.NewNotificationCache()
	// 		if err := notificationCache.UpdateCache(notification, nc); err != nil {
	// 			n.log.Error("an error occurred %s", err)
	// 		}
	// 	}
	// }()

	accountId := notification.AccountId
	oldAccount, err := fetchNotifierOldAccount(accountId)
	if err != nil {
		return err
	}

	// fetch user profile name from bongo as routing key
	ne := &NotificationEvent{}
	ne.Event = nc.GetEventType()
	ne.Content = NotificationContent{
		// ActorId:      actorId,
		TargetId:     nc.TargetId,
		TypeConstant: nc.TypeConstant,
	}

	notificationMessage, err := json.Marshal(ne)
	if err != nil {
		return err
	}

	routingKey := oldAccount.Profile.Nickname

	return channel.Publish(
		"notification",
		routingKey,
		false,
		false,
		amqp.Publishing{Body: notificationMessage},
	)
}

// fetchNotifierOldAccount fetches mongo account of a given new account id.
// this function must be used under another file for further use
func fetchNotifierOldAccount(accountId int64) (*mongomodels.Account, error) {
	newAccount := socialapimodels.NewAccount()
	if err := newAccount.ById(accountId); err != nil {
		return nil, err
	}

	account, err := modelhelper.GetAccountById(newAccount.OldId)
	if err != nil {
		if err == mgo.ErrNotFound {
			return nil, errors.New("old account not found")
		}

		return nil, err
	}

	return account, nil
}

func (n *NotificationWorkerController) JoinGroup(data []byte) error {
	return processChannelParticipant(data, models.NotificationContent_TYPE_JOIN)
}

func (n *NotificationWorkerController) LeaveGroup(data []byte) error {
	return processChannelParticipant(data, models.NotificationContent_TYPE_LEAVE)
}

func processChannelParticipant(data []byte, typeConstant string) error {
	cp, err := mapMessageToChannelParticipant(data)
	if err != nil {
		return err
	}

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
	// TODO refactor this part
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
	if err = notification.Create(); err != nil {
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
	if err = notification.Create(); err != nil {
		return err
	}

	return nil
}

func mapMessageToChannelParticipant(data []byte) (*socialapimodels.ChannelParticipant, error) {
	cp := socialapimodels.NewChannelParticipant()
	if err := json.Unmarshal(data, cp); err != nil {
		return nil, err
	}

	return cp, nil
}

func mapMessageToMessageReply(data []byte) (*socialapimodels.MessageReply, error) {
	mr := socialapimodels.NewMessageReply()
	if err := json.Unmarshal(data, mr); err != nil {
		return nil, err
	}

	return mr, nil
}

func mapMessageToInteraction(data []byte) (*socialapimodels.Interaction, error) {
	i := socialapimodels.NewInteraction()
	if err := json.Unmarshal(data, i); err != nil {
		return nil, err
	}

	return i, nil
}

func mapMessageToNotification(data []byte) (*models.Notification, error) {
	n := models.NewNotification()
	if err := json.Unmarshal(data, n); err != nil {
		return nil, err
	}

	return n, nil
}
