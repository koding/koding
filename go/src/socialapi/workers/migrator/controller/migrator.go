package controller

import (
	"encoding/json"
	"errors"
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/helpers"
	"reflect"
	"socialapi/models"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/robfig/cron"
	"labix.org/v2/mgo/bson"
)

const SCHEDULE = "0 */5 * * * *"

var (
	ErrMigrated     = errors.New("already migrated")
	kodingChannelId int64
)

type Controller struct {
	log     logging.Logger
	cronJob *cron.Cron
	ready   chan bool
}

func New(log logging.Logger) (*Controller, error) {
	wc := &Controller{
		log:   log,
		ready: make(chan bool, 1),
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

	mwc.migrateAllAccountsToAlgolia()

	mwc.migrateAllAccounts()

	mwc.migrateAllGroups()

	mwc.migrateAllTags()

	mwc.migrateAllPosts()

	mwc.log.Notice("Migration finished")

	mwc.ready <- true
}

func (mwc *Controller) migrateAllPosts() {
	mwc.log.Notice("Post migration started")
	s := modelhelper.Selector{
		"migration": modelhelper.Selector{"$exists": false},
	}
	kodingChannel, err := mwc.createGroupChannel("koding")
	if err != nil {
		panic(fmt.Sprintf("Koding channel cannot be created: %s", err))
	}
	kodingChannelId = kodingChannel.Id

	errCount := 0
	successCount := 0

	handleError := func(su *mongomodels.StatusUpdate, err error) {
		mwc.log.Error("an error occured for %s: %s", su.Id.Hex(), err)
		errCount++

		s := modelhelper.Selector{"_id": su.Id}
		o := modelhelper.Selector{"$set": modelhelper.Selector{"migration": MigrationFailed, "error": err.Error()}}
		if err := modelhelper.UpdateStatusUpdatePartial(s, o); err != nil {
			mwc.log.Warning("Could not update status update document: %s", err)
		}
	}

	migratePost := func(post interface{}) error {
		su := post.(*mongomodels.StatusUpdate)
		channelId, err := mwc.fetchGroupChannelId(su.Group)
		if err != nil {
			if err == bongo.RecordNotFound {
				handleError(su, err)
				return nil
			}

			return err
		}

		if su.SocialMessageId > 0 {
			s := modelhelper.Selector{"_id": su.Id}
			o := modelhelper.Selector{"$set": modelhelper.Selector{"migration": MigrationCompleted}}
			modelhelper.UpdateStatusUpdatePartial(s, o)
			return nil
		}

		// create channel message
		cm, err := mapStatusUpdateToChannelMessage(su)
		if err != nil {
			handleError(su, err)
			return nil
		}

		cm.InitialChannelId = channelId
		if err := mwc.insertChannelMessage(cm, su.OriginId.Hex()); err != nil {
			handleError(su, err)
			return nil
		}

		if err := addChannelMessageToMessageList(cm); err != nil {
			handleError(su, err)
			return nil
		}

		// create reply messages
		if err := mwc.migrateComments(cm, su); err != nil {
			handleError(su, err)
			return nil
		}

		if err := mwc.migrateLikes(cm, su.Id); err != nil {
			handleError(su, err)
			return nil
		}

		if err := mwc.migrateTags(cm, su.Id); err != nil {
			handleError(su, err)
			return nil
		}

		// update mongo status update channelMessageId field
		if err := completePostMigration(su, cm); err != nil {
			handleError(su, err)
			return nil
		}
		successCount++

		return nil
	}

	iterOptions := helpers.NewIterOptions()
	iterOptions.CollectionName = "jNewStatusUpdates"
	iterOptions.F = migratePost
	iterOptions.Filter = s
	iterOptions.Result = &mongomodels.StatusUpdate{}
	iterOptions.Limit = 10000000
	iterOptions.Skip = 0

	if err := helpers.Iter(modelhelper.Mongo, iterOptions); err != nil {
		mwc.log.Fatal("Post migration is interrupted with %d errors: channel id cannot be fetched :%s", errCount, err)
	}

	mwc.log.Notice("Post migration completed for %d status updates with %d errors", successCount, errCount)
}

func (mwc *Controller) insertChannelMessage(cm *models.ChannelMessage, accountOldId string) error {

	if err := mwc.prepareMessageAccount(cm, accountOldId); err != nil {
		return err
	}

	if err := cm.CreateRaw(); err != nil {
		return err
	}

	return nil
}

func addChannelMessageToMessageList(cm *models.ChannelMessage) error {
	cml := models.NewChannelMessageList()
	cml.ChannelId = cm.InitialChannelId
	cml.MessageId = cm.Id
	cml.AddedAt = cm.CreatedAt

	return cml.CreateRaw()
}

func (mwc *Controller) migrateComments(parentMessage *models.ChannelMessage, su *mongomodels.StatusUpdate) error {

	s := modelhelper.Selector{
		"sourceId":   su.Id,
		"targetName": "JComment",
	}
	rels, err := modelhelper.GetAllRelationships(s)
	if err != nil {
		if err == modelhelper.ErrNotFound {
			return nil
		}
		return fmt.Errorf("comment relationships cannot be fetched: %s", err)
	}

	for _, r := range rels {
		comment, err := modelhelper.GetCommentById(r.TargetId.Hex())
		if err != nil {
			return fmt.Errorf("comment cannot be fetched %s", err)
		}
		// comment is already migrated
		if comment.SocialMessageId != 0 {
			continue
		}

		reply := mapCommentToChannelMessage(comment)
		reply.InitialChannelId = parentMessage.InitialChannelId
		// insert as channel message
		if err := mwc.insertChannelMessage(reply, comment.OriginId.Hex()); err != nil {
			return fmt.Errorf("comment cannot be inserted %s", err)
		}

		// insert as message reply
		mr := models.NewMessageReply()
		mr.MessageId = parentMessage.Id
		mr.ReplyId = reply.Id
		mr.CreatedAt = reply.CreatedAt
		if err := mr.CreateRaw(); err != nil {
			return fmt.Errorf("comment cannot be inserted to message reply %s", err)
		}

		if err := mwc.migrateLikes(reply, comment.Id); err != nil {
			return fmt.Errorf("likes cannot be migrated %s", err)
		}

		if err := completeCommentMigration(comment, reply); err != nil {
			return fmt.Errorf("old comment cannot be flagged with new message id %s", err)
		}
	}

	return nil
}

func (mwc *Controller) migrateLikes(cm *models.ChannelMessage, oldId bson.ObjectId) error {
	s := modelhelper.Selector{
		"sourceId": oldId,
		"as":       "like",
	}
	rels, err := modelhelper.GetAllRelationships(s)
	if err != nil {
		return fmt.Errorf("likes cannot be fetched %s", err)
	}
	for _, r := range rels {
		id, err := mwc.AccountIdByOldId(r.TargetId.Hex())
		if err != nil {
			mwc.log.Error("interactor account %s could not found: %s", r.TargetId.Hex(), err)
			continue
		}
		i := models.NewInteraction()
		i.MessageId = cm.Id
		i.AccountId = id
		i.TypeConstant = models.Interaction_TYPE_LIKE
		i.CreatedAt = r.TimeStamp
		if err := i.CreateRaw(); err != nil {
			mwc.log.Error("interaction could not created: %s", err)
		}
	}

	return nil
}

func (mwc *Controller) prepareMessageAccount(cm *models.ChannelMessage, accountOldId string) error {
	id, err := mwc.AccountIdByOldId(accountOldId)
	if err != nil {
		return fmt.Errorf("account could not found: %s", err)
	}

	cm.AccountId = id

	return nil
}

func (mwc *Controller) fetchGroupChannelId(groupName string) (int64, error) {
	// koding group channel id is prefetched
	if groupName == "koding" {
		return kodingChannelId, nil
	}

	c := models.NewChannel()
	channelId, err := c.FetchChannelIdByNameAndGroupName(groupName, groupName)
	if err != nil {
		return 0, err
	}

	return channelId, nil
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

func mapStatusUpdateToChannelMessage(su *mongomodels.StatusUpdate) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.Body = su.Body // for now do not modify tags
	if err := migrateSlug(cm, su.Slug); err != nil {
		return nil, err
	}
	cm.TypeConstant = models.ChannelMessage_TYPE_POST
	cm.CreatedAt = su.Meta.CreatedAt
	payload, err := mapEmbeddedLink(su.Link)
	if err != nil {
		return nil, err
	}
	cm.Payload = payload

	prepareMessageMetaDates(cm, &su.Meta)

	return cm, nil
}

func migrateSlug(cm *models.ChannelMessage, slug string) error {
	if len(slug) > 100 {
		if _, err := models.Slugify(cm); err != nil {
			return err
		}

		return nil
	}

	cm.Slug = slug

	return nil
}

func mapEmbeddedLink(link map[string]interface{}) (map[string]*string, error) {
	resultMap := make(map[string]*string)
	for key, value := range link {
		// when value is a map, then marshal it
		if reflect.ValueOf(value).Kind() == reflect.Map {
			res, err := json.Marshal(value)
			if err != nil {
				return nil, err
			}

			s := string(res)
			resultMap[key] = &s
			continue
		}

		// for the other types convert value to string
		str := fmt.Sprintf("%v", value)
		resultMap[key] = &str
	}

	return resultMap, nil
}

func mapCommentToChannelMessage(c *mongomodels.Comment) *models.ChannelMessage {
	cm := models.NewChannelMessage()
	cm.Body = c.Body
	cm.TypeConstant = models.ChannelMessage_TYPE_REPLY
	cm.CreatedAt = c.Meta.CreatedAt
	cm.DeletedAt = c.DeletedAt
	prepareMessageMetaDates(cm, &c.Meta)

	return cm
}

func prepareMessageMetaDates(cm *models.ChannelMessage, meta *mongomodels.Meta) {
	// default setter
	cm.UpdatedAt = meta.ModifiedAt

	// i am not sure if it is possible but i do not trust current mongo data :)
	if meta.ModifiedAt.Before(meta.CreatedAt) {
		cm.UpdatedAt = cm.CreatedAt
		return
	}

	// if modified at value is within 1 second limits of created at value
	lowerLimit := cm.CreatedAt.Add(-time.Second)
	upperLimit := cm.CreatedAt.Add(time.Second)
	if meta.ModifiedAt.After(lowerLimit) && meta.ModifiedAt.Before(upperLimit) {
		cm.UpdatedAt = cm.CreatedAt
	}
}

func completePostMigration(su *mongomodels.StatusUpdate, cm *models.ChannelMessage) error {
	su.SocialMessageId = cm.Id
	su.Migration = MigrationCompleted

	return modelhelper.UpdateStatusUpdate(su)
}

func completeCommentMigration(reply *mongomodels.Comment, cm *models.ChannelMessage) error {
	reply.SocialMessageId = cm.Id

	return modelhelper.UpdateComment(reply)
}
