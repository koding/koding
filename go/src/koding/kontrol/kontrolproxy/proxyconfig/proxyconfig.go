package proxyconfig

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/bradfitz/gomemcache/memcache"
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
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

type Config struct {
	RoutingTable map[string]UserProxy
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

func NewConfig() *Config {
	return &Config{
		RoutingTable: make(map[string]UserProxy),
	}
}

func NewUserProxy() *UserProxy {
	return &UserProxy{
		Services: make(map[string]KeyRoutingTable),
	}
}

type ProxyConfiguration struct {
	Session    *mgo.Session
	Collection map[string]*mgo.Collection
	MemCache   *memcache.Client
	Config     Config
}

func Connect() (*ProxyConfiguration, error) {
	session, err := mgo.Dial(config.Current.Kontrold.Mongo.Host)
	if err != nil {
		return nil, err
	}
	session.SetMode(mgo.Strong, true)
	session.SetSafe(&mgo.Safe{})

	collections := make(map[string]*mgo.Collection)
	collections["proxies"] = session.DB("kontrol").C("pProxies")
	collections["domains"] = session.DB("kontrol").C("pDomains")
	collections["rules"] = session.DB("kontrol").C("pRules")
	collections["domainstats"] = session.DB("kontrol").C("pDomainStats")
	collections["proxystats"] = session.DB("kontrol").C("pProxyStats")
	collections["default"] = session.DB("kontrol").C("proxies")

	mc := memcache.New("127.0.0.1:11211", "127.0.0.1:11211")

	config := Config{}
	err = collections["default"].Find(nil).One(&config)
	if err != nil {
		config = *NewConfig()
	}

	pr := &ProxyConfiguration{
		Session:    session,
		Collection: collections,
		MemCache:   mc,
		Config:     config,
	}

	return pr, nil
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
	err := p.Collection["default"].Update(bson.M{}, config)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) GetConfig() (Config, error) {
	config := Config{}
	err := p.Collection["default"].Find(nil).One(&config)
	if err != nil {
		return config, fmt.Errorf("no config exists: '%s'", err)
	}

	return config, nil
}
func (p *ProxyConfiguration) GetKeyList(username, servicename string) (map[string][]KeyData, error) {
	mcKey := username + servicename + "keylist"
	it, err := p.MemCache.Get(mcKey)
	if err != nil {
		config := Config{}
		keyPath := fmt.Sprintf("routingtable.%s.services.%s", username, servicename)
		err := p.Collection["default"].Find(bson.M{keyPath: bson.M{"$exists": true}}).One(&config)
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
