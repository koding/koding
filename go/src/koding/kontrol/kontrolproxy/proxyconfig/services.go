package proxyconfig

import (
	"fmt"
	"koding/kontrol/kontrolproxy/models"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"sort"
	"strconv"
)

func NewKeyRoutingTable() *models.KeyRoutingTable {
	return &models.KeyRoutingTable{
		Keys: make(map[string]models.KeyData),
	}
}

func NewKeyData(key, persistence, mode, hostdata, rabbitkey string, host []string) *models.KeyData {
	return &models.KeyData{
		Key:          key,
		Host:         host,
		LoadBalancer: models.LoadBalancer{persistence, mode},
		HostData:     hostdata,
		RabbitKey:    rabbitkey,
	}
}

func NewService(username string) *models.Service {
	return &models.Service{
		Id:       bson.NewObjectId(),
		Username: username,
		Services: make(map[string]models.KeyRoutingTable),
	}
}

func (p *ProxyConfiguration) GetServices() []models.Service {
	service := models.Service{}
	services := make([]models.Service, 0)
	iter := p.Collection["services"].Find(nil).Iter()
	for iter.Next(&service) {
		services = append(services, service)
	}

	return services
}

func (p *ProxyConfiguration) GetService(username string) (models.Service, error) {
	service := models.Service{}
	err := p.Collection["services"].Find(bson.M{"username": username}).One(&service)
	if err != nil {
		return service, err
	}

	return service, nil
}

func (p *ProxyConfiguration) GetLatestKey(username, servicename string) string {
	service, err := p.GetService(username)
	if err != nil {
		return ""
	}

	keyRoutingTable, ok := service.Services[servicename]
	if !ok {
		return ""
	}

	lenKeys := len(keyRoutingTable.Keys)
	listOfKeys := make([]int, lenKeys)
	i := 0
	for k, _ := range keyRoutingTable.Keys {
		listOfKeys[i], _ = strconv.Atoi(k)
		i++
	}
	sort.Ints(listOfKeys)

	// give precedence to the largest key number
	key := strconv.Itoa(listOfKeys[len(listOfKeys)-1])
	return key
}

func (p *ProxyConfiguration) GetKey(username, servicename, key string) (models.KeyData, error) {
	service, err := p.GetService(username)
	if err != nil {
		return models.KeyData{}, err
	}

	keyRoutingTable, ok := service.Services[servicename]
	if !ok {
		return models.KeyData{}, fmt.Errorf("getting key is not possible, servicename %s does not exist", servicename)
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
		return models.KeyData{}, fmt.Errorf("no key '%s' available for username '%s', service '%s'", key, username, servicename)
	}

	return keyData, nil
}

// Update or add a key. service and username will be created if not available
func (p *ProxyConfiguration) UpsertKey(username, persistence, mode, servicename, key, host, hostdata, rabbitkey string) error {
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
		keyRoutingTable.Keys[key] = *NewKeyData(key, persistence, mode, hostdata, rabbitkey, hosts)
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

	keyData.LoadBalancer.Persistence = persistence
	keyData.LoadBalancer.Mode = mode
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

func (p *ProxyConfiguration) UpdateKeyData(username, servicename string, keyData models.KeyData) error {
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

func (p *ProxyConfiguration) UpsertService(username string, service models.Service) error {
	_, err := p.Collection["services"].Upsert(bson.M{"username": username}, service)
	if err != nil {
		return err
	}
	return nil
}
