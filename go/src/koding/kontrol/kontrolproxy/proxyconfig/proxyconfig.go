package proxyconfig

import (
	"koding/tools/config"
	"labix.org/v2/mgo"
)

type ProxyConfiguration struct {
	Session *mgo.Session
}

// Connect creates a new session to the MongoDB cluster and returns a new
// ProxyConfiguration struct holds that session
func Connect() (*ProxyConfiguration, error) {
	p := &ProxyConfiguration{}
	p.CreateSession(config.Current.Mongo)
	return p, nil
}

func (p *ProxyConfiguration) CreateSession(url string) {
	var err error
	p.Session, err = mgo.Dial(url)
	if err != nil {
		panic(err) // no, not really
	}

	p.Session.SetSafe(&mgo.Safe{})
}

func (p *ProxyConfiguration) Close() {
	p.Session.Close()
}

func (p *ProxyConfiguration) Refresh() {
	p.Session.Refresh()
}

func (p *ProxyConfiguration) Copy() *mgo.Session {
	return p.Session.Copy()
}

func (p *ProxyConfiguration) GetSession() *mgo.Session {
	if p.Session == nil {
		p.CreateSession(config.Current.Mongo)
	}
	return p.Copy()
}

func (p *ProxyConfiguration) RunCollection(collection string, s func(*mgo.Collection) error) error {
	session := p.GetSession()
	defer session.Close()
	c := session.DB("").C(collection)
	return s(c)
}

func (p *ProxyConfiguration) GetCollection(collection string) *mgo.Collection {
	session := p.GetSession()
	return session.DB("").C(collection)
}
