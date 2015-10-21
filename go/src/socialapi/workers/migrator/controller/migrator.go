package controller

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	webhookmodels "socialapi/workers/integration/webhook"
	realtimemodels "socialapi/workers/realtime/models"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
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

	mwc.migrateAllAccountsToAlgolia()

	mwc.GrantPublicAccess()

	mwc.EnsureIntegrations()

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

// describeIntegrations describe all integrations in this func.
// firstly, fills all fields for each integrations and assign each integration to the
// integration array, and then sends this array to the 'EnsureIntegrations' to create in db
//
// DO NOT delete any integration from here. Just edit integration fields.
// You can update the properties , changes will be updated automatically,
// if you want to delete any integration, only set 'isPublished' field as 'false'.
func (mwc *Controller) describeIntegrations() ([]*webhookmodels.Integration, error) {
	var integrations []*webhookmodels.Integration

	// Github Creation
	githubInt := webhookmodels.NewIntegration()
	githubInt.Title = "GitHub"
	githubInt.Name = "github"
	githubInt.Summary = "Source control and code management."
	githubInt.IconPath = "https://koding-cdn.s3.amazonaws.com/temp-images/github.png"
	githubInt.Description = "GitHub offers online source code hosting for Git projects, with powerful collaboration, code review, and issue tracking. \n \n This integration will post commits, pull requests, and activity on GitHub Issues to a channel in Koding."
	githubInt.TypeConstant = webhookmodels.Integration_TYPE_INCOMING
	githubInt.Instructions = `
#### Step 1

In your GitHub account, go to the repository that you'd like to monitor. Click on the **Settings** tab in the right navigation.

![github_step1.png](https://koding-cdn.s3.amazonaws.com/temp-images/airbrake_step1.png)


#### Step 2

Click on **Webhooks & Services** in the left navigation, and then press the **Add webhook** button.

![airbrake_step2.png](https://koding-cdn.s3.amazonaws.com/temp-images/airbrake_step2.png)

`
	githubInt.Settings = gorm.Hstore{}

	events := webhookmodels.NewEvents(
		webhookmodels.NewEvent("push", "Commits pushed to the repository"),
		webhookmodels.NewEvent("commit_comment", "New comment on commit"),
		webhookmodels.NewEvent("pull_request", "Pull request opened or closed"),
		webhookmodels.NewEvent("issues", "Issues opened or closed"),
		webhookmodels.NewEvent("issue_comment", "New comment on issue"),
		webhookmodels.NewEvent("deployment_status", "Show deployment statuses"),
		webhookmodels.NewEvent("create", "Branch or tag created"),
		webhookmodels.NewEvent("delete", "Branch or tag deleted"),
		webhookmodels.NewEvent("pull_request_review_comment", "New comment on pull request"),
	)

	githubInt.AddSettings("authorizable", true)

	githubInt.AddEvents(events)

	integrations = append(integrations, githubInt)

	// Travis Creation
	travisInt := webhookmodels.NewIntegration()
	travisInt.Title = "Travis CI"
	travisInt.Name = "travis"
	travisInt.Summary = "Hosted software build services."
	travisInt.IconPath = "https://koding-cdn.s3.amazonaws.com/temp-images/travisci.png"
	travisInt.Description = "Travis CI is a continuous integration platform that takes care of running your software tests and deploying your apps. This integration will allow your team to receive notifications in Koding for normal branch builds, and for pull requests, as well."
	travisInt.TypeConstant = webhookmodels.Integration_TYPE_INCOMING
	travisInt.IsPublished = false

	integrations = append(integrations, travisInt)

	// Pivotal Creation
	pivotalInt := webhookmodels.NewIntegration()
	pivotalInt.Title = "Pivotal Tracker"
	pivotalInt.Name = "pivotal"
	pivotalInt.Summary = "Collaborative, lightweight agile project management."
	pivotalInt.IconPath = "https://koding-cdn.s3.amazonaws.com/temp-images/pivotaltracker.png"
	pivotalInt.Description = "Pivotal Tracker is an agile project management tool that shows software teams their work in progress and allows them to track upcoming milestones. This integration will post updates to a channel in Koding whenever a story activity occurs in Pivotal Tracker."
	pivotalInt.TypeConstant = webhookmodels.Integration_TYPE_INCOMING
	pivotalInt.Instructions = `
#### Step 1

In your Pivotal Tracker project, click on **Settings** menu and the **Configure Integrations** option.

![pivotal_step1.png](https://s3.amazonaws.com/koding-cdn/temp-images/pivotal_settings.png)


#### Step 2

Go to **Activity Web Hook** section on that page. Copy Webhook URL that we generated for you, and add this url to Webhook  URL field. Ensure that the API Version is set to v5 and then click **Save Web Hook Settings**.

![pivotal_step2.png](https://s3.amazonaws.com/koding-cdn/temp-images/pivotal-add.png)


`

	integrations = append(integrations, pivotalInt)

	// Pagerduty Creation
	pagerdutyInt := webhookmodels.NewIntegration()
	pagerdutyInt.Title = "Pagerduty"
	pagerdutyInt.Name = "pagerduty"
	pagerdutyInt.Summary = "On-call scheduling, alerting, and incident tracking."
	pagerdutyInt.IconPath = "https://s3.amazonaws.com/koding-cdn/temp-images/pagerduty.png"
	pagerdutyInt.Description = "PagerDuty provides IT alert monitoring, on-call scheduling, escalation policies and incident tracking to fix problems in your apps, servers and websites."
	pagerdutyInt.TypeConstant = webhookmodels.Integration_TYPE_INCOMING
	pagerdutyInt.Instructions = `
#### Step 1

In your PagerDuty account, click on **Services** in the top navigation bar. Next, click on the service you would like to monitor and press the **Add a webhook** button further down the page.

![pagerduty_step1.png](https://s3.amazonaws.com/koding-cdn/temp-images/pagerduty-add.png)


#### Step 2

Give it a name and add **Webhook URL** that we generated for you as the Endpoint URL. Press the **Save** button to finish adding the Webhook.

![pagerduty_step2.png](https://s3.amazonaws.com/koding-cdn/temp-images/pagerduty-webhook.png)


#### Step 3

Return to the Koding Integration page (this page) and choose the PagerDuty incidents to monitor by selecting the checkboxes. Press the **SAVE INTEGRATION** button.


`

	pagerdutyInt.Settings = gorm.Hstore{}

	pdEvents := webhookmodels.NewEvents(
		webhookmodels.NewEvent("incident.trigger", "Newly triggered"),
		webhookmodels.NewEvent("incident.acknowledge", "Acknowledged"),
		webhookmodels.NewEvent("incident.resolve", "Resolved"),
		webhookmodels.NewEvent("incident.assign", "Manually reassigned"),
		webhookmodels.NewEvent("incident.escalate", "Escalated"),
		webhookmodels.NewEvent("incident.unacknowledge", "Unacknowledged due to timeout"),
	)

	pagerdutyInt.AddEvents(pdEvents)

	integrations = append(integrations, pagerdutyInt)

	return integrations, nil

}

// EnsureIntegrations creates or updates all integrations
// Declare these integration out of the function.
func (mwc *Controller) EnsureIntegrations() {
	mwc.log.Notice("Creating and updating integration channels")
	integrations, err := mwc.describeIntegrations()
	if err != nil {
		mwc.log.Error("Could not get integration: %s", err)
	}

	for _, integration := range integrations {
		// Get integration from db, if cannot find in db, create it.
		i := webhookmodels.NewIntegration()
		err := i.ByName(integration.Name)
		if err != nil {
			if err == bongo.RecordNotFound || err == webhookmodels.ErrIntegrationNotFound {
				if err = integration.Create(); err != nil {
					mwc.log.Error("Could not create integration: %s", err)
				}
			} else {
				mwc.log.Error("Could not create integration: %s", err)
			}
		} else {
			integration.Id = i.Id
			if err = integration.Update(); err != nil {
				mwc.log.Error("Could not update integration: %s", err)
			}
		}
	}
}

func (mwc *Controller) CreateBotUser() {
	mwc.log.Notice("Creating bot user")
	_, err := models.CreateAccountInBothDbsWithNick("bot")
	if err != nil {
		mwc.log.Error("Could not create bot account")
	}
}
