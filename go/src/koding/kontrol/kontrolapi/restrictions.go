package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"net/http"
	"strconv"
)

type RulePostMessage struct {
	Enabled *string `json:"enabled"`
	Action  *string `json:"action"`
	Match   *string `json:"match"`
	Index   *string `json:"index"`
}

func GetRestrictions(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("GET\t/restrictions")
	res := proxyDB.GetRestrictions()
	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	writer.Write([]byte(data))
}

func GetRestrictionByDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	fmt.Printf("GET\t/restrictions/%s\n", domain)

	res, err := proxyDB.GetRestrictionByDomain(domain)
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

func DeleteRestriction(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	fmt.Printf("DELETE\t/restrictions/%s\n", domain)

	err := proxyDB.DeleteRestriction(domain)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("restriction for domain '%s' is deleted", domain)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func CreateRuleByName(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	name := vars["name"]
	fmt.Printf("POST\t/restrictions/%s/%s\n", domain, name)

	var msg RulePostMessage
	var ruleEnabled bool
	var ruleAction string
	var ruleIndex int
	var err error

	body, _ := ioutil.ReadAll(req.Body)
	err = json.Unmarshal(body, &msg)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Enabled != nil {
		switch *msg.Enabled {
		case "true", "on", "yes":
			ruleEnabled = true
		case "false", "off", "no":
			ruleEnabled = false
		default:
			err := "enabled field is invalid. should one of 'true,on,yes' or 'false,off,no'"
			http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
			return
		}
	} else {
		err := "no 'enabled' field available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Action != nil {
		ruleAction = *msg.Action
	} else {
		err := "no 'action' field available. should one of 'allow, deny, securepage'"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.Index != nil {
		ruleIndex, err = strconv.Atoi(*msg.Index)
		if err != nil {
			http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
			return
		}
	} else {
		err := "no 'index' field available. please define a number, this is needed for the order of rules"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	var rule proxyconfig.Rule
	switch req.Method {
	case "POST":
		rule, err = proxyDB.AddOrUpdateRule(ruleEnabled, domain, ruleAction, name, ruleIndex, "add")
		if err != nil {
			http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
			return
		}
	case "PUT":
		rule, err = proxyDB.AddOrUpdateRule(ruleEnabled, domain, ruleAction, name, ruleIndex, "update")
		if err != nil {
			http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
			return
		}
	}

	data, err := json.MarshalIndent(rule, "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}
	writer.Write([]byte(data))
	return

}

func DeleteRuleByName(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	name := vars["name"]
	fmt.Printf("DELETE\t/restrictions/%s/%s\n", domain, name)
	err := proxyDB.DeleteRuleByName(domain, name)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("rule for domain '%s' is deleted", domain)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
