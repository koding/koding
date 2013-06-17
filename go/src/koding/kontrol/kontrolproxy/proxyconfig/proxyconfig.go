package proxyconfig

import (
	"koding/tools/config"
	"labix.org/v2/mgo"
)

type ProxyConfiguration struct {
	Session    *mgo.Session
	Collection map[string]*mgo.Collection
}

func Connect() (*ProxyConfiguration, error) {
	session, err := mgo.Dial(config.Current.Mongo)
	if err != nil {
		return nil, err
	}
	session.SetMode(mgo.Strong, true)
	session.SetSafe(&mgo.Safe{})
	database := session.DB("")

	collections := make(map[string]*mgo.Collection)
	collections["services"] = database.C("jProxyServices")
	collections["proxies"] = database.C("jProxies")
	collections["domains"] = database.C("jDomains")
	collections["filters"] = database.C("jProxyFilters")
	collections["restrictions"] = database.C("jProxyRestrictions")
	collections["domainstats"] = database.C("jDomainStats")
	collections["proxystats"] = database.C("jProxyStats")
	collections["relationships"] = database.C("relationships")

	pr := &ProxyConfiguration{
		Session:    session,
		Collection: collections,
	}

	return pr, nil
}
