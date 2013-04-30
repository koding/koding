package proxyconfig

import (
	"errors"
	"fmt"
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type ProxyMessage struct {
	Action      string `json:"action"`
	DomainName  string `json:"domainName"`
	ServiceName string `json:"serviceName"`
	Key         string `json:"key"`
	RabbitKey   string `json:"rabbitKey"`
	Host        string `json:"host"`
	HostData    string `json:"hostdata"`
	Uuid        string `json:"uuid"`
}

type ProxyResponse struct {
	Action string `json:"action"`
	Uuid   string `json:"uuid"`
}

type KeyData struct {
	Key          string
	Host         string
	HostData     string
	CurrentIndex int
	RabbitKey    string
}

func NewKeyData(key, host, hostdata, rabbitkey string, currentindex int) *KeyData {
	return &KeyData{
		Key:          key,
		Host:         host,
		HostData:     hostdata,
		CurrentIndex: currentindex,
		RabbitKey:    rabbitkey,
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

type DomainData struct {
	Name    string
	Key     string
	FullUrl string
}

func NewDomainData(name, key, fullurl string) *DomainData {
	return &DomainData{
		Name:    name,
		Key:     key,
		FullUrl: fullurl,
	}
}

type DomainRoutingTable struct {
	Domains map[string]DomainData `json:"domains"`
}

func NewDomainRoutingTable() *DomainRoutingTable {
	return &DomainRoutingTable{
		Domains: make(map[string]DomainData),
	}
}

type Proxy struct {
	Services           map[string]KeyRoutingTable
	DomainRoutingTable DomainRoutingTable
	Uuid               string
}

func NewProxy(uuid string) *Proxy {
	return &Proxy{
		Services:           make(map[string]KeyRoutingTable),
		DomainRoutingTable: *NewDomainRoutingTable(),
		Uuid:               uuid,
	}
}

type ProxyConfiguration struct {
	Session    *mgo.Session
	Collection *mgo.Collection
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

func (p *ProxyConfiguration) DeleteName(name, key, host, hostdata, uuid string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("deleting key not possible '%s'", err)
	}

	_, ok := proxy.Services[name]
	if !ok {
		return errors.New("service name is wrong. deleting key is not possible")

	}

	delete(proxy.Services, name)
	err = p.UpdateProxy(proxy)
	if err != nil {
		return err
	}

	return nil
}

func (p *ProxyConfiguration) DeleteKey(name, key, host, hostdata, uuid string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("deleting key not possible '%s'", err)
	}

	_, ok := proxy.Services[name]
	if !ok {
		return errors.New("service name is wrong. deleting key is not possible")

	}

	keyRoutingTable := proxy.Services[name]
	delete(keyRoutingTable.Keys, key)

	proxy.Services[name] = keyRoutingTable
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

func (p *ProxyConfiguration) AddDomain(domainname, servicename, key, fullurl, uuid string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("adding domain not possible '%s'", err)
	}

	_, ok := proxy.DomainRoutingTable.Domains[domainname]
	if !ok {
		proxy.DomainRoutingTable.Domains[domainname] = *NewDomainData(servicename, key, fullurl)
	}

	// domainMap := proxy.DomainRoutingTable.Domain
	// proxy.DomainRoutingTable.Domain = domainMap
	err = p.UpdateProxy(proxy)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) AddKey(name, key, host, hostdata, uuid, rabbitkey string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("adding key not possible '%s'", err)
	}

	_, ok := proxy.Services[name]
	if !ok {
		proxy.Services[name] = *NewKeyRoutingTable()
	}
	keyRoutingTable := proxy.Services[name]

	if len(keyRoutingTable.Keys) == 0 { // empty routing table, add it
		keyRoutingTable.Keys[key] = append(keyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, rabbitkey, 0))
		proxy.Services[name] = keyRoutingTable
		err = p.UpdateProxy(proxy)
		if err != nil {
			return err
		}
		return nil
	}

	_, ok = keyRoutingTable.Keys[key] // new key, add it
	if !ok {
		keyRoutingTable.Keys[key] = append(keyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, rabbitkey, 0))
		proxy.Services[name] = keyRoutingTable
		err = p.UpdateProxy(proxy)
		if err != nil {
			return err
		}
		return nil
	}

	// check for existing hostnames, if exist abort
	for _, value := range keyRoutingTable.Keys[key] {
		if value.Host == host {
			return nil
		}
	}

	keyRoutingTable.Keys[key] = append(keyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, rabbitkey, 0))

	proxy.Services[name] = keyRoutingTable
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
