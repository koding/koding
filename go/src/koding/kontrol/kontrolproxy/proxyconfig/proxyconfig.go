package proxyconfig

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/bradfitz/gomemcache/memcache"
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"strconv"
	"strings"
	"time"
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

type Proxy struct {
	Name string
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

type DomainStat struct {
	Request map[string]int
}

type ProxyStat struct {
	Country map[string]int
	Ip      map[string]int
	Request map[string]int
}

type Stats struct {
	Domains map[string]DomainStat
	Proxies map[string]ProxyStat
}

type Config struct {
	Proxies      []Proxy
	RoutingTable map[string]UserProxy
	Domains      []Domain `json:"domains"`
	Rules        map[string]UserRules
	Stats        Stats
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

func NewProxy(name string) *Proxy {
	return &Proxy{
		Name: name,
	}
}

func NewStats() *Stats {
	return &Stats{
		Domains: make(map[string]DomainStat),
		Proxies: make(map[string]ProxyStat),
	}
}

func NewConfig() *Config {
	return &Config{
		Proxies:      make([]Proxy, 0),
		RoutingTable: make(map[string]UserProxy),
		Domains:      make([]Domain, 0),
		Rules:        make(map[string]UserRules),
		Stats:        *NewStats(),
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
	Config     Config
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

	config := Config{}
	err = col.Find(nil).One(&config)
	if err != nil {
		config = *NewConfig()
	}

	pr := &ProxyConfiguration{
		Session:    session,
		Collection: col,
		MemCache:   mc,
		Config:     config,
	}

	return pr, nil
}

func (p *ProxyConfiguration) AddProxy(proxyname string) error {
	config, err := p.GetConfig()
	if err != nil {
		return fmt.Errorf("Error: '%s' while adding the proxy: '%s'", err, proxyname)
	}

	proxy, err := p.GetProxy(proxyname)
	if err != nil {
		return fmt.Errorf("Error: '%s' while adding the proxy: '%s'", err, proxyname)
	}

	if proxy.Name != "" {
		return fmt.Errorf("Error: proxy '%s' already exists", proxyname)
	}

	config.Proxies = append(config.Proxies, *NewProxy(proxyname))
	err = p.UpdateConfig(config)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) AddUser(username string) error {
	config, err := p.GetConfig()
	if err != nil {
		return fmt.Errorf("adding user is not possible '%s'", err)
	}

	config.RoutingTable[username] = *NewUserProxy()

	err = p.UpdateConfig(config)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) AddDomain(domainname, mode, username, servicename, key, fullurl string) error {
	config, err := p.GetConfig()
	if err != nil {
		return fmt.Errorf("Error: '%s' while adding the domain: '%s'", err, domainname)
	}

	domain, err := p.GetDomain(domainname)
	if err != nil {
		return fmt.Errorf("Error: '%s' while adding the domain: '%s'", err, domainname)
	}

	if domain.Domainname != "" {
		return fmt.Errorf("Error: domain '%s' already exist", domainname)
	}

	config.Domains = append(config.Domains, *NewDomain(domainname, mode, username, servicename, key, fullurl))

	err = p.UpdateConfig(config)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) AddRule(username, servicename, rulename, rule, mode string, enabled bool) error {
	config, err := p.GetConfig()
	if err != nil {
		return fmt.Errorf("adding key is not possible. '%s'", err)
	}

	if config.Rules == nil {
		config.Rules = make(map[string]UserRules)
	}

	_, ok := config.Rules[username]
	if !ok {
		config.Rules[username] = UserRules{Services: make(map[string]Restriction)}
	}
	rules := config.Rules[username]

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
	config.Rules[username] = rules
	err = p.UpdateConfig(config)
	if err != nil {
		return err
	}
	return nil
}
func (p *ProxyConfiguration) AddKey(username, name, key, host, hostdata, rabbitkey string) error {
	config, err := p.GetConfig()
	if err != nil {
		return fmt.Errorf("adding key is not possible. '%s'", err)
	}

	_, ok := config.RoutingTable[username]
	if !ok {
		config.RoutingTable[username] = *NewUserProxy()
	}
	user := config.RoutingTable[username]

	_, ok = user.Services[name]
	if !ok {
		user.Services[name] = *NewKeyRoutingTable()
	}
	keyRoutingTable := user.Services[name]

	if len(keyRoutingTable.Keys) == 0 { // empty routing table, add it
		keyRoutingTable.Keys[key] = append(keyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, rabbitkey, 0))
		user.Services[name] = keyRoutingTable
		config.RoutingTable[username] = user
		err = p.UpdateConfig(config)
		if err != nil {
			return err
		}
		return nil
	}

	_, ok = keyRoutingTable.Keys[key] // new key, add it
	if !ok {
		keyRoutingTable.Keys[key] = append(keyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, rabbitkey, 0))
		user.Services[name] = keyRoutingTable
		config.RoutingTable[username] = user
		err = p.UpdateConfig(config)
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
	config.RoutingTable[username] = user
	err = p.UpdateConfig(config)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteDomain(domainname string) error {
	err := p.Collection.Update(
		bson.M{"domains.domainname": domainname}, bson.M{"$pull": bson.M{"domains": bson.M{"domainname": domainname}}})
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteProxy(proxyname string) error {
	err := p.Collection.Update(
		bson.M{"proxies.name": proxyname}, bson.M{"$pull": bson.M{"proxies": bson.M{"name": proxyname}}})
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteServiceName(username, name string) error {
	config, err := p.GetConfig()
	if err != nil {
		return fmt.Errorf("deleting key not possible '%s'", err)
	}

	_, ok := config.RoutingTable[username]
	if !ok {
		return fmt.Errorf("deleting key is not possible. no user %s exists", username)
	}
	user := config.RoutingTable[username]

	_, ok = user.Services[name]
	if !ok {
		return errors.New("service name is wrong. deleting service is not possible")
	}

	delete(user.Services, name)

	config.RoutingTable[username] = user
	err = p.UpdateConfig(config)
	if err != nil {
		return err
	}

	return nil
}

func (p *ProxyConfiguration) DeleteKey(username, name, key string) error {
	config, err := p.GetConfig()
	if err != nil {
		return fmt.Errorf("deleting key not possible '%s'", err)
	}

	_, ok := config.RoutingTable[username]
	if !ok {
		return fmt.Errorf("deleting key is not possible. no user %s exists", username)
	}
	user := config.RoutingTable[username]

	_, ok = user.Services[name]
	if !ok {
		return errors.New("deleting key is not possible. service name is wrong.")
	}

	keyRoutingTable := user.Services[name]
	delete(keyRoutingTable.Keys, key)

	user.Services[name] = keyRoutingTable

	config.RoutingTable[username] = user
	err = p.UpdateConfig(config)
	if err != nil {
		return err
	}

	return nil
}

func (p *ProxyConfiguration) UpdateConfig(config Config) error {
	err := p.Collection.Update(bson.M{}, config)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) GetProxies() ([]Proxy, error) {
	config, err := p.GetConfig()
	if err != nil {
		return nil, err
	}

	return config.Proxies, nil
}

func (p *ProxyConfiguration) GetConfig() (Config, error) {
	config := Config{}
	err := p.Collection.Find(nil).One(&config)
	if err != nil {
		return config, fmt.Errorf("no config exists: '%s'", err)
	}

	return config, nil
}

func (p *ProxyConfiguration) GetProxy(proxyname string) (Proxy, error) {
	config := Config{}
	err := p.Collection.Find(nil).One(&config)
	if err != nil {
		return Proxy{}, fmt.Errorf("no proxy with the name %s exist.", proxyname)
	}

	if len(config.Proxies) == 0 {
		return Proxy{}, nil
	}
	for _, proxy := range config.Proxies {
		if proxy.Name == proxyname {
			return proxy, nil
		}
	}
	return Proxy{}, nil // no domain found
}

func (p *ProxyConfiguration) GetDomain(domainname string) (Domain, error) {
	mcKey := domainname + "kontroldomain"
	it, err := p.MemCache.Get(mcKey)
	if err != nil {
		config, err := p.GetConfig()
		if err != nil {
			return Domain{}, err
		}

		if len(config.Domains) == 0 {
			return Domain{}, nil
		}

		for _, domain := range config.Domains {
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
		return Domain{}, nil // no domain found
	}

	domain := Domain{}
	err = json.Unmarshal(it.Value, &domain)
	if err != nil {
		fmt.Printf("unmarshall memcached value: %s", err)
	}
	return domain, nil
}

func (p *ProxyConfiguration) GetKeyList(username, servicename string) (map[string][]KeyData, error) {
	mcKey := username + servicename + "keylist"
	it, err := p.MemCache.Get(mcKey)
	if err != nil {
		config := Config{}
		keyPath := fmt.Sprintf("routingtable.%s.services.%s", username, servicename)
		err := p.Collection.Find(bson.M{keyPath: bson.M{"$exists": true}}).One(&config)
		if err != nil {
			return nil, fmt.Errorf("lookup %s", err.Error())
		}

		for user, value := range config.RoutingTable {
			if user == username {
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
	}

	keyList := make(map[string][]KeyData)
	err = json.Unmarshal(it.Value, &keyList)
	if err != nil {
		fmt.Printf("unmarshall memcached value: %s", err)
	}

	return keyList, nil
}

func (p *ProxyConfiguration) GetKey(username, servicename, key string) ([]KeyData, error) {
	keyList, err := p.GetKeyList(username, servicename)
	if err != nil {
		return nil, fmt.Errorf("lookup %s", err.Error())

	}

	keyData, ok := keyList[key]
	if !ok {
		return nil, fmt.Errorf("no key '%s' available for username '%s' and service '%s'", key, username, servicename)
	}

	return keyData, nil
}

func (p *ProxyConfiguration) GetRules() (map[string]UserRules, error) {
	mcKey := "kontrolproxyrules"
	it, err := p.MemCache.Get(mcKey)
	if err != nil {
		config := Config{}
		err := p.Collection.Find(bson.M{"rules": bson.M{"$exists": true}}).Select(bson.M{"rules": 1}).One(&config)
		if err != nil {
			return nil, fmt.Errorf("lookup %s", err.Error())
		}

		if len(config.Rules) == 0 {
			return nil, errors.New("rule is not created yet")
		}

		data, err := json.Marshal(config.Rules)
		if err != nil {
			fmt.Printf("could not marshall worker: %s", err)
		}

		p.MemCache.Set(&memcache.Item{
			Key:        mcKey,
			Value:      data,
			Expiration: int32(CACHE_TIMEOUT),
		})

		return config.Rules, nil
	}

	rules := make(map[string]UserRules)
	err = json.Unmarshal(it.Value, &rules)
	if err != nil {
		fmt.Printf("unmarshall memcached value: %s", err)
	}

	return rules, nil
}

func (p *ProxyConfiguration) GetRulesUsers() ([]string, error) {
	res, err := p.GetRules()
	if err != nil {
		return nil, fmt.Errorf("lookup %s", err.Error())
	}

	users := make([]string, 0)
	for username := range res {
		users = append(users, username)
	}

	return users, nil
}

func (p *ProxyConfiguration) GetRulesServices(username string) ([]string, error) {
	res, err := p.GetRules()
	if err != nil {
		return nil, fmt.Errorf("lookup %s", err.Error())
	}

	services := make([]string, 0)
	rules := res[username]
	for name, _ := range rules.Services {
		services = append(services, name)
	}

	return services, nil
}

func (p *ProxyConfiguration) GetRule(username, servicename string) (Restriction, error) {
	res, err := p.GetRules()
	if err != nil {
		return Restriction{}, fmt.Errorf("lookup %s", err.Error())
	}

	rules := res[username]
	return rules.Services[servicename], nil
}

func (p *ProxyConfiguration) DeleteStats() error {
	config, err := p.GetConfig()
	if err != nil {
		return fmt.Errorf("error: '%s' while getting domains statistics", err)
	}

	config.Stats = *NewStats()
	err = p.UpdateConfig(config)
	if err != nil {
		return err
	}

	return nil
}

func (p *ProxyConfiguration) GetStats() (Stats, error) {
	config, err := p.GetConfig()
	if err != nil {
		return Stats{}, fmt.Errorf("error: '%s' while getting domains statistics", err)
	}

	return config.Stats, nil
}

func (p *ProxyConfiguration) GetDomainStats() (map[string]DomainStat, error) {
	config, err := p.GetConfig()
	if err != nil {
		return nil, fmt.Errorf("error: '%s' while getting domains statistics", err)
	}

	return config.Stats.Domains, nil
}

func (p *ProxyConfiguration) GetSingleDomainStats(domainname string) (DomainStat, error) {
	config, err := p.GetConfig()
	if err != nil {
		return DomainStat{}, fmt.Errorf("error: '%s' while getting domain statistics for '%s'", err, domainname)
	}

	return config.Stats.Domains[domainname], nil
}

func (p *ProxyConfiguration) GetProxyStats() (map[string]ProxyStat, error) {
	config, err := p.GetConfig()
	if err != nil {
		return nil, fmt.Errorf("error: '%s' while getting proxies statistics", err)
	}

	return config.Stats.Proxies, nil
}

func (p *ProxyConfiguration) GetSingleProxyStats(proxyname string) (ProxyStat, error) {
	config, err := p.GetConfig()
	if err != nil {
		return ProxyStat{}, fmt.Errorf("error: '%s' while getting domain statistics for '%s'", err, proxyname)
	}

	return config.Stats.Proxies[proxyname], nil
}

func (p *ProxyConfiguration) AddStatistics(ip, country, proxy, domainname string) error {
	config, err := p.GetConfig()
	if err != nil {
		return fmt.Errorf("error: '%s' while adding statistics", err)
	}

	nowHour := strconv.Itoa(time.Now().Hour()) + ":00"

	if config.Stats.Domains == nil {
		config.Stats.Domains = make(map[string]DomainStat)
	}
	if config.Stats.Proxies == nil {
		config.Stats.Proxies = make(map[string]ProxyStat)
	}
	// DomainStats
	if domainname != "" {
		_, ok := config.Stats.Domains[domainname]
		if !ok {
			config.Stats.Domains[domainname] = DomainStat{Request: make(map[string]int)}
		}
		domainStat := config.Stats.Domains[domainname]

		_, ok = domainStat.Request[nowHour]
		if !ok {
			domainStat.Request[nowHour] = 1
		} else {
			domainStat.Request[nowHour]++
		}
		config.Stats.Domains[domainname] = domainStat
	}

	// ProxyStats
	_, ok := config.Stats.Proxies[proxy]
	if !ok {
		config.Stats.Proxies[proxy] = ProxyStat{
			Country: make(map[string]int),
			Ip:      make(map[string]int),
			Request: make(map[string]int),
		}
	}
	proxyStat := config.Stats.Proxies[proxy]

	_, ok = proxyStat.Request[nowHour]
	if !ok {
		proxyStat.Request[nowHour] = 1
	} else {
		proxyStat.Request[nowHour]++
	}

	if ip != "" {
		_, ok = proxyStat.Ip[ip]
		if !ok {
			proxyStat.Ip[ip] = 1
		} else {
			proxyStat.Ip[ip]++
		}
	}

	if country != "" {
		_, ok = proxyStat.Country[country]
		if !ok {
			proxyStat.Country[country] = 1
		} else {
			proxyStat.Country[country]++
		}
	}
	config.Stats.Proxies[proxy] = proxyStat

	// Update/Insert statistics
	err = p.UpdateConfig(config)
	if err != nil {
		return err
	}
	return nil
}
