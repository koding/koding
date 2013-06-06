package proxyconfig

import (
	"github.com/bradfitz/gomemcache/memcache"
	"koding/tools/config"
	"labix.org/v2/mgo"
)

type ProxyConfiguration struct {
	Session    *mgo.Session
	Collection map[string]*mgo.Collection
	MemCache   *memcache.Client
}

func Connect() (*ProxyConfiguration, error) {
	session, err := mgo.Dial(config.Current.Kontrold.Mongo.Host)
	if err != nil {
		return nil, err
	}
	session.SetMode(mgo.Strong, true)
	session.SetSafe(&mgo.Safe{})

	collections := make(map[string]*mgo.Collection)
	collections["services"] = session.DB("kontrol").C("pServices")
	collections["proxies"] = session.DB("kontrol").C("pProxies")
	collections["domains"] = session.DB("kontrol").C("pDomains")
	collections["rules"] = session.DB("kontrol").C("pRules")
	collections["domainstats"] = session.DB("kontrol").C("pDomainStats")
	collections["proxystats"] = session.DB("kontrol").C("pProxyStats")

	mc := memcache.New("127.0.0.1:11211", "127.0.0.1:11211")

	pr := &ProxyConfiguration{
		Session:    session,
		Collection: collections,
		MemCache:   mc,
	}

	return pr, nil
}
