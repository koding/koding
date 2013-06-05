package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"net/http"
)

type RulesPostMessage struct {
	RuleName    *string `json:"name"`
	Rule        *string `json:"rule"`
	RuleEnabled *bool   `json:"enabled"`
	RuleMode    *string `json:"mode"`
}

func GetRules(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("GET\t/rules")
	res, err := proxyDB.GetRulesUsers()
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

func GetRulesServices(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	username := vars["username"]
	fmt.Printf("GET\t/rules/%s\n", username)
	res, err := proxyDB.GetRulesServices(username)
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

func GetRule(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	username := vars["username"]
	servicename := vars["servicename"]
	fmt.Printf("GET\t/rules/%s/%s\n", username, servicename)

	res, err := proxyDB.GetRule(username, servicename)
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

func CreateRule(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	servicename := vars["servicename"]
	username := vars["username"]
	fmt.Printf("POST\t/rules/%s/%s\n", username, servicename)

	var msg RulesPostMessage
	var rule string
	var ruleName string
	var ruleEnabled bool
	var ruleMode string

	body, _ := ioutil.ReadAll(req.Body)
	err := json.Unmarshal(body, &msg)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.RuleName != nil {
		ruleName = *msg.RuleName
	} else {
		err := "no 'rule name' available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Rule != nil {
		rule = *msg.Rule
	} else {
		err := "no 'rule' available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.RuleEnabled != nil {
		ruleEnabled = *msg.RuleEnabled
	} else {
		err := "no 'ruleEnabled' available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.RuleMode != nil {
		ruleMode = *msg.RuleMode
	} else {
		err := "no 'ruleMode' available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	proxyDB.AddRule(username, servicename, ruleName, rule, ruleMode, ruleEnabled)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
	}

	url := fmt.Sprintf("firewall rule for '%s' is added with rule: '%s', enabled: '%t' and mode '%s'", ruleName, rule, ruleEnabled, ruleMode)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", url))
	return

}
