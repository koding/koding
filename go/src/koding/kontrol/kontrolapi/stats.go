package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"net/http"
)

func GetDomainStats(writer http.ResponseWriter, req *http.Request) {
	fmt.Printf("GET\t/stats/domains\n")
	res := proxyDB.GetDomainStats()
	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}
	writer.Write([]byte(data))
}

func GetDomainStat(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	fmt.Printf("GET\t/stats/domains/%s\n", domain)
	res, err := proxyDB.GetDomainStat(domain)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if res.Domainname == "" {
		http.Error(writer, fmt.Sprintf("{\"err\":\"stat for domain %s does not exist\"}\n", domain), http.StatusBadRequest)
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
	res := proxyDB.GetProxyStats()
	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}
	writer.Write([]byte(data))
}

func GetProxyStat(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	proxy := vars["proxy"]
	fmt.Printf("GET\t/stats/proxies/%s\n", proxy)
	res, err := proxyDB.GetProxyStat(proxy)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if res.Proxyname == "" {
		http.Error(writer, fmt.Sprintf("{\"err\":\"stat for proxy %s does not exist\"}\n", proxy), http.StatusBadRequest)
		return
	}

	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}
	writer.Write([]byte(data))
}

func DeleteDomainStat(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	fmt.Printf("DELETE\t/stats/domains/%s\n", domain)
	err := proxyDB.DeleteDomainStat(domain)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("stats for domain '%s' is deleted", domain)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func DeleteProxyStat(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	proxy := vars["proxy"]
	fmt.Printf("DELETE\t/stats/proxies/%s\n", proxy)
	err := proxyDB.DeleteProxyStat(proxy)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("stats for proxy '%s' is deleted", proxy)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
