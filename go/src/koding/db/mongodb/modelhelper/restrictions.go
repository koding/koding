package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func DeleteRestriction(domainname string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"domainName": domainname})
	}

	return Mongo.Run("jProxyRestrictions", query)
}

func GetRestrictionByDomain(domainname string) (models.Restriction, error) {
	restriction := models.Restriction{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"domainName": domainname}).One(&restriction)
	}

	err := Mongo.Run("jProxyRestrictions", query)
	if err != nil {
		return restriction, err
	}
	return restriction, nil
}

func GetRestrictionByID(id bson.ObjectId) (models.Restriction, error) {
	restriction := models.Restriction{}
	query := func(c *mgo.Collection) error {
		return c.FindId(id).One(&restriction)
	}

	err := Mongo.Run("jProxyRestrictions", query)
	if err != nil {
		return restriction, err
	}
	return restriction, nil
}
