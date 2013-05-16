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

type RulesPostMessage struct {
	IpRegex   *string
	Countries *string
}

func GetRules(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	users := make([]string, 0)
	proxyMachine, _ := proxyConfig.GetProxy(uuid)
	for username := range proxyMachine.Rules {
		users = append(users, username)
	}

	data, err := json.MarshalIndent(users, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func GetUserRules(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	username := vars["username"]
	services := make([]string, 0)

	proxyMachine, _ := proxyConfig.GetProxy(uuid)
	_, ok := proxyMachine.Rules[username]
	if !ok {
		resp := fmt.Sprintf("getting services of user rules is not possible. no user %s exists", username)
		io.WriteString(writer, resp)
		return
	}

	rules := proxyMachine.Rules[username]
	for name, _ := range rules.Services {
		services = append(services, name)
	}

	data, err := json.MarshalIndent(services, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}
	writer.Write([]byte(data))
}

func GetUserServiceRules(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	username := vars["username"]
	servicename := vars["servicename"]

	proxyMachine, _ := proxyConfig.GetProxy(uuid)
	_, ok := proxyMachine.Rules[username]
	if !ok {
		resp := fmt.Sprintf("getting services of user rules is not possible. no user %s exists", username)
		io.WriteString(writer, resp)
		return
	}

	rules := proxyMachine.Rules[username]
	restriction := rules.Services[servicename]

	data, err := json.MarshalIndent(restriction, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}
	writer.Write([]byte(data))
}

func CreateUserServiceRules(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]
	username := vars["username"]

	var msg RulesPostMessage
	var ipregex string
	var countries string

	body, _ := ioutil.ReadAll(req.Body)
	log.Println(string(body))

	err := json.Unmarshal(body, &msg)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.IpRegex != nil {
		ipregex = *msg.IpRegex
	} else {
		err := "no 'ipregex' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Countries != nil {
		countries = *msg.Countries
	} else {
		err := "no 'countries' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "addRule"
	cmd.Uuid = uuid
	cmd.Username = username
	cmd.ServiceName = servicename
	cmd.IpRegex = ipregex
	cmd.Countries = countries

	buildSendProxyCmd(cmd)

	url := fmt.Sprintf("rule ipregex: '%s' and country: '%s' is added for the user %s and service %s", ipregex, countries, username, servicename)
	io.WriteString(writer, url)
	return

}
