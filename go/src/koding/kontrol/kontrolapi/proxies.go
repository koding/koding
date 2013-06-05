package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"net/http"
)

func GetProxies(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("GET\t/proxies")
	res, err := proxyDB.GetProxies()
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

func GetProxy(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	proxyname := vars["proxyname"]
	fmt.Printf("GET\t/proxies/%s\n", proxyname)
	res, err := proxyDB.GetProxy(proxyname)
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
	fmt.Printf("POST\t/proxies/%s\n", proxyname)

	if proxyname == "" {
		err := errors.New("aborting. 'proxyname' field is empty")
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	err := proxyDB.AddProxy(proxyname)
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
	fmt.Printf("DELETE\t/proxies/%s\n", proxyname)

	err := proxyDB.DeleteProxy(proxyname)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("'%s' is deleted", proxyname)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
