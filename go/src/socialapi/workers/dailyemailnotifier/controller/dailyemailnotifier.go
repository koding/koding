package controller

import (
	"errors"
	"fmt"
	"socialapi/config"
	"socialapi/workers/emailnotifier/models"
	"socialapi/workers/helper"
	notificationmodels "socialapi/workers/notification/models"
	"strconv"
	"time"

	"github.com/garyburd/redigo/redis"
	"github.com/koding/logging"
	"github.com/robfig/cron"
)

const (
	DAY           = 24 * time.Hour
	TIMEFORMAT    = "20060102"
	DATEFORMAT    = "Jan 02"
	CACHEPREFIX   = "dailymail"
	RECIPIENTSKEY = "recipients"
	SCHEDULE      = "0 0 0 * * *"
)

type Controller struct {
	log      logging.Logger
	settings *models.EmailSettings
}

var ObsoleteActivity = errors.New("obsolete activity")

var (
	cronJob *cron.Cron
)

func New(log logging.Logger, es *models.EmailSettings) (*Controller, error) {

	c := &Controller{
		log:      log,
		settings: es,
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
	redisConn := helper.MustGetRedisConn()
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
	uc, err := models.FetchUserContact(accountId)
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
			if err != ObsoleteActivity {
				n.log.Error("error occurred while sending activity: %s ", err)
			}
			continue
		}

		containers = append(containers, container)
	}

	if len(containers) == 0 {
		return nil
	}

	tp := models.NewTemplateParser()
	tp.UserContact = uc
	body, err := tp.RenderDailyTemplate(containers)
	if err != nil {
		return fmt.Errorf("an error occurred while preparing notification email: %s", err)
	}

	tg := models.NewTokenGenerator()
	tg.UserContact = uc
	tg.NotificationType = "daily"
	if err := tg.CreateToken(); err != nil {
		return fmt.Errorf("an error occurred: %s", err)
	}

	mailer := models.NewMailer()
	mailer.EmailSettings = n.settings
	mailer.UserContact = uc
	mailer.Body = body
	mailer.Subject = fmt.Sprintf("Your Koding Activity for today: %s",
		time.Now().Format(DATEFORMAT))

	if err := mailer.SendMail(); err != nil {
		return fmt.Errorf("an error occurred: %s", err)
	}

	return nil
}

func (n *Controller) getDailyActivityIds(accountId int64) ([]int64, error) {
	redisConn := helper.MustGetRedisConn()
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
