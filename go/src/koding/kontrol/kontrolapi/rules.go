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
	RuleName    *string `json:"name"`
	Rule        *string `json:"rule"`
	RuleEnabled *bool   `json:"enabled"`
	RuleMode    *string `json:"mode"`
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
	var rule string
	var ruleName string
	var ruleEnabled bool
	var ruleMode string

	body, _ := ioutil.ReadAll(req.Body)
	log.Println(string(body))

	err := json.Unmarshal(body, &msg)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.RuleName != nil {
		ruleName = *msg.RuleName
	} else {
		err := "no 'rule name' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Rule != nil {
		rule = *msg.Rule
	} else {
		err := "no 'rule' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.RuleEnabled != nil {
		ruleEnabled = *msg.RuleEnabled
	} else {
		err := "no 'ruleEnabled' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.RuleMode != nil {
		ruleMode = *msg.RuleMode
	} else {
		err := "no 'ruleEnabled' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "addRule"
	cmd.Uuid = uuid
	cmd.Username = username
	cmd.ServiceName = servicename
	cmd.RuleName = ruleName
	cmd.Rule = rule
	cmd.RuleMode = ruleMode
	cmd.RuleEnabled = ruleEnabled

	buildSendProxyCmd(cmd)

	url := fmt.Sprintf("firewall rule for '%s' is added with rule: '%s', enabled: '%t' and mode '%s'", ruleName, rule, ruleEnabled, ruleMode)
	io.WriteString(writer, url)
	return

}
