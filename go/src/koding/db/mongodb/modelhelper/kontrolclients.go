package modelhelper

import (
	"koding/db/models"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func AddClient(info models.ServerInfo) error {
	query := func(c *mgo.Collection) error {
		info.CreatedAt = time.Now()
		_, err := c.Upsert(bson.M{"buildnumber": info.BuildNumber}, info)
		return err
	}

	return Mongo.Run("jKontrolClients", query)
}

func GetClient(buildnumber string) (models.ServerInfo, error) {
	serverinfo := models.ServerInfo{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"buildnumber": buildnumber}).One(&serverinfo)
	}

	err := Mongo.Run("jKontrolClients", query)
	if err != nil {
		return serverinfo, err
	}

	return serverinfo, nil
}

func GetClients() []models.ServerInfo {
	info := models.ServerInfo{}
	infos := make([]models.ServerInfo, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(nil).Iter()
		for iter.Next(&info) {
			infos = append(infos, info)
		}
		return nil
	}

	Mongo.Run("jKontrolClients", query)

	return infos
}

func DeleteClient(build string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"buildnumber": build})
	}

	return Mongo.Run("jKontrolClients", query)
}
