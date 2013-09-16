package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"koding/db/mongodb/modelhelper"
	"net/http"
)

type FiltersPostMessage struct {
	FilterType  *string `json:"type"`
	FilterName  *string `json:"name"`
	FilterMatch *string `json:"match"`
}

func GetFilters(writer http.ResponseWriter, req *http.Request) {
	res := modelhelper.GetFilters()
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

	res, err := modelhelper.GetFilterByField("name", name)
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

	filter := modelhelper.NewFilter(filterType, "", filterMatch)
	resFilter, err := modelhelper.AddFilter(filter)
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

	err := modelhelper.DeleteFilterByField("name", name)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("filter with name '%s' is deleted", name)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
