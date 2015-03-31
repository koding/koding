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
	ErrMigrated     = errors.New("already migrated")
	kodingChannelId int64
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

	mwc.migrateAllAccountsToAlgolia()

	mwc.GrantPublicAccess()

	mwc.log.Notice("Migration finished")

	mwc.ready <- true
}

func (mwc *Controller) AccountIdByOldId(oldId string) (int64, error) {
	id := models.FetchAccountIdByOldId(oldId)
	if id != 0 {
		return id, nil
	}

	acc, err := modelhelper.GetAccountById(oldId)
	if err != nil {
		return 0, fmt.Errorf("Participant account %s cannot be fetched: %s", oldId, err)
	}

	id, err = models.AccountIdByOldId(oldId, acc.Profile.Nickname)
	if err != nil {
		mwc.log.Warning("Could not update cache for %s: %s", oldId, err)
	}

	return id, nil
}
