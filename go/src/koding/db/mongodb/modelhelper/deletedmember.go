package modelhelper

import (
	"koding/db/models"
	"time"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const DeletedMembersCollectionName = "jDeletedMembers"

// GetDeletedMemberCountByGroupId counts the deleted users with groupId
func GetDeletedMemberCountByGroupId(groupID bson.ObjectId) (int, error) {
	var count int
	query := countQuery(Selector{
		"subscriptionId": bson.M{"$exists": false},
		"groupId":        groupID,
	}, Options{}, &count)

	return count, Mongo.Run(DeletedMembersCollectionName, query)
}

// CalculateAndApplyDeletedMembers counts the deleted users and marks them as
// operated for future invoices
func CalculateAndApplyDeletedMembers(groupID bson.ObjectId, subscriptionID string) (int, error) {
	var changeInfo *mgo.ChangeInfo
	var err error
	query := func(c *mgo.Collection) error {
		query := bson.M{
			"subscriptionId": bson.M{"$exists": false},
			"groupId":        groupID,
		}

		change := bson.M{
			"$set": bson.M{
				"subscriptionId": subscriptionID,
				"updatedAt":      time.Now().UTC(),
			},
		}

		changeInfo, err = c.UpdateAll(query, change)
		return err
	}

	return changeInfo.Updated, Mongo.Run(DeletedMembersCollectionName, query)
}

// EnsureDeletedMemberIndex creates the related index
func EnsureDeletedMemberIndex() error {
	query := func(c *mgo.Collection) error {
		index := mgo.Index{
			Key:        []string{"groupId", "subscriptionId"},
			Background: true,
			Sparse:     true,
		}

		return c.EnsureIndex(index)
	}

	return Mongo.Run(DeletedMembersCollectionName, query)
}

// CreateDeletedMember creates a member that is in deleted records
func CreateDeletedMember(groupID, accountID bson.ObjectId) (*models.DeletedMember, error) {
	m := &models.DeletedMember{
		Id:        bson.NewObjectId(),
		AccountID: accountID,
		GroupID:   groupID,
	}

	query := insertQuery(m)
	if err := Mongo.Run(DeletedMembersCollectionName, query); err != nil {
		return nil, err
	}

	return m, nil
}
