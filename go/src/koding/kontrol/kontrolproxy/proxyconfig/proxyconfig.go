package proxyconfig

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/bradfitz/gomemcache/memcache"
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"strings"
)

const CACHE_TIMEOUT = 60 //seconds

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

type UserProxy struct {
	Services map[string]KeyRoutingTable
}

type Domain struct {
	Domainname  string
	Mode        string
	Username    string
	Servicename string
	Key         string
	FullUrl     string
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
	Uuid         string
	RoutingTable map[string]UserProxy
	Domains      []Domain `json:"domains"`
	Rules        map[string]UserRules
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

func NewDomain(domainname, mode, username, servicename, key, fullurl string) *Domain {
	return &Domain{
		Domainname:  domainname,
		Mode:        mode,
		Username:    username,
		Servicename: servicename,
		Key:         key,
		FullUrl:     fullurl,
	}
}

func NewProxy(uuid string) *Proxy {
	return &Proxy{
		Uuid:         uuid,
		RoutingTable: make(map[string]UserProxy),
		Domains:      make([]Domain, 0),
		Rules:        make(map[string]UserRules),
	}
}

func NewUserProxy() *UserProxy {
	return &UserProxy{
		Services: make(map[string]KeyRoutingTable),
	}
}

type ProxyConfiguration struct {
	Session    *mgo.Session
	Collection *mgo.Collection
	MemCache   *memcache.Client
}

func Connect() (*ProxyConfiguration, error) {
	host := config.Current.Kontrold.Mongo.Host
	session, err := mgo.Dial(host)
	if err != nil {
		return nil, err
	}
	session.SetMode(mgo.Strong, true)

	col := session.DB("kontrol").C("proxies")
	mc := memcache.New("127.0.0.1:11211", "127.0.0.1:11211")

	pr := &ProxyConfiguration{
		Session:    session,
		Collection: col,
		MemCache:   mc,
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

func (p *ProxyConfiguration) AddDomain(domainname, mode, username, servicename, key, fullurl, uuid string) error {
	proxy, err := p.GetProxy(uuid)
	if err != nil {
		return fmt.Errorf("Error: '%s' while adding the domain: " + domainname + ", for proxy: " + uuid, err)
	}
	
	domain, err := p.GetDomain(uuid, domainname)
	if err != nil {
		return fmt.Errorf("Error: '%s' while adding the domain: " + domainname + ", for proxy: " + uuid, err)
	} else if domain.Domainname != "" {
		return errors.New("Domain already exists: " + domainname + ", for proxy: " + uuid)
	}
	proxy.Domains = append(proxy.Domains, *NewDomain(domainname, mode, username, servicename, key, fullurl))

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

	// check for existing hostnames, if exist abort.
	if name != "broker" {
		for _, value := range keyRoutingTable.Keys[key] {
			if value.Host == host {
				return nil
			}
		}
		keyRoutingTable.Keys[key] = append(keyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, rabbitkey, 0))
	} else { // delete old one and replace it
		delete(keyRoutingTable.Keys, key)
		keyRoutingTable.Keys[key] = append(keyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, rabbitkey, 0))
	}

	user.Services[name] = keyRoutingTable
	proxy.RoutingTable[username] = user
	err = p.UpdateProxy(proxy)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteDomain(uuid, domainname string) error {
	err := p.Collection.Update(
		bson.M{
			"uuid":         uuid,
			"domains.domainname": domainname},
		bson.M{"$pull": bson.M{"domains": bson.M{"domainname": domainname}}})
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

func (p *ProxyConfiguration) DeleteKey(uuid, username, name, key string) error {
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

func (p *ProxyConfiguration) GetProxies() []string {
	proxies := make([]string, 0)
	proxy := Proxy{}
	iter := p.Collection.Find(nil).Iter()
	for iter.Next(&proxy) {
		proxies = append(proxies, proxy.Uuid)

	}

	return proxies
}

func (p *ProxyConfiguration) GetProxy(uuid string) (Proxy, error) {
	result := Proxy{}
	err := p.Collection.Find(bson.M{"uuid": uuid}).One(&result)
	if err != nil {
		return result, fmt.Errorf("no proxy with the uuid %s exist.", uuid)
	}

	return result, nil
}

func (p *ProxyConfiguration) GetDomain(uuid, domainname string) (Domain, error) {
	mcKey := uuid + domainname
	it, err := p.MemCache.Get(mcKey)
	if err != nil {
		fmt.Println("get domain from mongo db")
		result, err := p.GetProxy(uuid)
		if err != nil {
			return Domain{}, err
		}

		if len(result.Domains) == 0 {
			return Domain{}, nil
		}

		for _, domain := range result.Domains {
			if domain.Domainname == domainname {
				data, err := json.Marshal(domain)
				if err != nil {
					fmt.Printf("could not marshall worker: %s", err)
				}

				p.MemCache.Set(&memcache.Item{
					Key:        mcKey,
					Value:      data,
					Expiration: int32(CACHE_TIMEOUT),
				})
				return domain, nil
			}
		}
	}

	fmt.Println("get domain from memcached")
	domain := Domain{}
	err = json.Unmarshal(it.Value, &domain)
	if err != nil {
		fmt.Printf("unmarshall memcached value: %s", err)
	}
	return domain, nil
}

func (p *ProxyConfiguration) GetKeyList(uuid, username, servicename string) (map[string][]KeyData, error) {
	mcKey := uuid + username + servicename
	it, err := p.MemCache.Get(mcKey)
	if err != nil {
		fmt.Println("get keylist from mongo db")
		result := Proxy{}
		keyPath := fmt.Sprintf("routingtable.%s.services.%s", username, servicename)
		err := p.Collection.Find(bson.M{"uuid": uuid, keyPath: bson.M{"$exists": true}}).One(&result)
		if err != nil {
			return nil, fmt.Errorf("mongo lookup %s", err.Error())
		}

		for _, value := range result.RoutingTable {
			for name, v := range value.Services {
				if name == servicename {

					data, err := json.Marshal(v.Keys)
					if err != nil {
						fmt.Printf("could not marshall worker: %s", err)
					}

					p.MemCache.Set(&memcache.Item{
						Key:        mcKey,
						Value:      data,
						Expiration: int32(CACHE_TIMEOUT),
					})
					return v.Keys, nil
				}
			}
		}
	}

	fmt.Println("get keylist from memcached")

	keyList := make(map[string][]KeyData)
	err = json.Unmarshal(it.Value, &keyList)
	if err != nil {
		fmt.Printf("unmarshall memcached value: %s", err)
	}

	return keyList, nil
}

func (p *ProxyConfiguration) GetKey(uuid, username, servicename, key string) ([]KeyData, error) {
	keyList, err := p.GetKeyList(uuid, username, servicename)
	if err != nil {
		return nil, fmt.Errorf("mongo lookup %s", err.Error())

	}

	keyData, ok := keyList[key]
	if !ok {
		return nil, fmt.Errorf("no keys data available for the username %s, service %s and key %s exist.", username, servicename, key)
	}

	return keyData, nil
}

func (p *ProxyConfiguration) GetRules(uuid string) (map[string]UserRules, error) {
	mcKey := uuid + "kontrolproxyrules"
	it, err := p.MemCache.Get(mcKey)
	if err != nil {
		fmt.Println("get rules from memcached")
		result := Proxy{}
		err := p.Collection.Find(bson.M{"uuid": uuid, "rules": bson.M{"$exists": true}}).Select(bson.M{"rules": 1}).One(&result)
		if err != nil {
			return nil, fmt.Errorf("mongo lookup %s", err.Error())
		}

		if len(result.Rules) == 0 {
			return nil, errors.New("rule is not created yet")
		}

		data, err := json.Marshal(result.Rules)
		if err != nil {
			fmt.Printf("could not marshall worker: %s", err)
		}

		p.MemCache.Set(&memcache.Item{
			Key:        mcKey,
			Value:      data,
			Expiration: int32(CACHE_TIMEOUT),
		})
	}

	fmt.Println("get rules from memcached")

	rules := make(map[string]UserRules)
	err = json.Unmarshal(it.Value, &rules)
	if err != nil {
		fmt.Printf("unmarshall memcached value: %s", err)
	}

	return rules, nil
}

func (p *ProxyConfiguration) GetRulesUsers(uuid string) ([]string, error) {
	res, err := p.GetRules(uuid)
	if err != nil {
		return nil, fmt.Errorf("mongo lookup %s", err.Error())
	}

	users := make([]string, 0)
	for username := range res {
		users = append(users, username)
	}

	return users, nil
}

func (p *ProxyConfiguration) GetRulesServices(uuid, username string) ([]string, error) {
	res, err := p.GetRules(uuid)
	if err != nil {
		return nil, fmt.Errorf("mongo lookup %s", err.Error())
	}

	services := make([]string, 0)
	rules := res[username]
	for name, _ := range rules.Services {
		services = append(services, name)
	}

	return services, nil
}

func (p *ProxyConfiguration) GetRule(uuid, username, servicename string) (Restriction, error) {
	res, err := p.GetRules(uuid)
	if err != nil {
		return Restriction{}, fmt.Errorf("mongo lookup %s", err.Error())
	}

	rules := res[username]
	return rules.Services[servicename], nil
}
