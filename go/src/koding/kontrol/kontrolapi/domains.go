package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"koding/db/mongodb/modelhelper"
	"koding/kontrol/kontrolproxy/resolver"
	"net/http"

	"github.com/gorilla/mux"
)

func GetDomains(writer http.ResponseWriter, req *http.Request) {
	io.WriteString(writer, fmt.Sprintf("{\"res\":\" usage: /domains/<domain name>\"}\n"))
}

func GetDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domainname := vars["domain"]

	domain, err := modelhelper.GetDomain(domainname)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	if domain.Domain == "" {
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

func ResolveDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domainname := vars["domain"]

	target, err := resolver.TargetByHost(domainname)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	data, err := json.MarshalIndent(target.URL.String(), "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func CreateOrUpdateDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domainname := vars["domain"]

	p, err := unmarshalAndValidate(req)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	domain := modelhelper.NewDomain(
		domainname,
		p.Mode,
		p.Username,
		p.Name,
		p.Key,
		p.FullUrl,
		[]string{p.HostnameAlias},
	)

	switch req.Method {
	case "POST":
		err = modelhelper.AddDomain(domain)
		if err != nil {
			http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
			return
		}
	case "PUT":
		err = modelhelper.UpdateDomain(domain)
		if err != nil {
			http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
			return
		}
	}

	var resp string
	switch p.Mode {
	case resolver.ModeInternal, resolver.ModeVM:
		resp = fmt.Sprintf("{\"host\":\"%s\"}\n", domainname)
	case resolver.ModeRedirect:
		resp = fmt.Sprintf("{\"host\":\"%s\"}\n", p.FullUrl)
	case resolver.ModeMaintenance:
		resp = fmt.Sprintf("{\"res\":\"maintenance mode enabled for %s\"}\n", domainname)
	}

	io.WriteString(writer, resp)
	return
}

func DeleteDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]
	err := modelhelper.DeleteDomain(domain)
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
	// internal 	: to point name-key.in.koding.com
	// redirect 	: to point fullurl
	// vm       	: to point username.kd.io
	// maintenance	: to show maintenance static page
	if p.Mode == "" {
		return errors.New("Missing field 'mode'. Can be one of: internal, redirect, vm and maintenance")
	}

	if p.Username == "" && p.Mode == resolver.ModeInternal {
		return errors.New("Missing field 'username' is required with {'mode': 'internal'}")
	}

	if p.Name == "" && p.Mode == resolver.ModeInternal {
		return errors.New("Missing field 'name' is required with {'mode': 'internal'}")
	}

	if p.Key == "" && p.Mode == resolver.ModeInternal {
		return errors.New("Missing field 'key' is required with {'mode': 'internal'}")
	}

	if p.FullUrl == "" && p.Mode == resolver.ModeRedirect {
		return errors.New("Missing field 'fullUrl' is required with {'mode': 'redirect}'")
	}

	if p.HostnameAlias == "" && p.Mode == resolver.ModeVM {
		return errors.New("Missing field 'hostnameAlias' is required with {'mode': 'vm}'")
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
