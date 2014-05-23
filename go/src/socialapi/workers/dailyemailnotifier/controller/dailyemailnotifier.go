package controller

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	socialmodels "socialapi/models"
	"socialapi/workers/emailnotifier/models"
	"socialapi/workers/helper"
	notificationmodels "socialapi/workers/notification/models"
	"time"

	"github.com/koding/logging"
	"github.com/robfig/cron"
)

const (
	DAY         = 24 * time.Hour
	TIMEFORMAT  = "20060102"
	CACHEPREFIX = "dailymail"
	SCHEDULE    = "0 0 0 * * *"
)

type DailyEmailNotifierWorkerController struct {
	log      logging.Logger
	settings *models.EmailSettings
}

var cronJob *cron.Cron

func NewDailyEmailNotifierWorkerController(
	log logging.Logger,
	es *models.EmailSettings) (*DailyEmailNotifierWorkerController, error) {

	c := &DailyEmailNotifierWorkerController{
		log:      log,
		settings: es,
	}

	return c, c.initDailyEmailCron()
}

func (n *DailyEmailNotifierWorkerController) initDailyEmailCron() error {
	cronJob = cron.New()
	err := cronJob.AddFunc(SCHEDULE, n.sendDailyMails)
	if err != nil {
		return err
	}

	cronJob.Start()

	return nil
}

func (n *DailyEmailNotifierWorkerController) Shutdown() {
	cronJob.Stop()
}

func (n *DailyEmailNotifierWorkerController) sendDailyMails() {
	s := modelhelper.Selector{
		"emailFrequency.daily": true,
	}

	users, err := modelhelper.GetSomeUsersBySelector(s)
	if err != nil {
		n.log.Error("Could not retrieved daily mail requesters: %s", err)
	}

	for i := range users {
		go n.prepareDailyEmail(&users[i])
	}
}

func (n *DailyEmailNotifierWorkerController) prepareDailyEmail(u *mongomodels.User) {
	// notifications are disabled
	if val := u.EmailFrequency["global"]; !val {
		return
	}

	accountId, err := fetchAccountId(u)
	if err != nil {
		// n.log.Error("%s", err)
		return
	}

	activityIds, err := n.getDailyActivityIds(accountId)
	if err != nil {
		n.log.Error("Could not fetch activity ids: %s", err)
		return
	}

	if len(activityIds) == 0 {
		return
	}

	containers := make([]*models.MailerContainer, 0)
	for _, activityId := range activityIds {
		container, err := buildContainerForDailyMail(accountId, activityId)
		if err != nil {
			n.log.Error("error occurred while sending activity, ")
			continue
		}

		containers = append(containers, container)
	}

	// TODO change this structure
	uc, err := models.FetchUserContact(accountId)
	if err != nil {
		n.log.Error("an error occurred while fetching user contact: %s", err)
		return
	}

	tp := models.NewTemplateParser()
	tp.UserContact = uc
	body, err := tp.RenderDailyTemplate(containers)
	if err != nil {
		n.log.Error("an error occurred while preparing notification email: %s", err)
		return
	}

	tg := models.NewTokenGenerator()
	tg.UserContact = uc
	tg.NotificationType = "daily"
	if err := tg.CreateToken(); err != nil {
		n.log.Error("an error occurred: %s", err)
		return
	}

	mailer := models.NewMailer()
	mailer.EmailSettings = n.settings
	mailer.UserContact = uc
	mailer.Body = body
	mailer.Subject = "hellolay" // change subject

	if err := mailer.SendMail(); err != nil {
		n.log.Error("an error occurred: %s", err)
		return
	}
}

func fetchAccountId(u *mongomodels.User) (int64, error) {
	a, err := modelhelper.GetAccount(u.Name)
	if err != nil {
		return 0, fmt.Errorf("Could not send daily mail to %s: %s", u.Name, err)
	}

	account := socialmodels.NewAccount()
	account.OldId = a.Id.Hex()
	if err := account.FetchByOldId(); err != nil {
		return 0, err
	}

	return account.Id, err
}

func (n *DailyEmailNotifierWorkerController) getDailyActivityIds(accountId int64) ([]int64, error) {
	redisConn := helper.MustGetRedisConn()
	members, err := redisConn.GetSetMembers(prepareGetterCacheKey(accountId))
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

func prepareGetterCacheKey(accountId int64) string {
	// previous day
	yesterday := time.Now().Unix() //- 86400 TODO do not forget

	return fmt.Sprintf("%s:%d:%s",
		CACHEPREFIX, accountId, time.Unix(int64(yesterday), 0).Format(TIMEFORMAT))
}

func buildContainerForDailyMail(accountId, activityId int64) (*models.MailerContainer, error) {
	// TODO cache notification contents in memory
	a := notificationmodels.NewNotificationActivity()
	if err := a.ById(activityId); err != nil {
		return nil, err
	}
	nc, err := a.FetchContent()
	if err != nil {
		return nil, err
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
