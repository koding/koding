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

func GetFilterByName(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	name := vars["name"]
	fmt.Printf("GET\t/filters/%s\n", name)

	res, err := proxyDB.GetFilterByField("name", name)
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

func CreateFilterByName(writer http.ResponseWriter, req *http.Request) {
	fmt.Printf("POST\t/filters\n")
	var msg FiltersPostMessage
	var filterType string
	var filterMatch string

	body, _ := ioutil.ReadAll(req.Body)
	err := json.Unmarshal(body, &msg)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if msg.FilterMatch != nil {
		filterMatch = *msg.FilterMatch
		if filterMatch == "" {
			err := "match field can't be empty"
			http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
			return
		}
	} else {
		err := "no 'match' field available"
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

	filter := proxyconfig.NewFilter(filterType, "", filterMatch)
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

func DeleteFilterByName(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	name := vars["name"]
	fmt.Printf("DELETE\t/filters/%s\n", name)

	err := proxyDB.DeleteFilterByField("name", name)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("filter with name '%s' is deleted", name)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
