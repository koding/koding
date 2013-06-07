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
	RuleEnabled *string `json:"enabled"`
	RuleMode    *string `json:"mode"`
}

func GetRules(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("GET\t/rules")
	res := proxyDB.GetRules()
	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	writer.Write([]byte(data))
}

func GetRule(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	fmt.Printf("GET\t/rules/%s\n", domain)

	res, err := proxyDB.GetRule(domain)
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
	domain := vars["domain"]
	fmt.Printf("POST\t/rules/%s\n", domain)

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
		switch *msg.RuleEnabled {
		case "true", "on", "yes":
			ruleEnabled = true
		case "false", "off", "no":
			ruleEnabled = false
		case "default":
			err := "enabled field is invalid. should one of 'true,on,yes' or 'false,off,no'"
			http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
			return
		}
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

	proxyDB.AddRule(domain, ruleName, rule, ruleMode, ruleEnabled)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
	}

	url := fmt.Sprintf("firewall rule for '%s' is added with rule: '%s', enabled: '%t' and mode '%s'", ruleName, rule, ruleEnabled, ruleMode)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", url))
	return

}

func DeleteRule(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	fmt.Printf("DELETE\t/rules/%s\n", domain)
	err := proxyDB.DeleteRule(domain)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("rule for domain '%s' is deleted", domain)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
