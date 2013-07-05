package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"net/http"
)

func GetUsers(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("GET\t/services")
	users := make([]string, 0)
	services := proxyDB.GetServices()

	for _, service := range services {
		users = append(users, service.Username)
	}

	data, err := json.MarshalIndent(users, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func GetServices(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	username := vars["username"]
	fmt.Printf("GET\t/services/%s\n", username)
	services := make([]string, 0)
	service, _ := proxyDB.GetService(username)

	for name, _ := range service.Services {
		services = append(services, name)
	}

	data, err := json.MarshalIndent(services, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func GetService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	servicename := vars["servicename"]
	username := vars["username"]
	fmt.Printf("GET\t/services/%s/%s\n", username, servicename)

	service, _ := proxyDB.GetService(username)
	data, err := json.MarshalIndent(service.Services[servicename], "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	writer.Write([]byte(data))
}

func CreateKey(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	servicename := vars["servicename"]
	username := vars["username"]
	key := vars["key"]
	fmt.Printf("POST\t/services/%s/%s/%s\n", username, servicename, key)

	var msg ProxyPostMessage

	body, _ := ioutil.ReadAll(req.Body)
	err := json.Unmarshal(body, &msg)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if key == "" {
		err := "no 'key' field available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if key == "latest" {
		err := "key 'latest' cannot be used."
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Host == "" {
		err := "no 'host' field available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Mode == "" {
		err := "no 'mode' field available. should 'roundrobin' or  'random'"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Persistence == "" {
		msg.Persistence = "disabled"
	}

	// this is optional
	if msg.Hostdata == "" {
		msg.Hostdata = "FromKontrolAPI"
	}

	err = proxyDB.UpsertKey(username, msg.Persistence, msg.Mode, servicename, key, msg.Host, msg.Hostdata, msg.RabbitKey)
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

func DeleteService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	servicename := vars["servicename"]
	username := vars["username"]
	fmt.Printf("DELETE\t/services/%s/%s\n", username, servicename)

	err := proxyDB.DeleteService(username, servicename)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("service: '%s' is deleted from config", servicename)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
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
