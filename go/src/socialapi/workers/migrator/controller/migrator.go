package controller

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	realtimemodels "socialapi/workers/realtime/models"

	"github.com/koding/logging"
	"github.com/robfig/cron"
)

const SCHEDULE = "0 */5 * * * *"

var (
	ErrMigrated = errors.New("already migrated")
)

type Controller struct {
	log     logging.Logger
	pubnub  *realtimemodels.PubNub
	cronJob *cron.Cron
	ready   chan bool
}

func New(log logging.Logger, pubnub *realtimemodels.PubNub) (*Controller, error) {

	wc := &Controller{
		log:    log,
		pubnub: pubnub,
		ready:  make(chan bool, 1),
	}

	return wc, nil
}

func (mwc *Controller) Schedule() error {
	mwc.cronJob = cron.New()
	mwc.ready <- true
	err := mwc.cronJob.AddFunc(SCHEDULE, mwc.CronStart)
	if err != nil {
		return err
	}
	mwc.cronJob.Start()

	return nil
}

func (mwc *Controller) Shutdown() {
	mwc.cronJob.Stop()
}

func (mwc *Controller) CronStart() {
	select {
	case <-mwc.ready:
		mwc.Start()
	default:
		mwc.log.Debug("Ongoing migration process")
	}
}

func (mwc *Controller) Start() {
	mwc.log.Notice("Migration started")

	mwc.migrateAllAccounts()

	mwc.migrateAllGroups()

	mwc.createPublicChannel()

	mwc.createChangelogChannel()

	mwc.GrantPublicAccess()

	mwc.CreateBotUser()

	mwc.log.Notice("Migration finished")

	mwc.ready <- true
}

func (mwc *Controller) AccountIdByOldId(oldId string) (int64, error) {
	acc, err := models.Cache.Account.ByOldId(oldId)
	if err == nil {
		return acc.Id, nil
	}

	acc1, err := modelhelper.GetAccountById(oldId)
	if err != nil {
		return 0, fmt.Errorf("Participant account %s cannot be fetched: %s", oldId, err)
	}

	a := models.NewAccount()
	a.OldId = oldId
	a.Nick = acc1.Profile.Nickname
	if err := a.FetchOrCreate(); err != nil {
		return 0, err
	}

	if err := models.Cache.Account.SetToCache(a); err != nil {
		return 0, err
	}

	return a.Id, nil
}

func (mwc *Controller) CreateBotUser() {
	mwc.log.Notice("Creating bot user")
	_, err := models.CreateAccountInBothDbsWithNick("bot")
	if err != nil {
		mwc.log.Error("Could not create bot account")
	}
}
