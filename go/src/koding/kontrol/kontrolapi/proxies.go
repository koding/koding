package main

import (
	"encoding/json"
	"errors"
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
	Name      string
	Username  string
	Domain    string
	Mode      string
	Key       string
	RabbitKey string
	Host      string
	Hostdata  string
	Uuid      string
}

func (p *ProxyPostMessage) validate() error {
	// mode can be one of the followings:
	// internal     : to point name-key.in.koding.com
	// direct       : to point host
	// vm           : to point username.kd.io
	if p.Mode == "" {
		return errors.New("Missing field 'mode'. Can be one of: internal, direct, vm")
	}

	if p.Username == "" && p.Mode != "direct" {
		return errors.New("Missing field 'username' is required with {'mode': 'vm' or 'internal'}")
	}

	if p.Name == "" && p.Mode == "internal" {
		return errors.New("Missing field 'name' is required with {'mode': 'internal'}")
	}

	if p.Key == "" && p.Mode == "internal" {
		return errors.New("Missing field 'key' is required with {'mode': 'internal'}")
	}

	if p.Host == "" && p.Mode == "direct" {
		return errors.New("Missing field 'host' is required with {'mode': 'direct}'")
	}

	return nil
}

// takes an http request, unmarshals it to a ProxyPostMessage struct,
// returns an error if the validation fails.
func unmarshalAndValidate(req *http.Request) (ProxyPostMessage, error) {
	msg := ProxyPostMessage{}
	body, err := ioutil.ReadAll(req.Body)
	if err != nil {
		return msg, err
	}

	err = json.Unmarshal(body, &msg)
	if err != nil {
		return msg, err
	}

	err = msg.validate()
	if err != nil {
		return msg, err
	}

	return msg, nil
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
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	if uuid == "" {
		err := errors.New("aborting. no 'uuid' available")
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	err := proxyDB.AddProxy(uuid)
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
	if err != nil || domain.Domainname == "" {
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

	p, err := unmarshalAndValidate(req)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	err = proxyDB.AddDomain(domain, p.Mode, p.Username, p.Name, p.Key, p.Host, uuid)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	var resp string
	switch p.Mode {
	case "internal":
		resp = fmt.Sprintf("{\"host\":\"%s-%s.kd.io\"}\n", p.Name, p.Key)
	case "direct":
		resp = fmt.Sprintf("{\"host\":\"%s\"}\n", p.Host)
	case "vm":
		resp = fmt.Sprintf("{\"host\":\"%s.kd.io\"}\n", p.Username)
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

	body, _ := ioutil.ReadAll(req.Body)
	log.Println(string(body))
	err := json.Unmarshal(body, &msg)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Key == "" {
		err := "no 'key' available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Host == "" {
		err := "no 'host' available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	// this is optional
	if msg.Hostdata == "" {
		msg.Hostdata = "FromKontrolAPI"
	}

	err = proxyDB.AddKey(username, servicename, msg.Key, msg.Host, msg.Hostdata, uuid, msg.RabbitKey)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	var url string
	if username == "koding" {
		url = fmt.Sprintf("{\"host\":\"%s-%s.x.koding.com\"}\n", servicename, msg.Key)

	} else {
		url = fmt.Sprintf("{\"host\":\"%s-%s-%s.kd.io\"}\n", servicename, msg.Key, username)
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
