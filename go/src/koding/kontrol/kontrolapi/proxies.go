package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"koding/db/mongodb/modelhelper"
	"net/http"
)

func GetProxies(writer http.ResponseWriter, req *http.Request) {
	proxies := modelhelper.GetProxies()
	data, err := json.MarshalIndent(proxies, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func GetProxy(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	proxyname := vars["proxyname"]
	res, err := modelhelper.GetProxy(proxyname)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}
	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func CreateProxy(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	proxyname := vars["proxyname"]

	if proxyname == "" {
		err := errors.New("aborting. 'proxyname' field is empty")
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	err := modelhelper.AddProxy(proxyname)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("'%s' is registered", proxyname)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func DeleteProxy(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	proxyname := vars["proxyname"]

	err := modelhelper.DeleteProxy(proxyname)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("'%s' is deleted", proxyname)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
