// An hour is splitted into mailing periods. If it is 16:02, then the current time period is 2.
// Depending on this when a user receives a message in 16:02, they will be notified in 10 minutes (16:12),
// where the mailing period will be 12
// This periods are circular, which leads when the time is 16:56 next mailing period is going to be 6

// Three different redis key is needed here
// 1- AccountNextPeriod hashset: It stores next notification mailing period for each account
// 2- PeriodAccountId set: It stores notified accounts for each given time period
// 3- AccountId: stores account ChannelId:CreatedAt information for each message
package feeder

import (
	"errors"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/email/chatemail/common"
	"socialapi/workers/email/emailmodels"
	"strconv"

	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/streadway/amqp"
)

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

var eligibleToNotify = func(accountId int64) (bool, error) {
	uc, err := emailmodels.FetchUserContact(accountId)
	if err != nil {
		return false, err
	}

	if !uc.EmailSettings.Global {
		return false, nil
	}

	return uc.EmailSettings.PrivateMessage, nil
}

// AddMessageToQueue adds a new arrival message into participants notification queues
func (c *Controller) AddMessageToQueue(cm *models.ChannelMessage) error {
	if cm.TypeConstant != models.ChannelMessage_TYPE_PRIVATE_MESSAGE {
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
	nextPeriod, err := c.getAccountNextNotificationPeriod(a)
	// no awaiting notifications
	if err == ErrPeriodNotFound {
		return nil
	}

	if err != nil {
		return err
	}

	// TODO this can be taken into a MULTI execution
	count, err := c.deletePendingNotification(a, ch, nextPeriod)
	if err != nil {
		return err
	}

	// there is not any pending notification mail for the channel
	if count == 0 {
		return nil
	}

	pending, err := c.getPendingNotificationCount(a, nextPeriod)
	if err != nil {
		return err
	}

	if pending != 0 {
		return nil
	}

	// when there is not any pending notifications, just delete the account next period value
	return common.DeleteAccountNextPeriod(c.redis, a)
}

func (c *Controller) deletePendingNotification(a *models.Account, ch *models.Channel, nextPeriod string) (int, error) {
	return c.redis.DeleteHashSetField(common.AccountChannelHashSetKey(a.Id, nextPeriod), strconv.FormatInt(ch.Id, 10))
}

func (c *Controller) getPendingNotificationCount(a *models.Account, nextPeriod string) (int, error) {
	return c.redis.GetHashLength(common.AccountChannelHashSetKey(a.Id, nextPeriod))
}

func (c *Controller) fetchParticipantIds(cm *models.ChannelMessage) ([]int64, error) {
	ch := models.NewChannel()
	ch.Id = cm.InitialChannelId

	return ch.FetchParticipantIds(&request.Query{})
}

func (c *Controller) notifyAccount(accountId int64, cm *models.ChannelMessage) error {
	a := models.NewAccount()
	a.Id = accountId

	notify, err := eligibleToNotify(accountId)
	if err != nil {
		return err
	}

	if !notify {
		return nil
	}

	nextPeriod, err := c.updateAccountNextPeriodSet(a)
	if err != nil {
		return err
	}

	if err := c.updateNextPeriodSet(nextPeriod, accountId); err != nil {
		return err
	}

	return c.updateAccountChannelHashSet(nextPeriod, accountId, cm)
}

// updateAccountNextPeriodSet updates the Account-Segment hash set and returns
// the next mailing period of the account
func (c *Controller) updateAccountNextPeriodSet(a *models.Account) (string, error) {
	field := strconv.FormatInt(a.Id, 10)

	nextPeriod, err := c.getAccountNextNotificationPeriod(a)
	// if not exist get new mailing period for the account
	if err == ErrPeriodNotFound {
		nextPeriod = common.GetNextMailPeriod()
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

func (c *Controller) getAccountNextNotificationPeriod(a *models.Account) (string, error) {
	values, err := c.redis.GetHashMultipleSet(common.AccountNextPeriodHashSetKey(), a.Id)
	if err != nil {
		return "", err
	}

	if len(values) == 0 || values[0] == nil {
		return "", ErrPeriodNotFound
	}

	nextPeriod, err := c.redis.String(values[0])
	if err != nil {
		return "", err
	}

	return nextPeriod, nil
}

func (c *Controller) updateNextPeriodSet(period string, accountId int64) error {
	_, err := c.redis.AddSetMembers(common.PeriodAccountSetKey(period), strconv.FormatInt(accountId, 10))
	if err != nil {
		return err
	}

	return nil
}

func (c *Controller) updateAccountChannelHashSet(period string, accountId int64, cm *models.ChannelMessage) error {
	key := common.AccountChannelHashSetKey(accountId, period)
	channelId := strconv.FormatInt(cm.InitialChannelId, 10)
	awaySince := strconv.FormatInt(cm.CreatedAt.UnixNano(), 10)
	// add the first received message for channel
	_, err := c.redis.HashSetIfNotExists(key, channelId, awaySince)
	if err != nil {
		return err
	}

	return nil
}
