package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"net/http"
)

type FiltersPostMessage struct {
	FilterType  *string `json:"type"`
	FilterName  *string `json:"name"`
	FilterMatch *string `json:"match"`
}

func GetFilters(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("GET\t/filters")
	res := proxyDB.GetFilters()
	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	writer.Write([]byte(data))
}

func GetFilter(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	match := vars["match"]
	fmt.Printf("GET\t/filters/%s\n", match)

	res, err := proxyDB.GetFilter(match)
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

func CreateFilterByMatch(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	match := vars["match"]
	fmt.Printf("POST\t/filters/%s\n", match)

	var msg FiltersPostMessage
	var filterType string

	body, _ := ioutil.ReadAll(req.Body)
	err := json.Unmarshal(body, &msg)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if match == "" {
		err := "match field can't be empty"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}
	if msg.FilterType != nil {
		filterType = *msg.FilterType
	} else {
		err := "no 'type' field available"
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	// disabled for now, is generated automatically
	// if msg.FilterName != nil {
	// 	ruleName = *msg.FilterName
	// } else {
	// 	err := "no 'name' field available"
	// 	http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
	// 	return
	// }

	filter := proxyconfig.NewFilter(filterType, "", match)
	resFilter, err := proxyDB.AddFilter(filter)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	data, err := json.MarshalIndent(resFilter, "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}
	writer.Write([]byte(data))
	return
}

func DeleteFilterByMatch(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	match := vars["match"]
	fmt.Printf("DELETE\t/filters/%s\n", match)

	err := proxyDB.DeleteFilter(match)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("filter with match '%s' is deleted", match)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
