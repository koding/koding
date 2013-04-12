package proxyconfig

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
)

var configFile string = "proxy-handler.config.json"

type KeyRoutingTable struct {
	Keys map[string][]KeyData `json:"keys"`
}

func NewKeyRoutingTable() *KeyRoutingTable {
	return &KeyRoutingTable{
		Keys: make(map[string][]KeyData),
	}
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

type DomainRoutingTable struct {
	Domain map[string]string `json:"domain"`
}

func NewDomainRoutingTable() *DomainRoutingTable {
	return &DomainRoutingTable{
		Domain: make(map[string]string),
	}
}

type ProxyConfiguration struct {
	RegisteredProxies map[string]Proxy
}

type Proxy struct {
	KeyRoutingTable    KeyRoutingTable
	DomainRoutingTable DomainRoutingTable
}

func NewProxy() *Proxy {
	return &Proxy{
		KeyRoutingTable:    *NewKeyRoutingTable(),
		DomainRoutingTable: *NewDomainRoutingTable(),
	}
}

func NewProxyConfiguration() *ProxyConfiguration {
	return &ProxyConfiguration{
		RegisteredProxies: make(map[string]Proxy),
	}
}

type ProxyMessage struct {
	Action   string `json:"action"`
	Key      string `json:"key"`
	Host     string `json:"host"`
	HostData string `json:"hostdata"`
	Uuid     string `json:"uuid"`
}

func (p *ProxyConfiguration) AddProxy(uuid string) error {
	err := p.ReadConfig()
	if err != nil {
		log.Println("configfile not available, might be the first time registering...", err)
	}

	err = p.HasUuid(uuid)
	if err == nil {
		return fmt.Errorf("registering not possible uuid '%s' uuid exists.", uuid)
	}

	proxy := *NewProxy()
	p.RegisteredProxies[uuid] = proxy
	if err := p.SaveConfig(); err != nil {
		return err
	}

	return nil
}

func (p *ProxyConfiguration) DeleteProxy(uuid string) error {
	err := p.HasUuid(uuid)
	if err != nil {
		return fmt.Errorf("deleting not possible '%s'", err)
	}

	log.Printf("deleting uuid %s", uuid)
	delete(p.RegisteredProxies, uuid)
	if err := p.SaveConfig(); err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) DeleteKey(key, host, hostdata, uuid string) error {
	err := p.HasUuid(uuid)
	if err != nil {
		return fmt.Errorf("deleting key not possible '%s'", err)
	}

	proxy := p.RegisteredProxies[uuid]

	delete(proxy.KeyRoutingTable.Keys, key)
	if err := p.SaveConfig(); err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) AddKey(key, host, hostdata, uuid string) error {
	err := p.HasUuid(uuid)
	if err != nil {
		return fmt.Errorf("adding key not possible '%s'", err)
	}

	proxy := p.RegisteredProxies[uuid]

	if len(proxy.KeyRoutingTable.Keys) == 0 { // empty routing table, add it
		proxy.KeyRoutingTable.Keys[key] = append(proxy.KeyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, 0))
		return nil
	}

	_, ok := proxy.KeyRoutingTable.Keys[key] // new key, add it
	if !ok {
		proxy.KeyRoutingTable.Keys[key] = append(proxy.KeyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, 0))
		return nil
	}

	// check for existing hostnames, if exist abort
	for _, value := range proxy.KeyRoutingTable.Keys[key] {
		if value.Host == host {
			return nil
		}
	}

	proxy.KeyRoutingTable.Keys[key] = append(proxy.KeyRoutingTable.Keys[key], *NewKeyData(key, host, hostdata, 0))

	if err := p.SaveConfig(); err != nil {
		return err
	}
	return nil
}

func (p *ProxyConfiguration) ListKeys() string {
	data, err := json.MarshalIndent(p.RegisteredProxies, "", "  ")
	if err != nil {
		log.Printf("could not marshall json: %s", err)
	}

	res := fmt.Sprintf("current added hosts\n\n%s", data)
	return res
}

func (p *ProxyConfiguration) HasUuid(uuid string) error {
	_, ok := p.RegisteredProxies[uuid]
	if ok {
		return nil
	}
	return fmt.Errorf("no proxy with the uuid %s exist.", uuid)
}

func (p *ProxyConfiguration) SaveConfig() error {
	data, err := json.MarshalIndent(p, "", "  ")
	if err != nil {
		return fmt.Errorf("could not marshall json: %s", err)
	}
	err = ioutil.WriteFile(configFile, data, 0644)
	if err != nil {
		return fmt.Errorf("could not save to config.json: %s", err)
	}

	return nil

}

func (p *ProxyConfiguration) ReadConfig() error {
	if _, err := os.Stat(configFile); os.IsNotExist(err) {
		return fmt.Errorf("no such file or directory: %s", configFile)
	}

	file, err := ioutil.ReadFile(configFile)
	if err != nil {
		return err
	}

	*p = ProxyConfiguration{} // zeroed because othwerise the old ones can be still exist
	err = json.Unmarshal(file, &p)
	if err != nil {
		return fmt.Errorf("bad json unmarshalling config file", err)
	}

	return nil
}
