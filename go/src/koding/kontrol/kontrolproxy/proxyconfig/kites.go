package proxyconfig

import (
	"koding/newkite/protocol"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func NewKite() *protocol.Kite {
	return &protocol.Kite{}
}

func (p *ProxyConfiguration) UpsertKite(kite *protocol.Kite) error {
	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"uuid": kite.Uuid}, kite)
		return err
	}

	return p.RunCollection("jKites", query)
}

func (p *ProxyConfiguration) GetKite(uuid string) (*protocol.Kite, error) {
	kite := protocol.Kite{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"uuid": uuid}).One(&kite)
	}

	err := p.RunCollection("jKites", query)
	if err != nil {
		return nil, err
	}
	return &kite, nil
}

func (p *ProxyConfiguration) UpdateKite(kite *protocol.Kite) error {
	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"uuid": kite.Uuid}, kite)
	}

	return p.RunCollection("jKites", query)
}

func (p *ProxyConfiguration) DeleteKite(uuid string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"uuid": uuid})
	}

	return p.RunCollection("jKites", query)
}

func (p *ProxyConfiguration) SizeKites() (int, error) {
	var count int
	var err error
	query := func(c *mgo.Collection) error {
		count, err = c.Count()
		return err
	}

	err = p.RunCollection("jKites", query)
	return count, err
}

func (p *ProxyConfiguration) ListKites() []*protocol.Kite {
	kites := make([]*protocol.Kite, 0)
	query := func(c *mgo.Collection) error {
		// todo use Limit() to decrease the memory overhead, future
		// improvements...
		iter := c.Find(nil).Iter()
		return iter.All(&kites)
	}

	p.RunCollection("jKites", query)
	return kites
}
