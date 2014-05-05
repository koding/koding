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
	"socialapi/models"
	"socialapi/workers/cache"
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

func (n *NotificationWorkerController) DefaultErrHandler(delivery amqp.Delivery, err error) {
	n.log.Error("an error occured: %s", err)

	delivery.Ack(false)
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
		"api.message_reply_created": (*NotificationWorkerController).CreateReplyNotification,
		"api.interaction_created":   (*NotificationWorkerController).CreateInteractionNotification,
		"api.notification_created":  (*NotificationWorkerController).NotifyUser,
		"api.notification_updated":  (*NotificationWorkerController).NotifyUser,
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
	cm := models.NewChannelMessage()
	if err := cm.ById(mr.ReplyId); err != nil {
		return err
	}

	rn := models.NewReplyNotification()
	rn.TargetId = mr.MessageId
	rn.NotifierId = cm.AccountId

	if err := models.CreateNotification(rn); err != nil {
		return err
	}

	return nil
}

func (n *NotificationWorkerController) CreateInteractionNotification(data []byte) error {
	i, err := mapMessageToInteraction(data)
	if err != nil {
		return err
	}

	// a bit error prune since we take interaction type as notification type
	in := models.NewInteractionNotification(i.TypeConstant)
	in.TargetId = i.MessageId
	in.NotifierId = i.AccountId
	if err := models.CreateNotification(in); err != nil {
		return err
	}

	return nil
}

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

	nt, err := models.CreateNotificationType(nc.TypeConstant)
	if err != nil {
		return err
	}

	nt.SetTargetId(nc.TargetId)
	ac, err := nt.FetchActors()
	if err != nil {
		return err
	}

	var actorId int64
	if len(ac.LatestActors) > 0 {
		actorId = ac.LatestActors[0]
	}

	go func() {
		if n.cacheEnabled {
			notificationCache := cache.NewNotificationCache()
			if err := notificationCache.UpdateCache(notification, nc); err != nil {
				n.log.Error("an error occurred %s", err)
			}
		}
	}()

	accountId := notification.AccountId
	oldAccount, err := fetchNotifierOldAccount(accountId)
	if err != nil {
		return err
	}

	// fetch user profile name from bongo as routing key
	ne := &NotificationEvent{}
	ne.Event = nc.GetEventType()
	ne.Content = NotificationContent{
		ActorId:      actorId,
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
	newAccount := models.NewAccount()
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

// copy/pasted from realtime package
func mapMessageToMessageReply(data []byte) (*models.MessageReply, error) {
	mr := models.NewMessageReply()
	if err := json.Unmarshal(data, mr); err != nil {
		return nil, err
	}

	return mr, nil
}

// copy/pasted from realtime package
func mapMessageToInteraction(data []byte) (*models.Interaction, error) {
	i := models.NewInteraction()
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
