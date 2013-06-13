package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"net/http"
	"strconv"
)

type RulesPostMessage struct {
	RuleType  *string `json:"type"`
	RuleName  *string `json:"name"`
	RuleMatch *string `json:"match"`
}

type BehaviourPostMessage struct {
	Enabled  *string `json:"enabled"`
	Action   *string `json:"action"`
	RuleName *string `json:"name"`
	Index    *string `json:"index"`
}

func GetRestrictions(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("GET\t/restrictions")
	res := proxyDB.GetRules()
	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	writer.Write([]byte(data))
}

func GetRestriction(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	fmt.Printf("GET\t/restrictions/%s\n", domain)

	res, err := proxyDB.GetRestriction(domain)
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

	resp := fmt.Sprintf("rule for domain '%s' is deleted", domain)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func GetRule(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	rulename := vars["rule"]
	fmt.Printf("GET\t/restrictions/%s/rule/%s\n", domain, rulename)

	res, err := proxyDB.GetRule(domain, rulename)
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

// func GetBehaviour(writer http.ResponseWriter, req *http.Request) {
// 	vars := mux.Vars(req)
// 	domain := vars["domain"]
// 	behaviour := vars["behaviour"]
// 	fmt.Printf("GET\t/restrictions/%s/list/%s\n", domain, behaviour)
//
// 	res, err := proxyDB.GetBehaviour(domain, behaviour)
// 	if err != nil {
// 		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
// 		return
// 	}
//
// 	data, err := json.MarshalIndent(res, "", "  ")
// 	if err != nil {
// 		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
// 		return
// 	}
// 	writer.Write([]byte(data))
// }

func CreateBehaviour(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	ruleName := vars["behaviour"]
	fmt.Printf("POST\t/restrictions/%s/list/%s\n", domain, ruleName)

	var msg BehaviourPostMessage
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
		case "default":
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

	err = proxyDB.AddBehaviour(ruleEnabled, domain, ruleAction, ruleName, ruleIndex)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	url := fmt.Sprintf("behaviour for '%s' and rulename '%s' is added with: enabled: '%t' , action '%s' and index '%d'", domain, ruleName, ruleEnabled, ruleAction, ruleIndex)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", url))
	return
}

func CreateRule(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	fmt.Printf("POST\t/restrictions/%s/rules\n", domain)

	var msg RulesPostMessage
	var ruleType string
	var ruleMatch string

	body, _ := ioutil.ReadAll(req.Body)
	err := json.Unmarshal(body, &msg)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.RuleType != nil {
		ruleType = *msg.RuleType
	} else {
		err := "no 'type' field available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	// disabled for now, is generated automatically
	// if msg.RuleName != nil {
	// 	ruleName = *msg.RuleName
	// } else {
	// 	err := "no 'name' field available"
	// 	http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
	// 	return
	// }

	if msg.RuleMatch != nil {
		ruleMatch = *msg.RuleMatch
	} else {
		err := "no 'match' field available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	err = proxyDB.AddRule(domain, ruleType, ruleMatch)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	url := fmt.Sprintf("rule for '%s' is added with rule: '%s' - '%s'", domain, ruleType, ruleMatch)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", url))
	return

}

func DeleteRule(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	rulename := vars["rule"]
	fmt.Printf("DELETE\t/restrictions/%s/rule/%s\n", domain, rulename)

	err := proxyDB.DeleteRule(domain, rulename)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("rule '%s' of domain '%s' is deleted", rulename, domain)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func DeleteBehaviour(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	rulename := vars["behaviour"]
	fmt.Printf("DELETE\t/restrictions/%s/list/%s\n", domain, rulename)

	err := proxyDB.DeleteBehaviour(domain, rulename)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("behaviour '%s' of domain '%s' is deleted", rulename, domain)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
