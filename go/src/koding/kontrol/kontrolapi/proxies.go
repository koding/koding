package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
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
	res := proxyDB.GetProxies()
	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func DeleteProxy(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	err := proxyDB.DeleteProxy(uuid)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("'%s' is deleted", uuid)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func CreateProxy(writer http.ResponseWriter, req *http.Request) {
	var uuid string
	var msg ProxyPostMessage

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

	err = proxyDB.AddProxy(uuid)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("'%s' is registered", uuid)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func CreateProxyUser(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	username := vars["username"]

	err := proxyDB.AddUser(uuid, username)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}
	resp := fmt.Sprintf("user '%s' is added to proxy uuid: '%s'", username, uuid)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func DeleteProxyService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]
	username := vars["username"]
	err := proxyDB.DeleteServiceName(uuid, username, servicename)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("service: '%s' is deleted on proxy uuid: '%s'", servicename, uuid)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func DeleteProxyServiceKey(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	key := vars["key"]
	servicename := vars["servicename"]
	username := vars["username"]

	err := proxyDB.DeleteKey(uuid, username, servicename, key)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}
	resp := fmt.Sprintf("key: '%s' is deleted for service: '%s'", key, servicename)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func DeleteProxyDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	domain := vars["domain"]

	err := proxyDB.DeleteDomain(uuid, domain)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("domain: '%s' is deleted on proxy uuid: '%s'", domain, uuid)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func GetProxyDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	domainname := vars["domain"]

	domain, err := proxyDB.GetDomain(uuid, domainname)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return

	}

	data, err := json.MarshalIndent(domain, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func GetProxyDomains(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	proxyMachine, _ := proxyDB.GetProxy(uuid)

	data, err := json.MarshalIndent(proxyMachine.Domains, "", "  ")
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
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
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
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Username != nil {
		username = *msg.Username
	} else if mode == "vm" || mode == "internal" {
		err := "no 'username' available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Name != nil {
		name = *msg.Name
	} else if mode == "internal" {
		err := "no 'name' available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return

	}

	if msg.Key != nil {
		key = *msg.Key
	} else if mode == "internal" {
		err := "no 'key' available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	// this is optional feature
	if msg.Host != nil {
		host = *msg.Host
	} else if mode == "direct" {
		err := "no 'host' available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	// for default proxy assume that the main proxy will handle this. until
	// we come up with design decision for multiple proxies, use this
	if uuid == "default" {
		uuid = "proxy.in.koding.com"
	}

	err = proxyDB.AddDomain(domain, mode, username, name, key, host, uuid)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	var resp string
	switch mode {
	case "internal":
		resp = fmt.Sprintf("{\"host\":\"%s-%s.kd.io\"}\n", name, key)
	case "direct":
		resp = fmt.Sprintf("{\"host\":\"%s\"}\n", host)
	case "vm":
		resp = fmt.Sprintf("{\"host\":\"%s.kd.io\"}\n", username)
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
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Key != nil {
		key = *msg.Key
	} else {
		err := "no 'key' available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Host != nil {
		host = *msg.Host
	} else {
		err := "no 'host' available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
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

	err = proxyDB.AddKey(username, servicename, key, host, hostdata, uuid, rabbitkey)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	var url string
	if username == "koding" {
		url = fmt.Sprintf("{\"host\":\"%s-%s.x.koding.com\"}\n", servicename, key)

	} else {
		url = fmt.Sprintf("{\"host\":\"%s-%s-%s.kd.io\"}\n", servicename, key, username)
	}
	io.WriteString(writer, url)
	return
}

func GetProxyUsers(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	users := make([]string, 0)
	proxyMachine, _ := proxyDB.GetProxy(uuid)

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
	proxyMachine, _ := proxyDB.GetProxy(uuid)

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

func GetKeyList(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]
	username := vars["username"]

	res, err := proxyDB.GetKeyList(uuid, username, servicename)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	writer.Write([]byte(data))
}

func GetKey(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]
	username := vars["username"]
	key := vars["key"]

	res, err := proxyDB.GetKey(uuid, username, servicename, key)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	writer.Write([]byte(data))
}
