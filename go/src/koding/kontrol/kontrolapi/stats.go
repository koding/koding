package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"net/http"
)

func GetStats(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("GET\t/stats")
	res, err := proxyDB.GetStats()
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

func GetDomainStats(writer http.ResponseWriter, req *http.Request) {
	fmt.Printf("GET\t/stats/domains\n")
	res, err := proxyDB.GetDomainStats()
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

func GetSingleDomainStats(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	fmt.Printf("GET\t/stats/domains/%s\n", domain)
	res, err := proxyDB.GetSingleDomainStats(domain)
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

func GetProxyStats(writer http.ResponseWriter, req *http.Request) {
	fmt.Printf("GET\t/stats/proxies\n")
	res, err := proxyDB.GetProxyStats()
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

func GetSingleProxyStats(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	proxy := vars["proxy"]
	fmt.Printf("GET\t/stats/proxies/%s\n", proxy)
	res, err := proxyDB.GetSingleProxyStats(proxy)
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

func DeleteStats(writer http.ResponseWriter, req *http.Request) {
	fmt.Printf("DELETE\t/stats/\n")
	err := proxyDB.DeleteStats()
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	io.WriteString(writer, "{\"res\":\"all stats are deleted\"}\n")
	return
}
