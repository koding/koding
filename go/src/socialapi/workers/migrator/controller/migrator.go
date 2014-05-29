package controller

import (
	"errors"
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"

	"github.com/koding/logging"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	ErrMigrated     = errors.New("already migrated")
	kodingChannelId int64
)

type MigratorWorkerController struct {
	log logging.Logger
}

func NewMigratorWorkerController(log logging.Logger) (*MigratorWorkerController, error) {
	wc := &MigratorWorkerController{
		log: log,
	}

	return wc, nil
}

func (mwc *MigratorWorkerController) Start() error {
	o := modelhelper.Options{
		Sort: "meta.createdAt",
	}
	s := modelhelper.Selector{
		"socialMessageId": modelhelper.Selector{"$exists": false},
	}
	kodingChannel, err := createGroupChannel("koding")
	if err != nil {
		return fmt.Errorf("Koding channel cannot be created: %s", err)
	}
	kodingChannelId = kodingChannel.Id

	errCount := 0

	handleError := func(su *mongomodels.StatusUpdate, err error) {
		mwc.log.Error("an error occured for %s: %s", su.Id.Hex(), err)
		errCount++
	}

	for {
		o.Skip = errCount
		su, err := modelhelper.GetStatusUpdate(s, o)
		if err != nil {
			if err == mgo.ErrNotFound {
				mwc.log.Notice("Migration completed")
				return nil
			}
			return fmt.Errorf("status update cannot be fetched: %s", err)
		}

		channelId, err := fetchGroupChannelId(su.Group)
		if err != nil {
			return fmt.Errorf("channel id cannot be fetched :%s", err)
		}

		// create channel message
		cm := mapStatusUpdateToChannelMessage(&su)
		cm.InitialChannelId = channelId
		if err := insertChannelMessage(cm, su.OriginId.Hex()); err != nil {
			handleError(&su, err)
			continue
		}

		if err := addChannelMessageToMessageList(cm); err != nil {
			handleError(&su, err)
			continue
		}

		// create reply messages
		if err := migrateComments(cm, &su, channelId); err != nil {
			handleError(&su, err)
			continue
		}

		if err := migrateLikes(cm, su.Id); err != nil {
			handleError(&su, err)
			continue
		}

		// update mongo status update channelMessageId field
		if err := completePostMigration(&su, cm); err != nil {
			handleError(&su, err)
			continue
		}

		fmt.Printf("\n\nStatus update var %+v \n\n", su)
	}

	return nil
}

func createGroupChannel(groupName string) (*models.Channel, error) {
	c := models.NewChannel()
	c.Name = groupName
	c.GroupName = groupName
	c.TypeConstant = models.Channel_TYPE_GROUP

	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	// TODO check it causes any error
	c.PrivacyConstant = group.Privacy

	// find group owner
	creatorId, err := fetchGroupOwnerId(group)
	if err != nil {
		return nil, err
	}

	c.CreatorId = creatorId
	// create channel
	if err := c.Create(); err != nil {
		return nil, err
	}

	return c, nil
}

func fetchGroupOwnerId(g *mongomodels.Group) (int64, error) {
	// fetch owner relationship
	s := modelhelper.Selector{
		"targetName": "JAccount",
		"as":         "owner",
		"sourceId":   g.Id,
	}
	r, err := modelhelper.GetRelationship(s)
	if err != nil {
		return 0, err
	}

	a := models.NewAccount()
	a.OldId = r.TargetId.Hex()
	if err := a.FetchOrCreate(); err != nil {
		return 0, err
	}

	return a.Id, nil
}

func insertChannelMessage(cm *models.ChannelMessage, accountOldId string) error {

	if err := prepareMessageAccount(cm, accountOldId); err != nil {
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

func migrateComments(parentMessage *models.ChannelMessage, su *mongomodels.StatusUpdate, channelId int64) error {

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
		reply.InitialChannelId = channelId
		// insert as channel message
		if err := insertChannelMessage(reply, comment.OriginId.Hex()); err != nil {
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

		if err := migrateLikes(reply, comment.Id); err != nil {
			return fmt.Errorf("likes cannot be migrated %s", err)
		}

		if err := completeCommentMigration(comment, reply); err != nil {
			return fmt.Errorf("old comment cannot be flagged with new message id %s", err)
		}
	}

	return nil
}

func migrateLikes(cm *models.ChannelMessage, oldId bson.ObjectId) error {
	s := modelhelper.Selector{
		"sourceId": oldId,
		"as":       "like",
	}
	rels, err := modelhelper.GetAllRelationships(s)
	if err != nil {
		return fmt.Errorf("likes cannot be fetched %s", err)
	}
	for _, r := range rels {
		a := models.NewAccount()
		a.OldId = r.TargetId.Hex()
		if err := a.FetchOrCreate(); err != nil {
			return fmt.Errorf("interactor account could not found: %s", err)
		}
		i := models.NewInteraction()
		i.MessageId = cm.Id
		i.AccountId = a.Id
		i.TypeConstant = models.Interaction_TYPE_LIKE
		// creation date is not stored in mongo, so we could not set createdAt here.
		if err := i.Create(); err != nil {
			return fmt.Errorf("interaction could not created: %s", err)
		}
	}

	return nil
}

func prepareMessageAccount(cm *models.ChannelMessage, accountOldId string) error {
	a := models.NewAccount()
	a.OldId = accountOldId
	if err := a.FetchOrCreate(); err != nil {
		return fmt.Errorf("account could not found: %s", err)
	}

	cm.AccountId = a.Id

	return nil
}

func fetchGroupChannelId(groupName string) (int64, error) {
	// koding group channel id is prefetched
	if groupName == "koding" {
		return kodingChannelId, nil
	}

	c, err := createGroupChannel(groupName)
	if err != nil {
		return 0, err
	}

	return c.Id, nil
}

func mapStatusUpdateToChannelMessage(su *mongomodels.StatusUpdate) *models.ChannelMessage {
	cm := models.NewChannelMessage()
	cm.Slug = su.Slug
	cm.Body = su.Body
	cm.TypeConstant = models.ChannelMessage_TYPE_POST
	cm.CreatedAt = su.Meta.CreatedAt
	prepareMessageMetaDates(cm, &su.Meta)

	return cm
}

func mapCommentToChannelMessage(c *mongomodels.Comment) *models.ChannelMessage {
	cm := models.NewChannelMessage()
	cm.Body = c.Body
	cm.TypeConstant = models.ChannelMessage_TYPE_REPLY
	cm.CreatedAt = c.Meta.CreatedAt
	prepareMessageMetaDates(cm, &c.Meta)

	return cm
}

func prepareMessageMetaDates(cm *models.ChannelMessage, meta *mongomodels.Meta) {
	// this is added because status update->modified at field is before createdAt
	if cm.CreatedAt.After(meta.ModifiedAt) {
		cm.UpdatedAt = cm.CreatedAt
	} else {
		cm.UpdatedAt = meta.ModifiedAt
	}
}

func completePostMigration(su *mongomodels.StatusUpdate, cm *models.ChannelMessage) error {
	su.SocialMessageId = cm.Id

	return modelhelper.UpdateStatusUpdate(su)
}

func completeCommentMigration(reply *mongomodels.Comment, cm *models.ChannelMessage) error {
	reply.SocialMessageId = cm.Id

	return modelhelper.UpdateComment(reply)
}
