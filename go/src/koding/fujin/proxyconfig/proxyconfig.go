package proxyconfig

import (
	"fmt"
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type ProxyMessage struct {
	Action   string `json:"action"`
	Key      string `json:"key"`
	Host     string `json:"host"`
	HostData string `json:"hostdata"`
	Uuid     string `json:"uuid"`
}

type KeyData struct {
	Key          string
	Host         string
	HostData     string
	CurrentIndex int
}

func NewKeyData(key, host, hostdata string, currentindex int) *KeyData {
	return &KeyData{
		Key:          key,
		Host:         host,
		HostData:     hostdata,
		CurrentIndex: currentindex,
	}
}

type KeyRoutingTable struct {
	Keys map[string][]KeyData `json:"keys"`
}

func NewKeyRoutingTable() *KeyRoutingTable {
	return &KeyRoutingTable{
		Keys: make(map[string][]KeyData),
	}
}

type DomainRoutingTable struct {
	Domain map[string]string `json:"domain"`
}

func NewDomainRoutingTable() *DomainRoutingTable {
	return &DomainRoutingTable{
		Domain: make(map[string]string),
	}
}

type ProxyConfiguration struct {
	Session    *mgo.Session
	Collection *mgo.Collection
}

type Proxy struct {
	KeyRoutingTable    KeyRoutingTable
	DomainRoutingTable DomainRoutingTable
	Uuid               string
}

func NewProxy(uuid string) *Proxy {
	return &Proxy{
		KeyRoutingTable:    *NewKeyRoutingTable(),
		DomainRoutingTable: *NewDomainRoutingTable(),
		Uuid:               uuid,
	}
}

func Connect() (*ProxyConfiguration, error) {
	host := config.Current.Kontrold.Mongo.Host
	session, err := mgo.Dial(host)
	if err != nil {
		return nil, err
	}

	session.SetMode(mgo.Strong, true)

	col := session.DB("kontrol").C("proxies")

	pr := &ProxyConfiguration{
		Session:    session,
		Collection: col,
	}

	return pr, nil
}

// Base INSERT/CREATE crud action
func (p *ProxyConfiguration) Add(proxy Proxy) error {
	err := p.Collection.Insert(proxy)
	if err != nil {
		return err
	}
	return nil
}
func (p *ProxyConfiguration) AddProxy(uuid string) error {
	err := p.HasUuid(uuid)
	if err == nil {
		return fmt.Errorf("registering not possible uuid '%s' uuid exists.", uuid)
	}

	proxy := *NewProxy(uuid)
	err = p.Add(proxy)
	if err != nil {
		return err
	}
	return nil
}

// Base DELETE crud action
func (p *ProxyConfiguration) Delete(uuid string) error {
	err := p.Collection.Remove(bson.M{"uuid": uuid})
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteProxy(uuid string) error {
	err := p.HasUuid(uuid)
	if err != nil {
		return fmt.Errorf("deleting not possible '%s'", err)
	}

	err = p.Delete(uuid)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteKey(key, host, hostdata, uuid string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return err
		return fmt.Errorf("deleting key not possible '%s'", err)
	}

	delete(proxy.KeyRoutingTable.Keys, key)

	err = p.UpdateProxy(proxy)
	if err != nil {
		return err
	}

	return nil
}

func (p *ProxyConfiguration) UpdateProxy(proxy Proxy) error {
	err := p.Collection.Update(bson.M{"uuid": proxy.Uuid}, proxy)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) AddKey(key, host, hostdata, uuid string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("adding key not possible '%s'", err)
	}

	if len(proxy.KeyRoutingTable.Keys) == 0 { // empty routing table, add it
		proxy.KeyRoutingTable.Keys[key] = append(proxy.KeyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, 0))
		err = p.UpdateProxy(proxy)
		if err != nil {
			return err
		}
		return nil
	}

	_, ok := proxy.KeyRoutingTable.Keys[key] // new key, add it
	if !ok {
		proxy.KeyRoutingTable.Keys[key] = append(proxy.KeyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, 0))
		err = p.UpdateProxy(proxy)
		if err != nil {
			return err
		}
		return nil
	}

	// check for existing hostnames, if exist abort
	for _, value := range proxy.KeyRoutingTable.Keys[key] {
		if value.Host == host {
			return nil
		}
	}

	proxy.KeyRoutingTable.Keys[key] = append(proxy.KeyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, 0))

	err = p.UpdateProxy(proxy)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) HasUuid(uuid string) error {
	result := Proxy{}
	err := p.Collection.Find(bson.M{"uuid": uuid}).One(&result)
	if err != nil {
		return fmt.Errorf("no proxy with the uuid %s exist.", uuid)
	}
	return nil
}

func (p *ProxyConfiguration) GetProxy(uuid string) (Proxy, error) {
	result := Proxy{}
	err := p.Collection.Find(bson.M{"uuid": uuid}).One(&result)
	if err != nil {
		return result, fmt.Errorf("no proxy with the uuid %s exist.", uuid)
	}

	return result, nil

}
