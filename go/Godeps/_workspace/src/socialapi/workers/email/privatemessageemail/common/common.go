package common

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"strconv"

	"github.com/koding/redis"
)

const (
	CachePrefix = "privatemessagenotifier"
	MailPeriod  = 1 // minute
)

func AccountNextPeriodHashSetKey() string {
	return fmt.Sprintf("%s:%s:%s",
		config.MustGet().Environment,
		CachePrefix,
		"account-nextperiod",
	)
}

func PeriodAccountSetKey(period string) string {
	return fmt.Sprintf("%s:%s:%s:%s",
		config.MustGet().Environment,
		CachePrefix,
		"periodaccountset",
		period,
	)
}

func AccountChannelHashSetKey(accountId int64) string {
	return fmt.Sprintf("%s:%s:%s:%d",
		config.MustGet().Environment,
		CachePrefix,
		"account-channelhashset",
		accountId,
	)
}

// getNextMailPeriod returns the next mailing period
func GetNextMailPeriod(delayInMinutes int) string {
	nextPeriod := GetCurrentMailPeriod()
	segment := (nextPeriod + delayInMinutes) % (60 / MailPeriod)

	return strconv.Itoa(segment)
}

func GetCurrentMailPeriod() int {
	ts := models.NewTimeSegmentor(MailPeriod)

	nextPeriod, _ := strconv.Atoi(ts.GetNextSegment())

	return nextPeriod
}

func ResetMailingPeriodForAccount(redisConn *redis.RedisSession, a *models.Account) error {
	_, err := redisConn.DeleteHashSetField(AccountNextPeriodHashSetKey(), strconv.FormatInt(a.Id, 10))

	return err
}
