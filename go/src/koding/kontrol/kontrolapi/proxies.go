package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"log"
	"net/http"
)

type Proxy struct {
	Key       string
	Host      string
	Hostdata  string
	RabbitKey string
}
type Proxies []Proxy

type ProxyMachine struct {
	Uuid string
	Keys []string
}
type ProxyMachines []ProxyMachine

type ProxyPostMessage struct {
	Name      *string
	Username  *string
	Domain    *string
	Mode      *string
	Key       *string
	RabbitKey *string
	Host      *string
	Hostdata  *string
	Uuid      *string
}

func GetProxies(writer http.ResponseWriter, req *http.Request) {
	proxies := make([]string, 0)
	proxy := proxyconfig.Proxy{}
	iter := proxyConfig.Collection.Find(nil).Iter()
	for iter.Next(&proxy) {
		proxies = append(proxies, proxy.Uuid)

	}

	data, err := json.MarshalIndent(proxies, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func DeleteProxy(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "deleteProxy"
	cmd.Uuid = uuid

	buildSendProxyCmd(cmd)
	resp := fmt.Sprintf("'%s' is deleted", uuid)
	io.WriteString(writer, resp)
}

func CreateProxy(writer http.ResponseWriter, req *http.Request) {
	var msg ProxyPostMessage
	var uuid string

	body, _ := ioutil.ReadAll(req.Body)
	log.Println(string(body))

	err := json.Unmarshal(body, &msg)
	if err != nil {
		log.Print("bad json incoming msg: ", err)
	}

	if msg.Uuid != nil {
		if *msg.Uuid == "default" {
			err := "reserved keyword, please choose another uuid name"
			io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
			return
		}
		uuid = *msg.Uuid
	} else {
		err := "aborting. no 'uuid' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "addProxy"
	cmd.Uuid = uuid

	buildSendProxyCmd(cmd)

	resp := fmt.Sprintf("'%s' is registered", uuid)
	io.WriteString(writer, resp)
}

func CreateProxyUser(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	username := vars["username"]

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "addUser"
	cmd.Uuid = uuid
	cmd.Username = username

	buildSendProxyCmd(cmd)
	resp := fmt.Sprintf("user '%s' is added to proxy uuid: '%s'", username, uuid)
	io.WriteString(writer, resp)
}

func DeleteProxyService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]
	username := vars["username"]

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "deleteServiceName"
	cmd.Uuid = uuid
	cmd.ServiceName = servicename
	cmd.Username = username

	buildSendProxyCmd(cmd)
	resp := fmt.Sprintf("service: '%s' is deleted on proxy uuid: '%s'", servicename, uuid)
	io.WriteString(writer, resp)
}

func DeleteProxyServiceKey(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	key := vars["key"]
	servicename := vars["servicename"]
	username := vars["username"]

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "deleteKey"
	cmd.Uuid = uuid
	cmd.Key = key
	cmd.ServiceName = servicename
	cmd.Username = username

	buildSendProxyCmd(cmd)
	resp := fmt.Sprintf("key: '%s' is deleted for service: '%s'", key, servicename)
	io.WriteString(writer, resp)
}

func DeleteProxyDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	domain := vars["domain"]

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "deleteDomain"
	cmd.Uuid = uuid
	cmd.DomainName = domain

	buildSendProxyCmd(cmd)
	resp := fmt.Sprintf("domain: '%s' is deleted on proxy uuid: '%s'", domain, uuid)
	io.WriteString(writer, resp)
}

func GetProxyDomains(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	proxyMachine, _ := proxyConfig.GetProxy(uuid)

	domains := proxyMachine.DomainRoutingTable

	data, err := json.MarshalIndent(domains, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func CreateProxyDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	domain := vars["domain"]

	var msg ProxyPostMessage
	var mode string
	var name string
	var username string
	var key string
	var host string

	body, _ := ioutil.ReadAll(req.Body)
	log.Println(string(body))

	err := json.Unmarshal(body, &msg)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	// can be one of the followings:
	// internal	: to point name-key.in.koding.com
	// direct	: to point host
	// vm		: to point username.kd.io
	if msg.Mode != nil {
		mode = *msg.Mode
	} else {
		err := "no 'mode' available. must be one of: internal, direct, vm"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Username != nil {
		username = *msg.Username
	} else if mode == "vm" || mode == "internal" {
		err := "no 'username' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Name != nil {
		name = *msg.Name
	} else if mode == "internal" {
		err := "no 'name' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return

	}

	if msg.Key != nil {
		key = *msg.Key
	} else if mode == "internal" {
		err := "no 'key' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	// this is optional feature
	if msg.Host != nil {
		host = *msg.Host
	} else if mode == "direct" {
		err := "no 'host' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	// for default proxy assume that the main proxy will handle this. until
	// we come up with design decision for multiple proxies, use this
	if uuid == "default" {
		uuid = "proxy.in.koding.com"
	}

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "addDomain"
	cmd.Username = username
	cmd.Uuid = uuid
	cmd.Key = key
	cmd.ServiceName = name
	cmd.DomainName = domain
	cmd.DomainMode = mode
	cmd.Host = host
	cmd.HostData = "FromKontrolAPI"

	buildSendProxyCmd(cmd)

	var resp string
	switch mode {
	case "internal":
		resp = fmt.Sprintf("'%s' will proxy to '%s-%s.kd.io'", domain, name, key)
	case "direct":
		resp = fmt.Sprintf("'%s' will proxy to '%s'", domain, host)
	case "vm":
		resp = fmt.Sprintf("'%s' will proxy to '%s.kd.io'", domain, username)
	}

	io.WriteString(writer, resp)
	return
}

func CreateProxyService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]
	username := vars["username"]

	var msg ProxyPostMessage
	var key string
	var host string
	var hostdata string
	var rabbitkey string

	body, _ := ioutil.ReadAll(req.Body)
	log.Println(string(body))

	err := json.Unmarshal(body, &msg)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Key != nil {
		key = *msg.Key
	} else {
		err := "no 'key' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Host != nil {
		host = *msg.Host
	} else {
		err := "no 'host' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	// this is optional
	if msg.Hostdata != nil {
		hostdata = *msg.Hostdata
	}

	if msg.RabbitKey != nil {
		rabbitkey = *msg.RabbitKey
	}

	if hostdata == "" {
		hostdata = "FromKontrolAPI"
	}

	// for default proxy assume that the main proxy will handle this. until
	// we come up with design decision for multiple proxies, use this
	if uuid == "default" {
		uuid = "proxy.in.koding.com"
	}

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "addKey"
	cmd.Uuid = uuid
	cmd.Key = key
	cmd.RabbitKey = rabbitkey
	cmd.ServiceName = servicename
	cmd.Username = username
	cmd.Host = host
	cmd.HostData = hostdata

	buildSendProxyCmd(cmd)

	var url string
	if username == "koding" {
		url = fmt.Sprintf("http://%s-%s.x.koding.com", servicename, key)
	} else {
		url = fmt.Sprintf("http://%s-%s-%s.kd.io", servicename, key, username)
	}
	io.WriteString(writer, url)
	return
}

func GetProxyUsers(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	users := make([]string, 0)
	proxyMachine, _ := proxyConfig.GetProxy(uuid)

	for username := range proxyMachine.RoutingTable {
		users = append(users, username)
	}

	data, err := json.MarshalIndent(users, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func GetProxyServices(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	username := vars["username"]

	services := make([]string, 0)
	proxyMachine, _ := proxyConfig.GetProxy(uuid)

	_, ok := proxyMachine.RoutingTable[username]
	if !ok {
		resp := fmt.Sprintf("getting proxy services is not possible. no user %s exists", username)
		io.WriteString(writer, resp)
		return
	}
	user := proxyMachine.RoutingTable[username]

	for name, _ := range user.Services {
		services = append(services, name)
	}

	data, err := json.MarshalIndent(services, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func GetProxyService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]
	username := vars["username"]

	v := req.URL.Query()
	key := v.Get("key")
	host := v.Get("host")
	hostdata := v.Get("hostdata")

	p := make(Proxies, 0)
	proxyMachine, _ := proxyConfig.GetProxy(uuid)

	_, ok := proxyMachine.RoutingTable[username]
	if !ok {
		resp := fmt.Sprintf("getting proxy service is not possible. no user %s exists", username)
		io.WriteString(writer, resp)
		return
	}
	user := proxyMachine.RoutingTable[username]

	keyRoutingTable := user.Services[servicename]

	for _, keys := range keyRoutingTable.Keys {
		for _, proxy := range keys {
			p = append(p, Proxy{proxy.Key, proxy.Host, proxy.HostData, proxy.RabbitKey})
		}
	}

	s := make([]interface{}, len(p))
	for i, v := range p {
		s[i] = v
	}

	t := NewMatcher(s).
		ByString("Key", key).
		ByString("Host", host).
		ByString("Hostdata", hostdata).
		Run()

	matchedProxies := make(Proxies, len(t))
	for i, item := range t {
		w, _ := item.(Proxy)
		matchedProxies[i] = w
	}

	var res []Proxy
	if len(v) == 0 { // no query available, means return all proxies
		res = p
	} else {
		res = matchedProxies
	}

	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func buildSendProxyCmd(cmd proxyconfig.ProxyMessage) {
	log.Println("Sending cmd to kontrold:", cmd)

	// Wrap message for dynamic unmarshaling at endpoint
	type Wrap struct{ Proxy proxyconfig.ProxyMessage }

	data, err := json.Marshal(&Wrap{cmd})
	if err != nil {
		log.Println("Json marshall error", data)
	}

	amqpWrapper.Publish(data)
}
