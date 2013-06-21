package proxyconfig

import (
	"fmt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"sort"
	"strconv"
)

type KeyData struct {
	// Versioning of hosts
	Key string `json:"key"`

	// List of hosts to proxy
	Host []string `json:"host"`

	// LoadBalance for this server
	LoadBalancer LoadBalancer `json:"loadBalancer"`

	// future usage...
	HostData string `json:"hostData"`

	// future usage, proxy via mq
	RabbitKey string `json:"rabbitKey"`
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

func NewKeyData(key, persistence, mode, hostdata, rabbitkey string, host []string, index int) *KeyData {
	return &KeyData{
		Key:          key,
		Host:         host,
		LoadBalancer: LoadBalancer{persistence, mode, index},
		HostData:     hostdata,
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
	service := Service{}
	err := p.Collection["services"].Find(bson.M{"username": username}).One(&service)
	if err != nil {
		return service, err
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
func (p *ProxyConfiguration) UpsertKey(username, persistence, mode, servicename, key, host, hostdata, rabbitkey string, index int) error {
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
		keyRoutingTable.Keys[key] = *NewKeyData(key, persistence, mode, hostdata, rabbitkey, hosts, 0)
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

	if index >= len(keyData.Host) && mode == "sticky" {
		return fmt.Errorf("index: %d can't be larger or equal to the length of host-list: %d", index, len(keyData.Host))
	}

	keyData.LoadBalancer.Persistence = persistence
	keyData.LoadBalancer.Mode = mode
	keyData.LoadBalancer.Index = index
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
