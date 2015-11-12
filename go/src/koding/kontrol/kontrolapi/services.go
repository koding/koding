package main

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"koding/db/mongodb/modelhelper"
	"net/http"

	"github.com/gorilla/mux"
)

func GetUsers(writer http.ResponseWriter, req *http.Request) {
	users := make([]string, 0)
	services := modelhelper.GetServices()

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
	services := make([]string, 0)
	service, _ := modelhelper.GetService(username)

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

	service, _ := modelhelper.GetService(username)
	data, err := json.MarshalIndent(service.Services[servicename], "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	writer.Write([]byte(data))
}

type ServicePostMessage struct {
	Host        string
	Enabled     string
	Key         string
	Username    string
	Data        string
	ServiceName string
}

func CreateKey(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	servicename := vars["servicename"]
	username := vars["username"]
	key := vars["key"]

	var msg ServicePostMessage

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

	if msg.Data == "" {
		err := "no 'data' field available."
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	var enabled bool
	switch msg.Enabled {
	case "true", "on", "yes":
		enabled = true
	case "false", "off", "no":
		enabled = false
	default:
		msg.Enabled = "false"
		enabled = false
	}

	err = modelhelper.UpsertKey(
		username,
		servicename,
		key,
		msg.Host,
		msg.Data,
		enabled,
	)

	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	// update msg with rest api paths
	msg.Username = username
	msg.Key = key
	msg.ServiceName = servicename

	data, err := json.MarshalIndent(msg, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write(data)
	return
}

func GetKey(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	servicename := vars["servicename"]
	username := vars["username"]
	key := vars["key"]

	res, err := modelhelper.GetKey(username, servicename, key)
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

	err := modelhelper.DeleteService(username, servicename)
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

	err := modelhelper.DeleteKey(username, servicename, key)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}
	resp := fmt.Sprintf("key: '%s' is deleted for service: '%s'", key, servicename)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func DeleteServices(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	username := vars["username"]

	err := modelhelper.DeleteServices(username)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("user: '%s' is deleted from config", username)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
