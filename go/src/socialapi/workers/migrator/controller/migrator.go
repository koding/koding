package controller

import (
	"encoding/json"
	"errors"
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"reflect"
	"socialapi/models"
	"strings"
	"time"

	"github.com/VerbalExpressions/GoVerbalExpressions"
	"github.com/koding/logging"
	"labix.org/v2/mgo/bson"
)

var (
	ErrMigrated     = errors.New("already migrated")
	kodingChannelId int64
	tagRegex        = verbalexpressions.New().
			BeginCapture().
			Find("|#:JTag:").
			Word().
			Then(":").
			Word().
			Then("|").
			EndCapture().
			Regex()
)

type Controller struct {
	log logging.Logger
}

func New(log logging.Logger) (*Controller, error) {
	wc := &Controller{
		log: log,
	}

	return wc, nil
}

func (mwc *Controller) Start() error {
	if err := mwc.migrateAllAccounts(); err != nil {
		return err
	}

	if err := mwc.migrateAllGroups(); err != nil {
		return err
	}

	if err := mwc.migrateAllTags(); err != nil {
		return err
	}

	if err := mwc.migrateAllPosts(); err != nil {
		return err
	}

	return nil
}

func (mwc *Controller) migrateAllPosts() error {
	o := modelhelper.Options{
		Sort: "meta.createdAt",
	}
	s := modelhelper.Selector{
		"socialMessageId": modelhelper.Selector{"$exists": false},
	}
	kodingChannel, err := mwc.createGroupChannel("koding")
	if err != nil {
		return fmt.Errorf("Koding channel cannot be created: %s", err)
	}
	kodingChannelId = kodingChannel.Id

	errCount := 0
	successCount := 0

	handleError := func(su *mongomodels.StatusUpdate, err error) {
		mwc.log.Error("an error occured for %s: %s", su.Id.Hex(), err)
		errCount++
	}

	iter := modelhelper.GetStatusUpdateIter(s, o)
	defer iter.Close()

	var su mongomodels.StatusUpdate
	for iter.Next(&su) {
		channelId, err := mwc.fetchGroupChannelId(su.Group)
		if err != nil {
			return fmt.Errorf("Post migration is interrupted with %d errors: channel id cannot be fetched :%s", errCount, err)
		}

		// create channel message
		cm, err := mapStatusUpdateToChannelMessage(&su)
		if err != nil {
			handleError(&su, err)
			continue
		}

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
		if err := mwc.migrateComments(cm, &su); err != nil {
			handleError(&su, err)
			continue
		}

		if err := mwc.migrateLikes(cm, su.Id); err != nil {
			handleError(&su, err)
			continue
		}

		if err := mwc.migrateTags(cm, su.Id); err != nil {
			handleError(&su, err)
			continue
		}

		// update mongo status update channelMessageId field
		if err := completePostMigration(&su, cm); err != nil {
			handleError(&su, err)
			continue
		}
		successCount++
	}

	if err := iter.Err(); err != nil {
		return fmt.Errorf("Post migration is interrupted with %d errors: %s", errCount, err)
	}

	mwc.log.Notice("Post migration completed for %d status updates with %d errors", successCount, errCount)

	return nil
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
		a := models.NewAccount()
		a.OldId = r.TargetId.Hex()
		if err := a.FetchOrCreate(); err != nil {
			mwc.log.Error("interactor account could not found: %s", err)
			continue
		}
		i := models.NewInteraction()
		i.MessageId = cm.Id
		i.AccountId = a.Id
		i.TypeConstant = models.Interaction_TYPE_LIKE
		i.CreatedAt = r.TimeStamp
		if err := i.CreateRaw(); err != nil {
			mwc.log.Error("interaction could not created: %s", err)
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

func mapStatusUpdateToChannelMessage(su *mongomodels.StatusUpdate) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.Slug = su.Slug
	prepareBody(cm, su.Body)
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
	lowerLimit := cm.CreatedAt.Add(-time.Second)
	upperLimit := cm.CreatedAt.Add(time.Second)
	if meta.ModifiedAt.After(lowerLimit) && meta.ModifiedAt.Before(upperLimit) {
		cm.UpdatedAt = cm.CreatedAt
	} else {
		cm.UpdatedAt = meta.ModifiedAt
	}
}

func prepareBody(cm *models.ChannelMessage, body string) {
	res := tagRegex.FindAllStringSubmatch(body, -1)
	cm.Body = body
	if len(res) == 0 {
		return
	}

	for _, element := range res {
		tag := element[1][1 : len(element[1])-1]
		tag = strings.Split(tag, ":")[3]
		tag = "#" + tag
		cm.Body = verbalexpressions.New().Find(element[1]).Replace(cm.Body, tag)
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
