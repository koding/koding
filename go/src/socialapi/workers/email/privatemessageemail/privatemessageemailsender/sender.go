package sender

import (
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/email/emailmodels"
	"socialapi/workers/email/privatemessageemail/common"
	"strconv"
	"sync"
	"time"

	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/koding/redis"
	"github.com/robfig/cron"
	"github.com/streadway/amqp"
)

var cronJob *cron.Cron

const (
	Schedule     = "0 * * * * *"
	MessageLimit = 3
	Subject      = "Chat notifications"
	MAXROUTINES  = 4
)

type Controller struct {
	log       logging.Logger
	redisConn *redis.RedisSession
	metrics   *metrics.Metrics
	conf      *config.Config

	ready chan struct{}
}

func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred: %s", err)
	delivery.Ack(false)

	return false
}

func New(redisConn *redis.RedisSession, log logging.Logger, metrics *metrics.Metrics, conf *config.Config) (*Controller, error) {
	c := &Controller{
		log:       log,
		redisConn: redisConn,
		ready:     make(chan struct{}, 1),
		metrics:   metrics,
		conf:      conf,
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

	c.ready <- struct{}{}

	return nil
}

// Shutdown stops the cron job
func (c *Controller) Shutdown() {
	cronJob.Stop()
}

// Run send account emails in current time period
func (c *Controller) Run() {
	select {
	case <-c.ready:
		c.log.Debug("Starting next mailing period")
		c.SendEmails()
	case <-time.After(10 * time.Second):
		c.log.Critical("Need some more private message email sender workers")
		return
	}
}

func (c *Controller) SendEmails() {
	currentPeriod := common.GetCurrentMailPeriod()
	defer func() { c.ready <- struct{}{} }()

	var wg sync.WaitGroup
	for i := 0; i < MAXROUTINES; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()

			c.StartWorker(currentPeriod)
		}()
	}

	wg.Wait()

	c.log.Debug("All accounts are notified")

}

func (c *Controller) StartWorker(currentPeriod int) {
	for {
		// Fetch Account
		account, err := c.NextAccount(strconv.Itoa(currentPeriod))
		// no more pending notifications
		if err == models.ErrAccountNotFound {
			return
		}

		if err != nil {
			c.log.Error("Could not fetch account: %s", err)
			return
		}

		usercontact, err := emailmodels.FetchUserContactWithToken(account.Id)
		if err != nil {
			continue
		}

		// Fetch channel summary data
		channels, err := c.FetchChannelData(account, usercontact.LastLoginTimezoneOffset)
		if err != nil {
			c.log.Error("Could not fetch messages for rendering: %s", err)
			continue
		}

		// maybe an error occurred while fething summaries, or they are already glanced
		// who knows
		if len(channels) == 0 {
			continue
		}

		recipient, err := emailmodels.FetchUserContact(account.Id)
		if err != nil {
			continue
		}

		privatemsgchannels := []emailmodels.Message{}

		for _, channel := range channels {
			messages := []*emailmodels.PrivateMessage{}

			for _, msg := range channel.MessageSummaries {
				suffix := ""
				if msg.IsNicknameShown {
					suffix = ":"
				}

				message := &emailmodels.PrivateMessage{
					CreatedAt: msg.Time,
					Actor:     msg.Nickname + suffix,
					Message:   msg.Body,
				}

				messages = append(messages, message)
			}

			pmc := &emailmodels.PrivateMessageChannel{
				NestedMessages: messages,
				Subtitle:       channel.Link,
				ActorHash:      channel.Image,
			}
			privatemsgchannels = append(privatemsgchannels, pmc)
		}

		mailer := &emailmodels.MailerNotification{
			Hostname:         c.conf.Protocol + "//" + c.conf.Hostname,
			FirstName:        recipient.FirstName,
			Username:         recipient.Username,
			Email:            recipient.Email,
			MessageType:      "chat",
			Messages:         privatemsgchannels,
			UnsubscribeToken: recipient.Token,
		}

		if err := mailer.SendMail(); err != nil {
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
		return nil, models.ErrAccountNotFound
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
	if err := common.ResetMailingPeriodForAccount(c.redisConn, a); err != nil {
		return nil, err
	}

	return a, nil
}

func (c *Controller) FetchChannelData(a *models.Account, timezone int) ([]*emailmodels.ChannelSummary, error) {
	// fetch value from redis
	key := common.AccountChannelHashSetKey(a.Id)
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

		cs, err := c.buildChannelSummary(a, ch, awayTime, timezone)
		if err == emailmodels.ErrMessageNotFound {
			continue
		}

		if err != nil {
			c.log.Error("Could not render email channel content: %s", err)
			continue
		}

		channels = append(channels, cs)
	}

	return channels, nil
}

func (c *Controller) buildChannelSummary(a *models.Account, ch *models.Channel, awayTime time.Time, timezoneOffset int) (*emailmodels.ChannelSummary, error) {
	cs, err := emailmodels.NewChannelSummary(a, ch, awayTime, timezoneOffset)
	if err != nil {
		return nil, err
	}

	summary, err := cs.BodyContent.Render()
	if err != nil {
		return nil, err
	}

	cs.Summary = summary

	image, err := cs.RenderImage()
	if err != nil {
		return nil, err
	}

	cs.Image = image

	return cs, nil
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

	ch, err := models.Cache.Channel.ById(id)
	if err != nil {
		return nil, time.Time{}, err
	}

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
