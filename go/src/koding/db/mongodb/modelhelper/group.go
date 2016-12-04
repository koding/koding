package modelhelper

import (
	"errors"
	"time"

	"koding/db/models"
	"koding/kites/kloud/utils"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const GroupsCollectionName = "jGroups"

func GetGroupById(id string) (*models.Group, error) {
	var group models.Group

	return &group, Mongo.Run(GroupsCollectionName, func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.ObjectIdHex(id)}).One(&group)
	})
}

// GetGroupsByIds returns groups by their given IDs
func GetGroupsByIds(ids ...bson.ObjectId) ([]*models.Group, error) {
	var groups []*models.Group

	return groups, Mongo.Run(GroupsCollectionName, func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": ids}}).All(&groups)
	})
}

// GetGroupFieldsByIds retrieves a slice of groups matching the given ids and
// limited to the specified fields.
func GetGroupFieldsByIds(ids []string, fields []string) ([]*models.Group, error) {
	groups := []*models.Group{}

	objectIds := make([]bson.ObjectId, len(ids))
	for i, id := range ids {
		objectIds[i] = bson.ObjectIdHex(id)
	}

	selects := bson.M{}
	for _, f := range fields {
		selects[f] = 1
	}

	query := func(c *mgo.Collection) error {
		iter := c.Find(bson.M{
			"_id": bson.M{"$in": objectIds},
		}).Select(selects).Iter()

		for g := new(models.Group); iter.Next(g); g = new(models.Group) {
			groups = append(groups, g)
		}

		return iter.Close()
	}

	return groups, Mongo.Run(GroupsCollectionName, query)
}

// GetGroupForKite reverse looks up a team name for the given kiteID
// by looking up a kiteID among jMachine.queryString fields.
func GetGroupForKite(kiteID string) (*models.Group, error) {
	qs, err := utils.QueryString(kiteID)
	if err != nil {
		return nil, err
	}

	var groups []struct {
		ID bson.ObjectId `bson:"id"`
	}

	fn := func(c *mgo.Collection) error {
		return c.Find(bson.M{"queryString": qs}).Select(bson.M{"groups": 1}).One(&groups)
	}

	if err := Mongo.Run(MachinesColl, fn); err != nil {
		return nil, err
	}

	if len(groups) == 0 {
		return nil, mgo.ErrNotFound
	}

	return GetGroupById(groups[0].ID.Hex())
}

func GetGroup(slugName string) (*models.Group, error) {
	group := new(models.Group)

	query := func(c *mgo.Collection) error {
		return c.Find(Selector{"slug": slugName}).One(&group)
	}

	return group, Mongo.Run(GroupsCollectionName, query)
}

func GetGroupOwner(group *models.Group) (*models.Account, error) {
	if !group.Id.Valid() {
		return nil, errors.New("group id is not valid")
	}

	rel, err := GetRelationship(Selector{
		"sourceId": group.Id,
		"as":       "owner",
	})

	if err != nil {
		return nil, err
	}

	return GetAccountById(rel.TargetId.Hex())
}

func RemoveGroup(id bson.ObjectId) error {
	return RemoveDocument(GroupsCollectionName, id)
}

func CheckGroupExistence(groupname string) (bool, error) {
	var count int
	query := func(c *mgo.Collection) error {
		var err error
		count, err = c.Find(Selector{"slug": groupname}).Count()
		if err != nil {
			return err
		}
		return nil
	}

	return count > 0, Mongo.Run(GroupsCollectionName, query)
}

func UpdateGroup(g *models.Group) error {
	query := updateByIdQuery(g.Id.Hex(), g)
	return Mongo.Run(GroupsCollectionName, query)
}

func UpdateGroupPartial(selector, options Selector) error {
	query := func(c *mgo.Collection) error {
		return c.Update(selector, options)
	}

	return Mongo.Run(GroupsCollectionName, query)
}

func UpdateGroupAddMembers(id bson.ObjectId, newMembers int) (count int, err error) {
	query := func(c *mgo.Collection) error {
		var group models.Group
		err := c.FindId(id).One(&group)
		if err != nil {
			return err
		}
		members, ok := group.Counts["members"]
		if ok {
			count, ok = members.(int)
			if !ok {
				// If the member count is unavaible to skip updating
				// and return.
				return nil
			}
		}
		count += newMembers
		group.Counts["members"] = count
		return c.UpdateId(id, &group)
	}
	err = Mongo.Run("jGroups", query)
	if err != nil {
		return 0, err
	}
	return count, nil
}

func CreateGroup(m *models.Group) error {
	query := func(c *mgo.Collection) error {
		return c.Insert(m)
	}

	return Mongo.Run(GroupsCollectionName, query)
}

func MakeAdmin(accountId, groupId bson.ObjectId) error {
	r := &models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   accountId,
		TargetName: "JAccount",
		SourceId:   groupId,
		SourceName: "JGroup",
		As:         "admin",
		TimeStamp:  time.Now().UTC(),
	}

	return AddRelationship(r)
}
