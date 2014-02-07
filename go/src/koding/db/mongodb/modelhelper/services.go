package modelhelper

import (
	"fmt"
	"koding/db/models"
	"sort"
	"strconv"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func NewKeyRoutingTable() *models.KeyRoutingTable {
	return &models.KeyRoutingTable{
		Keys: make(map[string]models.KeyData),
	}
}

func NewKeyData(key, hostdata string, host []string, enabled bool) *models.KeyData {
	return &models.KeyData{
		Key:      key,
		Host:     host,
		HostData: hostdata,
		Enabled:  enabled,
	}
}

func NewService(username string) *models.Service {
	return &models.Service{
		Id:       bson.NewObjectId(),
		Username: username,
		Services: make(map[string]models.KeyRoutingTable),
	}
}

func GetServices() []models.Service {
	service := models.Service{}
	services := make([]models.Service, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(nil).Iter()
		for iter.Next(&service) {
			services = append(services, service)
		}
		return nil
	}

	Mongo.Run("jProxyServices", query)
	return services
}

func GetService(username string) (models.Service, error) {
	service := models.Service{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).One(&service)
	}

	err := Mongo.Run("jProxyServices", query)
	return service, err
}

func GetLatestKey(username, servicename string) string {
	service, err := GetService(username)
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

func GetKey(username, servicename, key string) (models.KeyData, error) {
	service, err := GetService(username)
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
func UpsertKey(username, servicename, key, host, hostdata string, enabled bool) error {
	service, err := GetService(username)
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
		keyRoutingTable.Keys[key] = *NewKeyData(key, hostdata, hosts, enabled)
		service.Services[servicename] = keyRoutingTable
		err = UpsertService(username, service)
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

	keyData.HostData = hostdata
	keyData.Enabled = enabled

	keyRoutingTable.Keys[key] = keyData
	service.Services[servicename] = keyRoutingTable
	err = UpsertService(username, service)
	if err != nil {
		return err
	}
	return nil
}

func UpdateKeyData(username, servicename string, keyData models.KeyData) error {
	service, err := GetService(username)
	if err != nil {
		return err
	}

	keyRoutingTable, ok := service.Services[servicename]
	if !ok {
		return fmt.Errorf("getting keylist is not possible, servicename %s does not exist", servicename)
	}

	keyRoutingTable.Keys[keyData.Key] = keyData
	service.Services[servicename] = keyRoutingTable

	err = UpsertService(username, service)
	if err != nil {
		return err
	}
	return nil
}

func DeleteKey(username, servicename, key string) error {
	service, err := GetService(username)
	if err != nil {
		return err
	}

	keyRoutingTable, ok := service.Services[servicename]
	if !ok {
		return fmt.Errorf("deleting key is not possible, servicename %s does not exist", servicename)
	}

	delete(keyRoutingTable.Keys, key)
	service.Services[servicename] = keyRoutingTable

	err = UpsertService(username, service)
	if err != nil {
		return err
	}
	return nil
}

func DeleteService(username, servicename string) error {
	service, err := GetService(username)
	if err != nil {
		return err
	}

	_, ok := service.Services[servicename]
	if !ok {
		return fmt.Errorf("deleting key is not possible, servicename %s does not exist", servicename)
	}
	delete(service.Services, servicename)

	err = UpsertService(username, service)
	if err != nil {
		return err
	}
	return nil
}

func UpsertService(username string, service models.Service) error {
	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"username": username}, service)
		return err
	}

	return Mongo.Run("jProxyServices", query)
}

func DeleteServices(username string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"username": username})
	}

	return Mongo.Run("jProxyServices", query)
}
