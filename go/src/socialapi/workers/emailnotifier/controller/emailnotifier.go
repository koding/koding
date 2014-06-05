package controller

import (
	"errors"
	"fmt"
	"socialapi/config"
	"socialapi/workers/emailnotifier/models"
	"socialapi/workers/helper"
	notificationmodels "socialapi/workers/notification/models"
	"time"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/koding/worker"
	"github.com/streadway/amqp"
)

var emailConfig = map[string]string{
	notificationmodels.NotificationContent_TYPE_COMMENT: "comment",
	notificationmodels.NotificationContent_TYPE_LIKE:    "likeActivities",
	notificationmodels.NotificationContent_TYPE_FOLLOW:  "followActions",
	notificationmodels.NotificationContent_TYPE_JOIN:    "groupJoined",
	notificationmodels.NotificationContent_TYPE_LEAVE:   "groupLeft",
	notificationmodels.NotificationContent_TYPE_MENTION: "mention",
}

const (
	DAY           = 24 * time.Hour
	TIMEFORMAT    = "20060102"
	CACHEPREFIX   = "dailymail"
	RECIPIENTSKEY = "recipients"
)

type Action func(*Controller, []byte) error

type Controller struct {
	routes   map[string]Action
	log      logging.Logger
	rmqConn  *amqp.Connection
	settings *models.EmailSettings
}

func (n *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	n.log.Error("an error occured: %s", err)
	delivery.Ack(false)

	return false
}

func (n *Controller) HandleEvent(event string, data []byte) error {
	n.log.Debug("New Event Received %s", event)
	handler, ok := n.routes[event]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	return handler(n, data)
}

func New(rmq *rabbitmq.RabbitMQ, log logging.Logger, es *models.EmailSettings) (*Controller, error) {
	rmqConn, err := rmq.Connect("NewEmailNotifierWorkerController")
	if err != nil {
		return nil, err
	}

	nwc := &Controller{
		log:      log,
		rmqConn:  rmqConn.Conn(),
		settings: es,
	}

	routes := map[string]Action{
		"notification.notification_created": (*Controller).SendInstantEmail,
		"notification.notification_updated": (*Controller).SendInstantEmail,
	}

	nwc.routes = routes

	return nwc, nil
}

func (n *Controller) SendInstantEmail(data []byte) error {
	channel, err := n.rmqConn.Channel()
	if err != nil {
		return errors.New("channel connection error")
	}
	defer channel.Close()

	notification := notificationmodels.NewNotification()
	if err := notification.MapMessage(data); err != nil {
		return err
	}

	// fetch latest activity for checking actor
	activity, nc, err := notification.FetchLastActivity()
	if err != nil {
		return err
	}

	if !validNotification(activity, notification) {
		return nil
	}

	uc, err := models.FetchUserContact(notification.AccountId)
	if err != nil {
		return fmt.Errorf("an error occurred while fetching user contact: %s", err)
	}

	if !n.checkMailSettings(uc, activity, nc) {
		return nil
	}

	mc := models.NewMailerContainer()
	mc.AccountId = notification.AccountId
	mc.Activity = activity
	mc.Content = nc

	if err := mc.PrepareContainer(); err != nil {
		return err
	}

	mc.CreatedAt = notification.ActivatedAt

	tp := models.NewTemplateParser()
	tp.UserContact = uc
	body, err := tp.RenderInstantTemplate(mc)
	if err != nil {
		return fmt.Errorf("an error occurred while preparing notification email: %s", err)
	}

	tg := &models.TokenGenerator{
		UserContact:      uc,
		NotificationType: emailConfig[nc.TypeConstant],
	}

	if err := tg.CreateToken(); err != nil {
		return err
	}

	mailer := models.NewMailer()
	mailer.EmailSettings = n.settings
	mailer.UserContact = uc
	mailer.Body = body
	mailer.Subject = prepareSubject(mc)

	if err := mailer.SendMail(); err != nil {
		return err
	}

	n.log.Info("%s notified by email", uc.Username)

	return nil
}

func prepareSubject(mc *models.MailerContainer) string {
	t, err := mc.Content.GetContentType()
	if err != nil {
		return ""
	}

	return t.GetDefinition()
}

func validNotification(a *notificationmodels.NotificationActivity, n *notificationmodels.Notification) bool {
	// do not notify actor for her own action
	if a.ActorId == n.AccountId {
		return false
	}

	// do not notify user when notification is not yet activated
	return !n.ActivatedAt.IsZero()
}

func (n *Controller) checkMailSettings(uc *models.UserContact, a *notificationmodels.NotificationActivity,
	nc *notificationmodels.NotificationContent) bool {
	// notifications are disabled
	if val := uc.EmailSettings.Global; !val {
		return false
	}

	notificationEnabled := checkMailSettings(nc, uc)
	// daily notifications are enabled
	if val := uc.EmailSettings.Daily; val {
		if notificationEnabled {
			go n.saveDailyMail(uc.AccountId, a.Id)
		}

		return false
	}

	// get config
	return notificationEnabled
}

func (n *Controller) saveDailyMail(accountId, activityId int64) {
	if err := saveRecipient(accountId); err != nil {
		n.log.Error("daily mail error: %s", err)
	}

	if err := saveActivity(accountId, activityId); err != nil {
		n.log.Error("daily mail error: %s", err)
	}
}

func saveRecipient(accountId int64) error {
	redisConn := helper.MustGetRedisConn()
	key := prepareRecipientsCacheKey()
	if _, err := redisConn.AddSetMembers(key, accountId); err != nil {
		return err
	}

	if err := redisConn.Expire(key, DAY); err != nil {
		return fmt.Errorf("Could not set ttl of recipients: %s", err)
	}

	return nil
}

func saveActivity(accountId, activityId int64) error {
	redisConn := helper.MustGetRedisConn()
	key := prepareSetterCacheKey(accountId)
	if _, err := redisConn.AddSetMembers(key, activityId); err != nil {
		return err
	}

	if err := redisConn.Expire(key, DAY); err != nil {
		return fmt.Errorf("Could not set ttl of activity: %s", err)
	}

	return nil
}

func checkMailSettings(nc *notificationmodels.NotificationContent, uc *models.UserContact) bool {
	switch nc.TypeConstant {
	case notificationmodels.NotificationContent_TYPE_COMMENT:
		return uc.EmailSettings.Comment
	case notificationmodels.NotificationContent_TYPE_LIKE:
		return uc.EmailSettings.Like
	case notificationmodels.NotificationContent_TYPE_FOLLOW:
		return uc.EmailSettings.Follow
	case notificationmodels.NotificationContent_TYPE_JOIN:
		return uc.EmailSettings.Join
	case notificationmodels.NotificationContent_TYPE_LEAVE:
		return uc.EmailSettings.Leave
	case notificationmodels.NotificationContent_TYPE_MENTION:
		return uc.EmailSettings.Mention
	}

	return false
}

func prepareRecipientsCacheKey() string {
	return fmt.Sprintf("%s:%s:%s:%s",
		config.Get().Environment,
		CACHEPREFIX,
		RECIPIENTSKEY,
		time.Now().Format(TIMEFORMAT))
}

func prepareSetterCacheKey(accountId int64) string {
	return fmt.Sprintf("%s:%s:%d:%s",
		config.Get().Environment,
		CACHEPREFIX,
		accountId,
		time.Now().Format(TIMEFORMAT))
}
