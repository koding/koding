package proxyconfig

import (
	"encoding/json"
	"fmt"
	"github.com/bradfitz/gomemcache/memcache"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"sort"
	"strconv"
)

const SERVICE_CACHE_TIMEOUT = 60 //seconds

type KeyData struct {
	// Versioning of hosts
	Key string

	// List of hosts to proxy
	Host []string

	// load-balancing, sticky or roundrobin
	Mode string `json:"mode"`

	// current index of hosts. Updated automatically in roundrobin
	// change manually when using sticky mode
	CurrentIndex int `json:"currentindex"`

	// future usage...
	HostData string

	// future usage, proxy via mq
	RabbitKey string
}

type KeyRoutingTable struct {
	Keys map[string]KeyData `json:"keys"`
}

type Service struct {
	Id       bson.ObjectId              `bson:"_id" json:"-"`
	Username string                     `bson:"username", json:"username"`
	Services map[string]KeyRoutingTable `bson:"services", json:"services"`
}

func NewKeyRoutingTable() *KeyRoutingTable {
	return &KeyRoutingTable{
		Keys: make(map[string]KeyData),
	}
}

func NewKeyData(key, mode, hostdata, rabbitkey string, host []string, currentindex int) *KeyData {
	return &KeyData{
		Key:          key,
		Host:         host,
		Mode:         mode,
		HostData:     hostdata,
		CurrentIndex: currentindex,
		RabbitKey:    rabbitkey,
	}
}

func NewService(username string) *Service {
	return &Service{
		Id:       bson.NewObjectId(),
		Username: username,
		Services: make(map[string]KeyRoutingTable),
	}
}

func (p *ProxyConfiguration) GetServices() []Service {
	service := Service{}
	services := make([]Service, 0)
	iter := p.Collection["services"].Find(nil).Iter()
	for iter.Next(&service) {
		services = append(services, service)
	}

	return services
}

func (p *ProxyConfiguration) GetService(username string) (Service, error) {
	mcKey := username + "servicename"
	it, err := p.MemCache.Get(mcKey)
	if err != nil {
		service := Service{}
		err := p.Collection["services"].Find(bson.M{"username": username}).One(&service)
		if err != nil {
			return service, err
		}

		data, err := json.Marshal(service)
		if err != nil {
			fmt.Printf("could not marshall worker: %s", err)
		}

		p.MemCache.Set(&memcache.Item{
			Key:        mcKey,
			Value:      data,
			Expiration: int32(SERVICE_CACHE_TIMEOUT),
		})

		return service, nil
	}

	service := Service{}
	err = json.Unmarshal(it.Value, &service)
	if err != nil {
		fmt.Printf("unmarshall memcached value: %s", err)
	}
	return service, nil
}

func (p *ProxyConfiguration) GetKey(username, servicename, key string) (KeyData, error) {
	service, err := p.GetService(username)
	if err != nil {
		return KeyData{}, err
	}

	keyRoutingTable, ok := service.Services[servicename]
	if !ok {
		return KeyData{}, fmt.Errorf("getting key is not possible, servicename %s does not exist", servicename)
	}

	if key == "latest" {
		// get all keys and sort them
		lenKeys := len(keyRoutingTable.Keys)
		listOfKeys := make([]int, lenKeys)
		i := 0
		for k, _ := range keyRoutingTable.Keys {
			listOfKeys[i], _ = strconv.Atoi(k)
			i++
		}
		sort.Ints(listOfKeys)

		// give precedence to the largest key number
		key = strconv.Itoa(listOfKeys[len(listOfKeys)-1])
	}

	keyData, ok := keyRoutingTable.Keys[key]
	if !ok {
		return KeyData{}, fmt.Errorf("no key '%s' available for username '%s', service '%s'", key, username, servicename)
	}

	return keyData, nil
}

// Update or add a key. service and username will be created if not available
func (p *ProxyConfiguration) UpsertKey(username, mode, servicename, key, host, hostdata, rabbitkey string, currentindex int) error {
	service, err := p.GetService(username)
	if err != nil {
		if err != mgo.ErrNotFound {
			return err
		}
		service = *NewService(username)
	}

	_, ok := service.Services[servicename]
	if !ok {
		service.Services[servicename] = *NewKeyRoutingTable()
	}
	keyRoutingTable := service.Services[servicename]

	_, ok = keyRoutingTable.Keys[key] // empty routing table or not existing key
	if !ok {
		hosts := []string{host}
		keyRoutingTable.Keys[key] = *NewKeyData(key, mode, hostdata, rabbitkey, hosts, 0)
		service.Services[servicename] = keyRoutingTable
		err = p.UpsertService(username, service)
		if err != nil {
			return err
		}
		return nil
	}

	keyData := keyRoutingTable.Keys[key]
	hasHost := false
	for _, hostname := range keyData.Host {
		if hostname == host {
			hasHost = true // don't append an already added host
			break
		}
	}

	if !hasHost {
		keyData.Host = append(keyData.Host, host)
	}

	if currentindex >= len(keyData.Host) && mode == "sticky" {
		return fmt.Errorf("currentindex: %d can't be larger or equal to the lenght of host-list: %d", currentindex, len(keyData.Host))
	}

	keyData.Mode = mode
	keyData.CurrentIndex = currentindex
	keyData.HostData = hostdata
	keyData.RabbitKey = rabbitkey

	keyRoutingTable.Keys[key] = keyData
	service.Services[servicename] = keyRoutingTable
	err = p.UpsertService(username, service)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) UpdateKeyData(username, servicename string, keyData KeyData) error {
	service, err := p.GetService(username)
	if err != nil {
		return err
	}

	keyRoutingTable, ok := service.Services[servicename]
	if !ok {
		return fmt.Errorf("getting keylist is not possible, servicename %s does not exist", servicename)
	}

	keyRoutingTable.Keys[keyData.Key] = keyData
	service.Services[servicename] = keyRoutingTable

	err = p.UpsertService(username, service)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteKey(username, servicename, key string) error {
	service, err := p.GetService(username)
	if err != nil {
		return err
	}

	keyRoutingTable, ok := service.Services[servicename]
	if !ok {
		return fmt.Errorf("deleting key is not possible, servicename %s does not exist", servicename)
	}

	delete(keyRoutingTable.Keys, key)
	service.Services[servicename] = keyRoutingTable

	err = p.UpsertService(username, service)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteService(username, servicename string) error {
	service, err := p.GetService(username)
	if err != nil {
		return err
	}

	_, ok := service.Services[servicename]
	if !ok {
		return fmt.Errorf("deleting key is not possible, servicename %s does not exist", servicename)
	}
	delete(service.Services, servicename)

	err = p.UpsertService(username, service)
	if err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) UpsertService(username string, service Service) error {
	_, err := p.Collection["services"].Upsert(bson.M{"username": username}, service)
	if err != nil {
		return err
	}
	return nil
}
