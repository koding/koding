package dailyemail

import (
	"errors"
	"fmt"
	"socialapi/config"
	"socialapi/workers/email/activityemail/models"
	"socialapi/workers/email/emailmodels"
	notificationmodels "socialapi/workers/notification/models"
	"strconv"
	"time"

	"github.com/garyburd/redigo/redis"
	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/runner"
	"github.com/robfig/cron"
)

const (
	DAY           = 24 * time.Hour
	TIMEFORMAT    = "20060102"
	DATEFORMAT    = "Jan 02"
	CACHEPREFIX   = "dailymail"
	RECIPIENTSKEY = "recipients"
	SCHEDULE      = "0 0 0 * * *"

	Subject     = "DailyDigest"
	Information = "Here is what happened on Koding.com today!"
)

type Controller struct {
	log    logging.Logger
	config *config.Config
}

var ObsoleteActivity = errors.New("obsolete activity")

var (
	cronJob *cron.Cron
)

func New(log logging.Logger, conf *config.Config) (*Controller, error) {

	c := &Controller{
		log:    log,
		config: conf,
	}

	return c, c.initDailyEmailCron()
}

func (n *Controller) initDailyEmailCron() error {
	cronJob = cron.New()
	err := cronJob.AddFunc(SCHEDULE, n.sendDailyMails)
	if err != nil {
		return err
	}
	cronJob.Start()

	return nil
}

func (n *Controller) Shutdown() {
	cronJob.Stop()
}

func (n *Controller) sendDailyMails() {
	redisConn := runner.MustGetRedisConn()
	for {
		key := prepareRecipientsCacheKey()
		reply, err := redisConn.PopSetMember(key)
		if err == redis.ErrNil {
			n.log.Info("all daily mails are sent")
			return
		}
		if err != nil {
			n.log.Error("Could not fetch recipient %s", err)
			return
		}

		accountId, err := strconv.ParseInt(reply, 10, 64)
		if err != nil {
			n.log.Error("Could not cast recipient id: %s", err)
			continue
		}

		if err := n.prepareDailyEmail(accountId); err != nil {
			n.log.Error("error occurred: %s", err)
		}
	}
}

func (n *Controller) prepareDailyEmail(accountId int64) error {
	uc, err := emailmodels.FetchUserContactWithToken(accountId)
	if err != nil {
		return err
	}

	// notifications are disabled
	if val := uc.EmailSettings.Global; !val {
		return nil
	}

	activityIds, err := n.getDailyActivityIds(accountId)
	if err != nil {
		return fmt.Errorf("Could not fetch activity ids: %s", err)
	}

	if len(activityIds) == 0 {
		return nil
	}

	containers := make([]*models.MailerContainer, 0)
	for _, activityId := range activityIds {
		container, err := buildContainerForDailyMail(accountId, activityId)
		if err != nil {
			if err != ObsoleteActivity && err != bongo.RecordNotFound {
				n.log.Error("error occurred while sending activity: %s ", err)
			}

			continue
		}

		containers = append(containers, container)
	}

	if len(containers) == 0 {
		return nil
	}

	hostname := n.config.Protocol + "//" + n.config.Hostname
	messages := []emailmodels.Message{}

	for _, container := range containers {
		actor, err := emailmodels.FetchUserContactWithToken(container.Activity.ActorId)
		if err != nil {
			return err
		}

		message := &emailmodels.NotificationMessage{
			Actor:          actor.FirstName,
			ActorHash:      actor.Hash,
			CreatedAt:      container.CreatedAt,
			Message:        container.Message,
			Action:         container.ActivityMessage,
			ActionType:     container.ObjectType,
			TimezoneOffset: uc.LastLoginTimezoneOffset,
			Hostname:       hostname,
			MessageSlug:    container.Slug,
		}

		messages = append(messages, message)
	}

	mailer := &emailmodels.MailerNotification{
		Hostname:         hostname,
		FirstName:        uc.FirstName,
		Username:         uc.Username,
		Email:            uc.Email,
		MessageType:      "dailydigest",
		Messages:         messages,
		UnsubscribeToken: uc.Token,
	}

	return mailer.SendMail()
}

func (n *Controller) getDailyActivityIds(accountId int64) ([]int64, error) {
	redisConn := runner.MustGetRedisConn()
	members, err := redisConn.GetSetMembers(prepareDailyActivitiesCacheKey(accountId))
	if err != nil {
		return nil, err
	}

	activityIds := make([]int64, len(members))
	for i, member := range members {
		activityId, err := redisConn.Int64(member)
		if err != nil {
			n.log.Error("Could not get activity id: %s", err)
			continue
		}

		activityIds[i] = activityId
	}

	redisConn.Del(prepareDailyActivitiesCacheKey(accountId))

	return activityIds, nil
}

func prepareRecipientsCacheKey() string {
	return fmt.Sprintf("%s:%s:%s:%s",
		config.MustGet().Environment,
		CACHEPREFIX,
		RECIPIENTSKEY,
		preparePreviousDayCacheKey())
}

func prepareDailyActivitiesCacheKey(accountId int64) string {
	return fmt.Sprintf("%s:%s:%d:%s",
		config.MustGet().Environment,
		CACHEPREFIX,
		accountId,
		preparePreviousDayCacheKey())
}

func preparePreviousDayCacheKey() string {
	return time.Now().Add(-time.Hour * 24).Format(TIMEFORMAT)
}

func buildContainerForDailyMail(accountId, activityId int64) (*models.MailerContainer, error) {
	a := notificationmodels.NewNotificationActivity()
	if err := a.ById(activityId); err != nil {
		return nil, err
	}

	nc, err := a.FetchContent()
	if err != nil {
		return nil, err
	}

	if a.Obsolete && nc.TypeConstant != notificationmodels.NotificationContent_TYPE_COMMENT {
		return nil, ObsoleteActivity
	}

	mc := models.NewMailerContainer()
	mc.AccountId = accountId
	mc.Activity = a
	mc.Content = nc

	if err := mc.PrepareContainer(); err != nil {
		return nil, err
	}

	return mc, nil
}
