package modelhelper

import (
	"fmt"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func NewProxy(name string) *models.Proxy {
	return &models.Proxy{
		Id:   bson.NewObjectId(),
		Name: name,
	}
}

func AddProxy(proxyname string) error {
	proxy := *NewProxy(proxyname)
	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"name": proxyname}, proxy)
		return err
	}
	return Mongo.Run("jProxies", query)
}

func DeleteProxy(proxyname string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"name": proxyname})
	}

	return Mongo.Run("jProxies", query)
}

func GetProxy(proxyname string) (models.Proxy, error) {
	proxy := models.Proxy{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"name": proxyname}).One(&proxy)
	}

	err := Mongo.Run("jProxies", query)
	if err != nil {
		return proxy, fmt.Errorf("no proxy with name %s exist.", proxyname)
	}
	return proxy, nil
}

func GetProxies() []models.Proxy {
	proxy := models.Proxy{}
	proxies := make([]models.Proxy, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(nil).Iter()
		for iter.Next(&proxy) {
			proxies = append(proxies, proxy)
		}

		return nil
	}

	Mongo.Run("jProxies", query)

	return proxies
}
