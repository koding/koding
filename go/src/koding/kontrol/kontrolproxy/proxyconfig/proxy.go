package proxyconfig

import (
	"fmt"
	"koding/kontrol/kontrolproxy/models"
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
	_, err := p.Collection["proxies"].Upsert(bson.M{"name": proxyname}, proxy)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteProxy(proxyname string) error {
	err := p.Collection["proxies"].Remove(bson.M{"name": proxyname})
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) GetProxy(proxyname string) (models.Proxy, error) {
	proxy := models.Proxy{}
	err := p.Collection["proxies"].Find(bson.M{"name": proxyname}).One(&proxy)
	if err != nil {
		return proxy, fmt.Errorf("no proxy with name %s exist.", proxyname)
	}

	return proxy, nil
}

func (p *ProxyConfiguration) GetProxies() []models.Proxy {
	proxy := models.Proxy{}
	proxies := make([]models.Proxy, 0)
	iter := p.Collection["proxies"].Find(nil).Iter()
	for iter.Next(&proxy) {
		proxies = append(proxies, proxy)
	}

	return proxies
}
