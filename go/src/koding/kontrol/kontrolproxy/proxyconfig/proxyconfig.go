package proxyconfig

import (
	"errors"
	"fmt"
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"strings"
)

type ProxyMessage struct {
	Action      string `json:"action"`
	DomainName  string `json:"domainName"`
	ServiceName string `json:"serviceName"`
	Username    string `json:"username"`
	Key         string `json:"key"`
	RabbitKey   string `json:"rabbitKey"`
	Host        string `json:"host"`
	HostData    string `json:"hostdata"`
	Uuid        string `json:"uuid"`
	RuleName    string `json:"rulename"`
	Rule        string `json:"rule"`
	RuleEnabled bool   `json:"enabled"`
	RuleMode    string `json:"mode"`
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

type KeyRoutingTable struct {
	Keys map[string][]KeyData `json:"keys"`
}

func NewKeyRoutingTable() *KeyRoutingTable {
	return &KeyRoutingTable{
		Keys: make(map[string][]KeyData),
	}
}

type DomainData struct {
	Username string
	Name     string
	Key      string
	FullUrl  string
}

type DomainRoutingTable struct {
	Domains map[string]DomainData `json:"domains"`
}

type UserProxy struct {
	Services map[string]KeyRoutingTable
}

type Restriction struct {
	IP struct {
		Enabled bool   // To disable or enable current rule
		Mode    string // Rule is either allowing matches or denying
		Rule    string // Regex string
	}
	Country struct {
		Enabled bool
		Mode    string   // Rule is either allowing matches or denying
		Rule    []string // A slice of country names, i.e.:["Turkey", "Germany"]
	}
}

type UserRules struct {
	Services map[string]Restriction
}

type Proxy struct {
	Uuid               string
	RoutingTable       map[string]UserProxy
	DomainRoutingTable DomainRoutingTable
	Rules              map[string]UserRules
}

type ProxyConfiguration struct {
	Session    *mgo.Session
	Collection *mgo.Collection
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

func NewDomainData(username, name, key, fullurl string) *DomainData {
	return &DomainData{
		Username: username,
		Name:     name,
		Key:      key,
		FullUrl:  fullurl,
	}
}

func NewProxy(uuid string) *Proxy {
	return &Proxy{
		Uuid:               uuid,
		RoutingTable:       make(map[string]UserProxy),
		DomainRoutingTable: *NewDomainRoutingTable(),
		Rules:              make(map[string]UserRules),
	}
}

func NewUserProxy() *UserProxy {
	return &UserProxy{
		Services: make(map[string]KeyRoutingTable),
	}
}

func NewDomainRoutingTable() *DomainRoutingTable {
	return &DomainRoutingTable{
		Domains: make(map[string]DomainData),
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

func (p *ProxyConfiguration) AddUser(uuid, username string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("adding user is not possible '%s'", err)
	}

	proxy.RoutingTable[username] = *NewUserProxy()

	err = p.UpdateProxy(proxy)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) AddDomain(username, domainname, servicename, key, fullurl, uuid string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("adding domain is not possible '%s'", err)
	}

	_, ok := proxy.DomainRoutingTable.Domains[domainname]
	if !ok {
		proxy.DomainRoutingTable.Domains[domainname] = *NewDomainData(username, servicename, key, fullurl)
	}

	err = p.UpdateProxy(proxy)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) AddRule(uuid, username, servicename, rulename, rule, mode string, enabled bool) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("adding key is not possible. '%s'", err)
	}

	if proxy.Rules == nil {
		proxy.Rules = make(map[string]UserRules)
	}

	_, ok := proxy.Rules[username]
	if !ok {
		proxy.Rules[username] = UserRules{Services: make(map[string]Restriction)}
	}
	rules := proxy.Rules[username]

	_, ok = rules.Services[servicename]
	if !ok {
		rules.Services[servicename] = Restriction{}
	}

	restriction := rules.Services[servicename]

	switch rulename {
	case "ip", "file":
		restriction.IP.Enabled = enabled
		restriction.IP.Mode = mode
		restriction.IP.Rule = strings.TrimSpace(rule)
	case "domain":
		restriction.Country.Enabled = enabled
		restriction.Country.Mode = mode
		cList := make([]string, 0)
		list := strings.Split(rule, ",")
		for _, country := range list {
			cList = append(cList, strings.TrimSpace(country))
		}
		restriction.Country.Rule = cList
	}

	rules.Services[servicename] = restriction
	proxy.Rules[username] = rules
	err = p.UpdateProxy(proxy)
	if err != nil {
		return err
	}
	return nil
}
func (p *ProxyConfiguration) AddKey(username, name, key, host, hostdata, uuid, rabbitkey string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("adding key is not possible. '%s'", err)
	}

	_, ok := proxy.RoutingTable[username]
	if !ok {
		proxy.RoutingTable[username] = *NewUserProxy()
	}
	user := proxy.RoutingTable[username]

	_, ok = user.Services[name]
	if !ok {
		user.Services[name] = *NewKeyRoutingTable()
	}
	keyRoutingTable := user.Services[name]

	if len(keyRoutingTable.Keys) == 0 { // empty routing table, add it
		keyRoutingTable.Keys[key] = append(keyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, rabbitkey, 0))
		user.Services[name] = keyRoutingTable
		proxy.RoutingTable[username] = user
		err = p.UpdateProxy(proxy)
		if err != nil {
			return err
		}
		return nil
	}

	_, ok = keyRoutingTable.Keys[key] // new key, add it
	if !ok {
		keyRoutingTable.Keys[key] = append(keyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, rabbitkey, 0))
		user.Services[name] = keyRoutingTable
		proxy.RoutingTable[username] = user
		err = p.UpdateProxy(proxy)
		if err != nil {
			return err
		}
		return nil
	}

	// delete old key
	delete(keyRoutingTable.Keys, key)

	// and replace it with the new one
	keyRoutingTable.Keys[key] = append(keyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, rabbitkey, 0))

	/* check for existing hostnames, if exist abort. Comment out if you want
	 add multiple entities for a single key. Useful to use  round-robin.
	for _, value := range keyRoutingTable.Keys[key] {
	    if value.Host == host {
	        return nil
	    }
	}
	keyRoutingTable.Keys[key] = append(keyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, rabbitkey, 0))
	*/

	user.Services[name] = keyRoutingTable
	proxy.RoutingTable[username] = user
	err = p.UpdateProxy(proxy)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteDomain(domainname, uuid string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("deleting domain not possible '%s'", err)
	}

	_, ok := proxy.DomainRoutingTable.Domains[domainname]
	if !ok {
		return errors.New("deleting domain is not possible. domain name is wrong")
	}

	delete(proxy.DomainRoutingTable.Domains, domainname)
	err = p.UpdateProxy(proxy)
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

func (p *ProxyConfiguration) DeleteServiceName(username, name, uuid string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("deleting key not possible '%s'", err)
	}

	_, ok := proxy.RoutingTable[username]
	if !ok {
		return fmt.Errorf("deleting key is not possible. no user %s exists", username)
	}
	user := proxy.RoutingTable[username]

	_, ok = user.Services[name]
	if !ok {
		return errors.New("service name is wrong. deleting service is not possible")
	}

	delete(user.Services, name)

	proxy.RoutingTable[username] = user
	err = p.UpdateProxy(proxy)
	if err != nil {
		return err
	}

	return nil
}

func (p *ProxyConfiguration) DeleteKey(username, name, key, host, hostdata, uuid string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("deleting key not possible '%s'", err)
	}

	_, ok := proxy.RoutingTable[username]
	if !ok {
		return fmt.Errorf("deleting key is not possible. no user %s exists", username)
	}
	user := proxy.RoutingTable[username]

	_, ok = user.Services[name]
	if !ok {
		return errors.New("deleting key is not possible. service name is wrong.")
	}

	keyRoutingTable := user.Services[name]
	delete(keyRoutingTable.Keys, key)

	user.Services[name] = keyRoutingTable

	proxy.RoutingTable[username] = user
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
