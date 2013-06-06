package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"net/http"
)

func GetDomains(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("GET\t/domains")
	domains := proxyDB.GetDomains()
	data, err := json.MarshalIndent(domains, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func GetDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domainname := vars["domain"]
	fmt.Printf("GET\t/domains/%s\n", domainname)

	domain, err := proxyDB.GetDomain(domainname)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if domain.Domainname == "" {
		http.Error(writer, fmt.Sprintf("{\"err\":\"domain '%s' does not exist\"}\n", domainname), http.StatusBadRequest)
		return
	}

	data, err := json.MarshalIndent(domain, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func CreateDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	fmt.Printf("POST\t/domains/%s\n", domain)

	p, err := unmarshalAndValidate(req)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	err = proxyDB.AddDomain(domain, p.Mode, p.Username, p.Name, p.Key, p.Host)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	var resp string
	switch p.Mode {
	case "internal":
		resp = fmt.Sprintf("{\"host\":\"%s-%s.kd.io\"}\n", p.Name, p.Key)
	case "direct":
		resp = fmt.Sprintf("{\"host\":\"%s\"}\n", p.Host)
	case "vm":
		resp = fmt.Sprintf("{\"host\":\"%s.kd.io\"}\n", p.Username)
	}

	io.WriteString(writer, resp)
	return
}

func DeleteDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	fmt.Printf("DELETE\t/domains/%s\n", domain)
	err := proxyDB.DeleteDomain(domain)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	resp := fmt.Sprintf("domain '%s' is deleted", domain)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}

func (p *ProxyPostMessage) validate() error {
	// mode can be one of the followings:
	// internal     : to point name-key.in.koding.com
	// direct       : to point host
	// vm           : to point username.kd.io
	if p.Mode == "" {
		return errors.New("Missing field 'mode'. Can be one of: internal, direct, vm")
	}

	if p.Username == "" && p.Mode != "direct" {
		return errors.New("Missing field 'username' is required with {'mode': 'vm' or 'internal'}")
	}

	if p.Name == "" && p.Mode == "internal" {
		return errors.New("Missing field 'name' is required with {'mode': 'internal'}")
	}

	if p.Key == "" && p.Mode == "internal" {
		return errors.New("Missing field 'key' is required with {'mode': 'internal'}")
	}

	if p.Host == "" && p.Mode == "direct" {
		return errors.New("Missing field 'host' is required with {'mode': 'direct}'")
	}

	return nil
}

// takes an http request, unmarshals it to a ProxyPostMessage struct,
// returns an error if the validation fails.
func unmarshalAndValidate(req *http.Request) (ProxyPostMessage, error) {
	msg := ProxyPostMessage{}
	body, err := ioutil.ReadAll(req.Body)
	if err != nil {
		return msg, err
	}

	err = json.Unmarshal(body, &msg)
	if err != nil {
		return msg, err
	}

	err = msg.validate()
	if err != nil {
		return msg, err
	}

	return msg, nil
}
