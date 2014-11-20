package sender

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/email/chatemail/common"
	"socialapi/workers/email/emailmodels"
	"strconv"
	"time"

	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/robfig/cron"
	"github.com/streadway/amqp"
)

var cronJob *cron.Cron

const (
	Schedule     = "0 * * * * *"
	MessageLimit = 3
	Subject      = "[Koding] Chat notifications for %s"
	DateLayout   = "Jan 2, 2006"
)

type Controller struct {
	log       logging.Logger
	redisConn *redis.RedisSession
	settings  *emailmodels.EmailSettings
}

func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred: %s", err)
	delivery.Ack(false)

	return false
}

func New(redisConn *redis.RedisSession, log logging.Logger, es *emailmodels.EmailSettings) (*Controller, error) {
	c := &Controller{
		log:       log,
		redisConn: redisConn,
		settings:  es,
	}

	return c, c.initCron()
}

// initCron initializes the cron job with given schedule, and Send closure
func (c *Controller) initCron() error {
	cronJob = cron.New()
	if err := cronJob.AddFunc(Schedule, c.Run); err != nil {
		return err
	}

	cronJob.Start()

	return nil
}

// Shutdown stops the cron job
func (c *Controller) Shutdown() {
	cronJob.Stop()
}

// Run send account emails in current time period
func (c *Controller) Run() {
	currentPeriod := common.GetCurrentMailPeriod()

	for {
		// Fetch Account
		account, err := c.NextAccount(strconv.Itoa(currentPeriod))
		// no more pending notifications
		if err == models.ErrAccountNotFound {
			c.log.Info("All accounts are notified")
			return
		}

		if err != nil {
			c.log.Error("Could not fetch account: %s", err)
			return
		}

		// Fetch hannel data
		channels, err := c.FetchChannelSummaries(account, strconv.Itoa(currentPeriod))
		if err != nil {
			c.log.Error("Could not fetch messages for rendering: %s", err)
			continue
		}

		// maybe an error occurred while fething summaries, or they are already glanced
		// who knows
		if len(channels) == 0 {
			continue
		}

		// Decorate channel data
		es := emailmodels.NewEmailSummary(channels)

		// Render body
		body, err := es.Render()
		if err != nil {
			c.log.Error("Could not render body for account %d: %s", account.Id, err)
		}

		// Send
		subject := fmt.Sprintf(Subject, time.Now().Format(DateLayout))
		mailer, err := emailmodels.NewMailer(account, body, subject, c.settings)
		if err != nil {
			c.log.Error("Could not create mailer for account %d: %s", account.Id, err)
			continue
		}

		if err := mailer.SendMail("chat"); err != nil {
			c.log.Error("Could not send email for account: %d: %s", account.Id, err)
		}
	}

}

// NextAccount pops a random account element from set, deletes its next period
// from AccountNextPeriod hash set and returns the popped account
func (c *Controller) NextAccount(period string) (*models.Account, error) {
	key := common.PeriodAccountSetKey(period)
	val, err := c.redisConn.PopSetMember(key)
	if err == redis.ErrNil {
		return nil, ErrAccountNotFound
	}

	if err != nil {
		return nil, err
	}

	accountId, err := strconv.ParseInt(val, 10, 64)
	if err != nil {
		return nil, err
	}
	a := models.NewAccount()
	a.Id = accountId

	// directyle delete it from AccountNextPeriod hash set for sending further e-mails
	if err := common.DeleteAccountNextPeriod(c.redisConn, a); err != nil {
		return nil, err
	}

	return a, nil
}

func (c *Controller) FetchChannelSummaries(a *models.Account, period string) ([]*emailmodels.ChannelSummary, error) {
	// fetch value from redis
	key := common.AccountChannelHashSetKey(a.Id, period)
	defer func() {
		if _, err := c.redisConn.Del(key); err != nil {
			c.log.Error("Could not delete pending channels for account", err)
		}
	}()

	channels := make([]*emailmodels.ChannelSummary, 0)
	vals, err := c.redisConn.HashGetAll(key)
	if err != nil {
		return channels, err
	}

	// maybe all channels are already glanced
	if len(vals) == 0 {
		return channels, nil
	}

	for i := 0; i < len(vals); i += 2 {
		ch, awayTime, err := c.parseValues(vals[i], vals[i+1])
		if err != nil {
			c.log.Error("Could not fetch channel messages: %s", err)
			continue
		}

		cs, err := emailmodels.NewChannelSummary(a, ch, awayTime)
		if err != nil {
			c.log.Error("Could not decorate channel summary: %s", err)
			continue
		}

		channels = append(channels, cs)
	}

	return channels, nil
}

func (c *Controller) parseValues(field, value interface{}) (*models.Channel, time.Time, error) {
	// string value of channelId
	channelId, err := c.redisConn.String(field)
	if err != nil {
		return nil, time.Time{}, err
	}

	// convert channel id to int64
	id, err := strconv.ParseInt(channelId, 10, 64)
	if err != nil {
		return nil, time.Time{}, err
	}

	ch := models.NewChannel()
	ch.Id = id

	awaySince, err := c.redisConn.String(value)
	if err != nil {
		return nil, time.Time{}, err
	}

	awayTime, err := strconv.ParseInt(awaySince, 10, 64)
	if err != nil {
		return nil, time.Time{}, err
	}

	t := time.Unix(0, awayTime)

	return ch, t, nil
}
