// An hour is splitted into mailing periods. If it is 16:02, then the current time period is 2.
// Depending on this when a user receives a message in 16:02, they will be notified in 10 minutes (16:12),
// where the mailing period will be 12
// This periods are circular, which leads when the time is 16:56 next mailing period is going to be 6

// Three different redis key is needed here
// 1- AccountNextPeriod hashset (AccountMailingPeriod): It stores notification mailing period for each account
// 2- PeriodAccountId set (Notifiee Queue): It stores notified accounts for each given time period
// 3- AccountId (AccountChannelNotifications): stores account ChannelId:CreatedAt information for each message
package feeder

import (
	"errors"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/email/emailmodels"
	"socialapi/workers/email/privatemessageemail/common"
	"strconv"

	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/streadway/amqp"
)

// delay in minutes
const DefaultMailDelay = 5

var (
	ErrInvalidPeriod  = errors.New("invalid period")
	ErrPeriodNotFound = errors.New("period not found")
)

type Controller struct {
	log   logging.Logger
	redis *redis.RedisSession
}

func New(log logging.Logger, redis *redis.RedisSession) *Controller {
	return &Controller{
		log:   log,
		redis: redis,
	}
}

func (n *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	n.log.Error("an error occurred: %s", err)
	delivery.Ack(false)

	return false
}

var isEligibleToNotify = func(accountId int64) (bool, int, error) {
	uc, err := emailmodels.FetchUserContact(accountId)
	if err != nil {
		return false, 0, err
	}

	if !uc.EmailSettings.Global {
		return false, 0, nil
	}

	delay, err := strconv.Atoi(uc.EmailSettings.NotificationDelay)
	if err != nil {
		delay = DefaultMailDelay
	}

	return uc.EmailSettings.PrivateMessage, delay, nil
}

// AddMessageToQueue adds a new arrival message into participants notification queues
func (c *Controller) AddMessageToQueue(cm *models.ChannelMessage) error {
	if cm.TypeConstant != models.ChannelMessage_TYPE_PRIVATE_MESSAGE {
		return nil
	}

	// return when user is troll
	if cm.MetaBits.Is(models.Troll) {
		return nil
	}

	// TODO later on fetch this from cache.
	participantIds, err := c.fetchParticipantIds(cm)
	if err != nil {
		return err
	}

	for _, participantId := range participantIds {
		if participantId == cm.AccountId {
			continue
		}

		if err := c.notifyAccount(participantId, cm); err != nil {
			c.log.Error("Could not add message %d to queue for account %d: %s", cm.Id, participantId, err)
		}

	}

	return nil
}

// GlanceChannel removes a channel from awaiting notification channel hash set and
// when none other channels are awaiting resets Account information from AccountPeriod hash
func (c *Controller) GlanceChannel(cp *models.ChannelParticipant) error {
	a := models.NewAccount()
	a.Id = cp.AccountId

	ch := models.NewChannel()
	ch.Id = cp.ChannelId

	hasPendingNotification, err := c.deletePendingNotifications(a, ch)
	if err != nil {
		return err
	}

	// there is not any pending notification mail for the channel
	if !hasPendingNotification {
		return nil
	}

	hasUnglancedChannels, err := c.hasUnglancedChannels(a)
	if err != nil {
		return err
	}

	if hasUnglancedChannels {
		return nil
	}

	// when there is not any pending notifications (unglanced active channels),
	// just reset the account mailing period value
	return common.ResetMailingPeriodForAccount(c.redis, a)
}

// deletePendingNotification deletes notification information for given account, and channel. It returns
// true when there are pending notifications, false otherwise
func (c *Controller) deletePendingNotifications(a *models.Account, ch *models.Channel) (bool, error) {
	count, err := c.redis.DeleteHashSetField(common.AccountChannelHashSetKey(a.Id), strconv.FormatInt(ch.Id, 10))
	if err != nil {
		return false, err
	}

	return count == 1, nil
}

func (c *Controller) hasUnglancedChannels(a *models.Account) (bool, error) {
	count, err := c.redis.GetHashLength(common.AccountChannelHashSetKey(a.Id))
	if err != nil {
		return false, err
	}

	return count > 0, nil
}

func (c *Controller) fetchParticipantIds(cm *models.ChannelMessage) ([]int64, error) {
	ch := models.NewChannel()
	ch.Id = cm.InitialChannelId

	return ch.FetchParticipantIds(&request.Query{})
}

func (c *Controller) notifyAccount(accountId int64, cm *models.ChannelMessage) error {
	a := models.NewAccount()
	a.Id = accountId

	eligible, delay, err := isEligibleToNotify(accountId)
	if err != nil {
		return err
	}

	if !eligible {
		return nil
	}

	if delay == 0 {
		delay = DefaultMailDelay
	}

	nextPeriod, err := c.getOrCreateMailingPeriod(a, delay)
	if err != nil {
		return err
	}

	if err := c.addAccountToNotifieeQueue(nextPeriod, accountId); err != nil {
		return err
	}

	return c.addMessageToAccountChannelNotifications(accountId, cm)
}

// getOrCreateMailingPeriod updates the Account-Segment hash set and returns
// the next mailing period of the account depending on given delayInMonutes
func (c *Controller) getOrCreateMailingPeriod(a *models.Account, delayInMinutes int) (string, error) {
	field := strconv.FormatInt(a.Id, 10)

	nextPeriod, err := c.getMailingPeriod(a)
	// if not exist get new mailing period for the account
	if err == ErrPeriodNotFound {
		nextPeriod = common.GetNextMailPeriod(delayInMinutes)
		err := c.redis.HashMultipleSet(common.AccountNextPeriodHashSetKey(), map[string]interface{}{field: nextPeriod})
		if err != nil {
			return "", err
		}

		return nextPeriod, nil
	}

	if err != nil {
		return "", err
	}

	return nextPeriod, nil
}

func (c *Controller) getMailingPeriod(a *models.Account) (string, error) {
	period, err := c.redis.GetHashSetField(common.AccountNextPeriodHashSetKey(), strconv.FormatInt(a.Id, 10))
	if err == redis.ErrNil {
		return "", ErrPeriodNotFound
	}

	if err != nil {
		return "", err
	}

	if period == "" {
		return "", ErrPeriodNotFound
	}

	return period, nil
}

func (c *Controller) addAccountToNotifieeQueue(period string, accountId int64) error {
	_, err := c.redis.AddSetMembers(common.PeriodAccountSetKey(period), strconv.FormatInt(accountId, 10))
	if err != nil {
		return err
	}

	return nil
}

func (c *Controller) addMessageToAccountChannelNotifications(accountId int64, cm *models.ChannelMessage) error {
	// TODO instead of using cm.InitialChannelId i have tried fetching related channel
	// from channel message list, but this relationships is created after the reception
	// of ChannelMessageCreated event.
	//
	// cml := models.NewChannelMessageList()
	// ids, err := cml.FetchMessageChannelIds(cm.Id)
	// if err != nil {
	// 	return err
	// }

	// if len(ids) == 0 {
	// 	return models.ErrChannelNotFound
	// }

	key := common.AccountChannelHashSetKey(accountId)
	// TODO in the future when we notify accounts for public channels, instead of ids[0] parameter,
	// we will need some logic
	channelId := strconv.FormatInt(cm.InitialChannelId, 10)
	awaySince := strconv.FormatInt(cm.CreatedAt.UnixNano(), 10)
	// add the first received message for channel
	_, err := c.redis.HashSetIfNotExists(key, channelId, awaySince)
	if err != nil {
		return err
	}

	return nil
}
