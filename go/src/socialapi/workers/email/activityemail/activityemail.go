package activityemail

import (
	"errors"
	"fmt"
	"socialapi/config"
	socialmodels "socialapi/models"
	"socialapi/workers/email/activityemail/models"
	"socialapi/workers/email/emailmodels"
	"socialapi/workers/email/templates"
	"socialapi/workers/helper"
	notificationmodels "socialapi/workers/notification/models"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

var emailConfig = map[string]string{
	notificationmodels.NotificationContent_TYPE_COMMENT: "comment",
	notificationmodels.NotificationContent_TYPE_LIKE:    "likeActivities",
	notificationmodels.NotificationContent_TYPE_MENTION: "mention",
}

const (
	DAY           = 24 * time.Hour
	TIMEFORMAT    = "20060102"
	CACHEPREFIX   = "dailymail"
	RECIPIENTSKEY = "recipients"

	Subject = "[Koding] You have a new %s"
)

type Controller struct {
	log     logging.Logger
	rmqConn *amqp.Connection
}

func (n *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	n.log.Error("an error occurred: %s", err)
	delivery.Ack(false)

	return false
}

func New(rmq *rabbitmq.RabbitMQ, log logging.Logger) *Controller {
	return &Controller{
		log:     log,
		rmqConn: rmq.Conn(),
	}
}

func (n *Controller) SendInstantEmail(notification *notificationmodels.Notification) error {
	channel, err := n.rmqConn.Channel()
	if err != nil {
		return errors.New("channel connection error")
	}
	defer channel.Close()

	// fetch latest activity for checking actor
	activity, nc, err := notification.FetchLastActivity()
	if err != nil {
		return err
	}

	if !n.validNotification(activity, notification) {
		return nil
	}

	uc, err := emailmodels.FetchUserContactWithToken(notification.AccountId)
	if err != nil {
		return err
	}

	// TODO: this does more than "check mail settings", it adds to daily
	// digest if user has it enabled, cut this function into two
	if !n.checkMailSettings(uc, activity, nc) {
		return nil
	}

	mc := models.NewMailerContainer()
	a := socialmodels.NewAccount()
	a.Id = notification.AccountId

	mc.AccountId = notification.AccountId
	mc.Activity = activity
	mc.Content = nc

	if err := mc.PrepareContainer(); err != nil {
		if err == bongo.RecordNotFound {
			return nil
		}
		return err
	}

	mc.CreatedAt = notification.ActivatedAt

	tp := models.NewTemplateParser()
	body, err := tp.RenderInstantTemplate(mc)
	if err != nil {
		return fmt.Errorf("an error occurred while preparing notification email: %s", err)
	}

	mailer := &emailmodels.Mailer{
		UserContact: uc,
		Information: prepareInformation(mc),
	}

	return mailer.SendMail(nc.TypeConstant, body, prepareSubject(mc))
}

func prepareSubject(mc *models.MailerContainer) string {
	t, err := mc.Content.GetContentType()
	if err != nil {
		return ""
	}

	return fmt.Sprintf(Subject, t.GetDefinition())
}

func prepareInformation(mc *models.MailerContainer) string {
	t, err := mc.Content.GetContentType()
	if err != nil {
		return ""
	}

	return fmt.Sprintf("You have a new %s on %s.", t.GetDefinition(), templates.KodingLink)
}

func (c *Controller) validNotification(a *notificationmodels.NotificationActivity, n *notificationmodels.Notification) bool {
	// do not notify actor for her own action
	if a.ActorId == n.AccountId {
		return false
	}

	// do not notify actor for troll activity
	acc, err := socialmodels.FetchAccountById(a.ActorId)
	if err != nil {
		c.log.Error("Invalid notification: %s", err)
		return false
	}

	if acc.IsTroll {
		return false
	}

	// do not notify user when notification is not yet activated
	return !n.ActivatedAt.IsZero()
}

func (n *Controller) checkMailSettings(uc *emailmodels.UserContact, a *notificationmodels.NotificationActivity,
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

func checkMailSettings(nc *notificationmodels.NotificationContent, uc *emailmodels.UserContact) bool {
	switch nc.TypeConstant {
	case notificationmodels.NotificationContent_TYPE_COMMENT:
		return uc.EmailSettings.Comment
	case notificationmodels.NotificationContent_TYPE_LIKE:
		return uc.EmailSettings.Like
	case notificationmodels.NotificationContent_TYPE_MENTION:
		return uc.EmailSettings.Mention
	case notificationmodels.NotificationContent_TYPE_PM:
		return uc.EmailSettings.PrivateMessage
	}

	return false
}

func prepareRecipientsCacheKey() string {
	return fmt.Sprintf("%s:%s:%s:%s",
		config.MustGet().Environment,
		CACHEPREFIX,
		RECIPIENTSKEY,
		time.Now().Format(TIMEFORMAT))
}

func prepareSetterCacheKey(accountId int64) string {
	return fmt.Sprintf("%s:%s:%d:%s",
		config.MustGet().Environment,
		CACHEPREFIX,
		accountId,
		time.Now().Format(TIMEFORMAT))
}
