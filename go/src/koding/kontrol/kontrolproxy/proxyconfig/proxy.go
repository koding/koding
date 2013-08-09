package proxyconfig

import (
	"fmt"
	"koding/kontrol/kontrolproxy/models"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func NewProxy(name string) *models.Proxy {
	return &models.Proxy{
		Id:   bson.NewObjectId(),
		Name: name,
	}
}

func (p *ProxyConfiguration) AddProxy(proxyname string) error {
	proxy := *NewProxy(proxyname)
	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"name": proxyname}, proxy)
		return err
	}
	return p.RunCollection("jProxies", query)
}

func (p *ProxyConfiguration) DeleteProxy(proxyname string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"name": proxyname})
	}

	return p.RunCollection("jProxies", query)
}

func (p *ProxyConfiguration) GetProxy(proxyname string) (models.Proxy, error) {
	proxy := models.Proxy{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"name": proxyname}).One(&proxy)
	}

	err := p.RunCollection("jProxies", query)
	if err != nil {
		return proxy, fmt.Errorf("no proxy with name %s exist.", proxyname)
	}
	return proxy, nil
}

func (p *ProxyConfiguration) GetProxies() []models.Proxy {
	proxy := models.Proxy{}
	proxies := make([]models.Proxy, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(nil).Iter()
		for iter.Next(&proxy) {
			proxies = append(proxies, proxy)
		}

		return nil
	}

	p.RunCollection("jProxies", query)

	return proxies
}
