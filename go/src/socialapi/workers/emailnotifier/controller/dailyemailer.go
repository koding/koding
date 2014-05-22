package emailnotifier

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	socialmodels "socialapi/models"
	"socialapi/workers/helper"
	"socialapi/workers/notification/models"
	"time"
)

const (
	DAY         = 24 * time.Hour
	TIMEFORMAT  = "20060102"
	CACHEPREFIX = "dailymail"
)

func (n *EmailNotifierWorkerController) saveDailyMail(accountId, activityId int64) {
	redisConn := helper.MustGetRedisConn()
	key := prepareSetterCacheKey(accountId)
	if _, err := redisConn.AddSetMembers(key, activityId); err != nil {
		n.log.Error("daily mail error: %s", err)
		return
	}

	if err := redisConn.Expire(key, DAY); err != nil {
		n.log.Error("daily mail error: %s", err)
	}
}

func (n *EmailNotifierWorkerController) sendDailyMails() {
	fmt.Println("basladi sanki")
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

func prepareSetterCacheKey(accountId int64) string {
	return fmt.Sprintf("%s:%d:%s", CACHEPREFIX, accountId, time.Now().Format(TIMEFORMAT))
}

func (n *EmailNotifierWorkerController) prepareDailyEmail(u *mongomodels.User) {
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

	containers := make([]*NotificationContainer, 0)
	for _, activityId := range activityIds {
		container, err := buildContainerForDailyMail(accountId, activityId)
		if err != nil {
			n.log.Error("error occurred while sending activity, ")
			continue
		}

		containers = append(containers, container)
	}

	// TODO change this structure
	uc, err := fetchUserContact(accountId)
	if err != nil {
		n.log.Error("an error occurred while fetching user contact: %s", err)
		return
	}

	body, err := renderDailyTemplate(uc, containers)
	if err != nil {
		n.log.Error("an error occurred while preparing notification email: %s", err)
		return
	}
	subject := "hellolay"

	if err := createToken(uc, "daily", uc.Token); err != nil {
		n.log.Error("an error occurred: %s", err)
		return
	}

	if err := n.SendMail(uc, body, subject); err != nil {
		n.log.Error("an error occurred: %s", err)
		return
	}
}

func buildContainerForDailyMail(accountId, activityId int64) (*NotificationContainer, error) {
	// TODO cache notification contents in memory
	a := models.NewNotificationActivity()
	if err := a.ById(activityId); err != nil {
		return nil, err
	}
	nc, err := a.FetchContent()
	if err != nil {
		return nil, err
	}

	return buildContainer(accountId, a, nc)

}

func (n *EmailNotifierWorkerController) getDailyActivityIds(accountId int64) ([]int64, error) {
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
