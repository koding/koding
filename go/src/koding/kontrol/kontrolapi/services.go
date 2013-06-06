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

func GetProxyUsers(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("GET\t/services")
	users := make([]string, 0)
	proxyMachine, _ := proxyDB.GetConfig()

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
	username := vars["username"]
	fmt.Printf("GET\t/services/%s\n", username)

	services := make([]string, 0)
	proxyMachine, _ := proxyDB.GetConfig()

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

func CreateProxyUser(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	username := vars["username"]
	fmt.Printf("POST\t/services/%s\n", username)

	err := proxyDB.AddUser(username)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}
	resp := fmt.Sprintf("user '%s' is added to config", username)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func GetKeyList(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	servicename := vars["servicename"]
	username := vars["username"]
	fmt.Printf("GET\t/services/%s/%s\n", username, servicename)

	res, err := proxyDB.GetKeyList(username, servicename)
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

func CreateProxyService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	servicename := vars["servicename"]
	username := vars["username"]
	fmt.Printf("POST\t/services/%s/%s\n", username, servicename)

	var msg ProxyPostMessage

	body, _ := ioutil.ReadAll(req.Body)
	log.Println(string(body))
	err := json.Unmarshal(body, &msg)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Key == "" {
		err := "no 'key' field available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Host == "" {
		err := "no 'host' field available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	// this is optional
	if msg.Hostdata == "" {
		msg.Hostdata = "FromKontrolAPI"
	}

	err = proxyDB.AddKey(username, servicename, msg.Key, msg.Host, msg.Hostdata, msg.RabbitKey)
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

func DeleteProxyService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	servicename := vars["servicename"]
	username := vars["username"]
	fmt.Printf("DELETE\t/services/%s/%s\n", username, servicename)

	err := proxyDB.DeleteServiceName(username, servicename)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("service: '%s' is deleted from config", servicename)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func GetKey(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	servicename := vars["servicename"]
	username := vars["username"]
	key := vars["key"]
	fmt.Printf("GET\t/services/%s/%s/%s\n", username, servicename, key)

	res, err := proxyDB.GetKey(username, servicename, key)
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

func DeleteKey(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	key := vars["key"]
	servicename := vars["servicename"]
	username := vars["username"]
	fmt.Printf("DELETE\t/services/%s/%s/%s\n", username, servicename, key)

	err := proxyDB.DeleteKey(username, servicename, key)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}
	resp := fmt.Sprintf("key: '%s' is deleted for service: '%s'", key, servicename)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
