//
// gosdc - Go library to interact with the Joyent CloudAPI
//
// CloudAPI double testing service - HTTP API implementation
//
// Copyright (c) Joyent Inc.
//

package cloudapi

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"strconv"
	"strings"

	"github.com/joyent/gosdc/cloudapi"
	"github.com/julienschmidt/httprouter"
)

// ErrorResponse defines a single HTTP error response.
type ErrorResponse struct {
	Code        int
	Body        string
	contentType string
	errorText   string
	headers     map[string]string
	cloudapi    *CloudAPI
}

var (
	// ErrNotAllowed is returned when the request's method is not allowed
	ErrNotAllowed = &ErrorResponse{
		http.StatusMethodNotAllowed,
		"Method is not allowed",
		"text/plain; charset=UTF-8",
		"MethodNotAllowedError",
		nil,
		nil,
	}

	// ErrNotFound is returned when the requested resource is not found
	ErrNotFound = &ErrorResponse{
		http.StatusNotFound,
		"Resource Not Found",
		"text/plain; charset=UTF-8",
		"NotFoundError",
		nil,
		nil,
	}

	// ErrBadRequest is returned when the request is malformed or incorrect
	ErrBadRequest = &ErrorResponse{
		http.StatusBadRequest,
		"Malformed request url",
		"text/plain; charset=UTF-8",
		"BadRequestError",
		nil,
		nil,
	}
)

func (e *ErrorResponse) Error() string {
	return e.errorText
}

func (e *ErrorResponse) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if e.contentType != "" {
		w.Header().Set("Content-Type", e.contentType)
	}
	body := e.Body
	if e.headers != nil {
		for h, v := range e.headers {
			w.Header().Set(h, v)
		}
	}
	// workaround for https://code.google.com/p/go/issues/detail?id=4454
	w.Header().Set("Content-Length", strconv.Itoa(len(body)))
	if e.Code != 0 {
		w.WriteHeader(e.Code)
	}
	if len(body) > 0 {
		w.Write([]byte(body))
	}
}

type cloudapiHandler struct {
	cloudapi *CloudAPI
	method   func(m *CloudAPI, w http.ResponseWriter, r *http.Request, p httprouter.Params) error
}

func (h *cloudapiHandler) ServeHTTP(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	path := r.URL.Path
	// handle trailing slash in the path
	if strings.HasSuffix(path, "/") && path != "/" {
		ErrNotFound.ServeHTTP(w, r)
		return
	}
	err := h.method(h.cloudapi, w, r, p)
	if err == nil {
		return
	}
	var resp http.Handler
	resp, _ = err.(http.Handler)
	if resp == nil {
		resp = &ErrorResponse{
			http.StatusInternalServerError,
			`{"internalServerError":{"message":"Unkown Error",code:500}}`,
			"application/json",
			err.Error(),
			nil,
			h.cloudapi,
		}
	}
	resp.ServeHTTP(w, r)
}

func writeResponse(w http.ResponseWriter, code int, body []byte) {
	// workaround for https://code.google.com/p/go/issues/detail?id=4454
	w.Header().Set("Content-Length", strconv.Itoa(len(body)))
	w.WriteHeader(code)
	w.Write(body)
}

// sendJSON sends the specified response serialized as JSON.
func sendJSON(code int, resp interface{}, w http.ResponseWriter, r *http.Request) error {
	data, err := json.Marshal(resp)
	if err != nil {
		return err
	}
	w.Header().Set("Content-Type", "application/json")
	writeResponse(w, code, data)
	return nil
}

func processFilter(rawQuery string) map[string]string {
	var filters map[string]string
	if rawQuery != "" {
		filters = make(map[string]string)
		for _, filter := range strings.Split(rawQuery, "&") {
			filters[filter[:strings.Index(filter, "=")]] = filter[strings.Index(filter, "=")+1:]
		}
	}

	return filters
}

func (c *CloudAPI) handler(method func(m *CloudAPI, w http.ResponseWriter, r *http.Request, p httprouter.Params) error) httprouter.Handle {
	handler := &cloudapiHandler{c, method}
	return handler.ServeHTTP
}

// Keys

func (c *CloudAPI) handleListKeys(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	keys, err := c.ListKeys()
	if err != nil {
		return err
	}
	if keys == nil {
		keys = []cloudapi.Key{}
	}
	return sendJSON(http.StatusOK, keys, w, r)
}

func (c *CloudAPI) handleGetKey(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	key, err := c.GetKey(params.ByName("id"))
	if err != nil {
		return err // TODO: 404 if key not found
	}
	if key == nil {
		key = &cloudapi.Key{}
	}
	return sendJSON(http.StatusOK, key, w, r)
}

func (c *CloudAPI) handleCreateKey(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	opts := &cloudapi.CreateKeyOpts{}
	body, err := ioutil.ReadAll(r.Body)
	defer r.Body.Close()

	if err != nil {
		return err
	}
	if len(body) > 0 {
		if err := json.Unmarshal(body, opts); err != nil {
			return err
		}
	}

	key, err := c.CreateKey(opts.Name, opts.Key)
	if err != nil {
		return err
	}
	if key == nil {
		key = &cloudapi.Key{}
	}
	return sendJSON(http.StatusCreated, key, w, r)
}

func (c *CloudAPI) handleDeleteKey(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	err := c.DeleteKey(params.ByName("id"))
	if err != nil {
		return err // TODO: handle 404
	}

	return sendJSON(http.StatusNoContent, nil, w, r)
}

// images

func (c *CloudAPI) handleListImages(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	images, err := c.ListImages(processFilter(r.URL.RawQuery))
	if err != nil {
		return err
	}
	if images == nil {
		images = []cloudapi.Image{}
	}
	return sendJSON(http.StatusOK, images, w, r)
}

func (c *CloudAPI) handleGetImage(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	image, err := c.GetImage(params.ByName("id"))
	if err != nil {
		return err // TODO: 404
	}
	if image == nil {
		image = &cloudapi.Image{}
	}
	return sendJSON(http.StatusOK, image, w, r)
}

func (c *CloudAPI) handleCreateImageFromMachine(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	return ErrNotFound // TODO: implement
}

func (c *CloudAPI) handleDeleteImage(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	// TODO: implement c.DeleteImage
	// err := c.DeleteImage(params.ByName("id"))
	// if err != nil {
	// 	return err // TODO: 404
	// }
	// return sendJSON(http.StatusNoContent, nil, w, r)
	return ErrNotAllowed
}

// packages

func (c *CloudAPI) handleListPackages(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	pkgs, err := c.ListPackages(processFilter(r.URL.RawQuery))
	if err != nil {
		return err
	}
	if pkgs == nil {
		pkgs = []cloudapi.Package{}
	}
	return sendJSON(http.StatusOK, pkgs, w, r)
}

func (c *CloudAPI) handleGetPackage(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	pkg, err := c.GetPackage(params.ByName("id"))
	if err != nil {
		return err // TODO: 404
	}
	if pkg == nil {
		pkg = &cloudapi.Package{}
	}
	return sendJSON(http.StatusOK, pkg, w, r)
}

// machines

func (c *CloudAPI) handleListMachines(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	machines, err := c.ListMachines(processFilter(r.URL.RawQuery))
	if err != nil {
		return err
	}
	if machines == nil {
		machines = []*cloudapi.Machine{}
	}
	return sendJSON(http.StatusOK, machines, w, r)
}

func (c *CloudAPI) handleCountMachines(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	count, err := c.CountMachines()
	if err != nil {
		return err
	}
	return sendJSON(http.StatusOK, count, w, r)
}

func (c *CloudAPI) handleGetMachine(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	machine, err := c.GetMachine(params.ByName("id"))
	if err != nil {
		return err // TODO: 404
	}
	if machine == nil {
		machine = &cloudapi.Machine{}
	}
	return sendJSON(http.StatusOK, machine, w, r)
}

func (c *CloudAPI) handleCreateMachine(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	var (
		name     string
		pkg      string
		image    string
		networks []string
		metadata = map[string]string{}
		tags     = map[string]string{}
	)
	opts := map[string]interface{}{}
	body, err := ioutil.ReadAll(r.Body)
	defer r.Body.Close()
	if err != nil {
		return err
	}
	if len(body) == 0 {
		return ErrBadRequest
	}

	if err := json.Unmarshal(body, &opts); err != nil {
		return err
	}
	for k, v := range opts {
		if v == nil {
			continue
		}

		switch k {
		case "name":
			name = v.(string)
		case "package":
			pkg = v.(string)
		case "image":
			image = v.(string)
		case "networks":
			networks = []string{}
			for _, n := range v.([]interface{}) {
				networks = append(networks, n.(string))
			}
		default:
			if strings.HasPrefix(k, "tag.") {
				tags[k[4:]] = v.(string)
				continue
			}
			if strings.HasPrefix(k, "metadata.") {
				metadata[k[9:]] = v.(string)
				continue
			}
		}
	}

	machine, err := c.CreateMachine(name, pkg, image, networks, metadata, tags)
	if err != nil {
		return err
	}
	if machine == nil {
		machine = &cloudapi.Machine{}
	}
	return sendJSON(http.StatusCreated, machine, w, r)
}

func (c *CloudAPI) handleUpdateMachine(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	var (
		err error
		id  = params.ByName("id")
	)

	switch r.URL.Query().Get("action") {
	case "stop":
		err = c.StopMachine(id)

	case "start":
		err = c.StartMachine(id)

	case "reboot":
		err = c.RebootMachine(id)

	case "resize":
		err = c.ResizeMachine(id, r.URL.Query().Get("package"))

	case "rename":
		err = c.RenameMachine(id, r.URL.Query().Get("name"))

	case "enable_firewall":
		err = c.EnableFirewallMachine(id)

	case "disable_firewall":
		err = c.DisableFirewallMachine(id)

	default:
		return ErrNotAllowed
	}

	if err != nil {
		return err
	}
	return sendJSON(http.StatusAccepted, nil, w, r)
}

func (c *CloudAPI) handleDeleteMachine(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	err := c.DeleteMachine(params.ByName("id"))
	if err != nil {
		return err // TODO: 404
	}
	return sendJSON(http.StatusNoContent, nil, w, r)
}

func (c *CloudAPI) handleMachineFirewallRules(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	rules, err := c.ListMachineFirewallRules(params.ByName("id"))
	if err != nil {
		return err // TODO: 404
	}
	if rules == nil {
		rules = []*cloudapi.FirewallRule{}
	}
	return sendJSON(http.StatusOK, rules, w, r)
}

// machine metadata

func (c *CloudAPI) handleGetMachineMetadata(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	metadata, err := c.GetMachineMetadata(params.ByName("id"))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusOK, metadata, w, r)
}

func (c *CloudAPI) handleUpdateMachineMetadata(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	metadata := make(map[string]string)

	body, err := ioutil.ReadAll(r.Body)
	defer r.Body.Close()
	if err != nil {
		return err
	}

	err = json.Unmarshal(body, &metadata)
	if err != nil {
		return err
	}

	metadata, err = c.UpdateMachineMetadata(params.ByName("id"), metadata)
	if err != nil {
		return err
	}

	return sendJSON(http.StatusOK, metadata, w, r)
}

func (c *CloudAPI) handleDeleteMachineMetadata(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	err := c.DeleteMachineMetadata(params.ByName("id"), params.ByName("key"))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusNoContent, nil, w, r)
}

func (c *CloudAPI) handleDeleteAllMachineMetadata(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	err := c.DeleteAllMachineMetadata(params.ByName("id"))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusNoContent, nil, w, r)
}

// machine tags

func (c *CloudAPI) handleListMachineTags(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	tags, err := c.ListMachineTags(params.ByName("id"))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusOK, tags, w, r)
}

func (c *CloudAPI) handleAddMachineTags(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	tags := make(map[string]string)

	body, err := ioutil.ReadAll(r.Body)
	defer r.Body.Close()
	if err != nil {
		return err
	}

	err = json.Unmarshal(body, &tags)
	if err != nil {
		return err
	}

	tags, err = c.AddMachineTags(params.ByName("id"), tags)
	if err != nil {
		return err
	}

	return sendJSON(http.StatusOK, tags, w, r)
}

func (c *CloudAPI) handleReplaceMachineTags(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	tags := make(map[string]string)

	body, err := ioutil.ReadAll(r.Body)
	defer r.Body.Close()
	if err != nil {
		return err
	}

	err = json.Unmarshal(body, &tags)
	if err != nil {
		return err
	}

	tags, err = c.ReplaceMachineTags(params.ByName("id"), tags)
	if err != nil {
		return err
	}

	return sendJSON(http.StatusOK, tags, w, r)
}

func (c *CloudAPI) handleDeleteMachineTags(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	err := c.DeleteMachineTags(params.ByName("id"))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusNoContent, nil, w, r)
}

func (c *CloudAPI) handleDeleteMachineTag(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	err := c.DeleteMachineTag(params.ByName("id"), params.ByName("tag"))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusNoContent, nil, w, r)
}

func (c *CloudAPI) handleGetMachineTag(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	tag, err := c.GetMachineTag(params.ByName("id"), params.ByName("tag"))
	if err != nil {
		return err
	}

	w.Header().Add("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(tag))

	return nil
}

// NICs

func (c *CloudAPI) handleListNICs(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	nics, err := c.ListNICs(params.ByName("id"))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusOK, nics, w, r)
}

func (c *CloudAPI) handleGetNIC(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	nic, err := c.GetNIC(params.ByName("id"), params.ByName("mac"))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusOK, nic, w, r)
}

type addNICOptions struct {
	Network string `json:"network"`
}

func (c *CloudAPI) handleAddNIC(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	opts := new(addNICOptions)
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		return err
	}
	if len(body) == 0 {
		return ErrBadRequest
	}
	if err = json.Unmarshal(body, opts); err != nil {
		return err
	}

	nic, err := c.AddNIC(params.ByName("id"), opts.Network)
	if err != nil {
		return err
	}

	return sendJSON(http.StatusCreated, nic, w, r)
}

func (c *CloudAPI) handleRemoveNIC(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	err := c.RemoveNIC(params.ByName("id"), params.ByName("mac"))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusNoContent, nil, w, r)
}

// firewall rules

func (c *CloudAPI) handleListFirewallRules(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	rules, err := c.ListFirewallRules()
	if err != nil {
		return err
	}
	if rules == nil {
		rules = []*cloudapi.FirewallRule{}
	}
	return sendJSON(http.StatusOK, rules, w, r)
}

func (c *CloudAPI) handleGetFirewallRule(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	rule, err := c.GetFirewallRule(params.ByName("id"))
	if err != nil {
		return err // TODO: 404
	}
	if rule == nil {
		rule = &cloudapi.FirewallRule{}
	}
	return sendJSON(http.StatusOK, rule, w, r)
}

func (c *CloudAPI) handleCreateFirewallRule(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	opts := new(cloudapi.CreateFwRuleOpts)
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		return err
	}
	if len(body) == 0 {
		return ErrBadRequest
	}
	if err = json.Unmarshal(body, opts); err != nil {
		return err
	}

	rule, err := c.CreateFirewallRule(opts.Rule, opts.Enabled)
	if err != nil {
		return err
	}
	if rule == nil {
		rule = &cloudapi.FirewallRule{}
	}
	return sendJSON(http.StatusCreated, rule, w, r)
}

func (c *CloudAPI) handleUpdateFirewallRule(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	opts := new(cloudapi.CreateFwRuleOpts)
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		return err
	}
	if len(body) == 0 {
		return ErrBadRequest
	}
	if err = json.Unmarshal(body, opts); err != nil {
		return err
	}

	rule, err := c.UpdateFirewallRule(params.ByName("id"), opts.Rule, opts.Enabled)
	if err != nil {
		return err // TODO: 404
	}
	if rule == nil {
		rule = new(cloudapi.FirewallRule)
	}
	return sendJSON(http.StatusOK, rule, w, r)
}

func (c *CloudAPI) handleDeleteFirewallRule(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	err := c.DeleteFirewallRule(params.ByName("id"))
	if err != nil {
		return err
	}
	return sendJSON(http.StatusNoContent, nil, w, r)
}

func (c *CloudAPI) handleEnableFirewallRule(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	rule, err := c.EnableFirewallRule(params.ByName("id"))
	if err != nil {
		return err // TODO: 404
	}
	if rule == nil {
		rule = new(cloudapi.FirewallRule)
	}
	return sendJSON(http.StatusOK, rule, w, r)
}

func (c *CloudAPI) handleDisableFirewallRule(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	rule, err := c.DisableFirewallRule(params.ByName("id"))
	if err != nil {
		return err // TODO: 404
	}
	if rule == nil {
		rule = new(cloudapi.FirewallRule)
	}
	return sendJSON(http.StatusOK, rule, w, r)
}

// Networks

func (c *CloudAPI) handleListNetworks(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	networks, err := c.ListNetworks()
	if err != nil {
		return err
	}
	if networks == nil {
		networks = []cloudapi.Network{}
	}
	return sendJSON(http.StatusOK, networks, w, r)
}

func (c *CloudAPI) handleGetNetwork(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	network, err := c.GetNetwork(params.ByName("id"))
	if err != nil {
		return err // TODO: 404
	}
	if network == nil {
		network = new(cloudapi.Network)
	}
	return sendJSON(http.StatusOK, network, w, r)
}

// Fabrics + VLANs and Networks

func (c *CloudAPI) handleListFabricVLANs(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	vlans, err := c.ListFabricVLANs()
	if err != nil {
		return err
	}

	return sendJSON(http.StatusOK, vlans, w, r)
}

func (c *CloudAPI) handleCreateFabricVLAN(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		return err
	}
	if len(body) == 0 {
		return ErrBadRequest
	}

	var opts cloudapi.FabricVLAN
	if err = json.Unmarshal(body, &opts); err != nil {
		return err
	}

	vlan, err := c.CreateFabricVLAN(opts)
	if err != nil {
		return err
	}

	return sendJSON(http.StatusCreated, vlan, w, r)
}

func (c *CloudAPI) handleGetFabricVLAN(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	id, err := strconv.Atoi(params.ByName("id"))
	if err != nil {
		return err
	}

	vlan, err := c.GetFabricVLAN(int16(id))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusOK, vlan, w, r)
}

func (c *CloudAPI) handleUpdateFabricVLAN(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		return err
	}
	if len(body) == 0 {
		return ErrBadRequest
	}

	var opts cloudapi.FabricVLAN
	if err = json.Unmarshal(body, &opts); err != nil {
		return err
	}

	vlan, err := c.UpdateFabricVLAN(opts)
	if err != nil {
		return err
	}

	return sendJSON(http.StatusAccepted, vlan, w, r)
}

func (c *CloudAPI) handleDeleteFabricVLAN(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	id, err := strconv.Atoi(params.ByName("id"))
	if err != nil {
		return err
	}

	err = c.DeleteFabricVLAN(int16(id))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusNoContent, nil, w, r)
}

func (c *CloudAPI) handleListFabricNetworks(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	id, err := strconv.Atoi(params.ByName("id"))
	if err != nil {
		return err
	}

	networks, err := c.ListFabricNetworks(int16(id))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusOK, networks, w, r)
}

func (c *CloudAPI) handleCreateFabricNetwork(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	id, err := strconv.Atoi(params.ByName("id"))
	if err != nil {
		return err
	}

	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		return err
	}
	if len(body) == 0 {
		return ErrBadRequest
	}

	var opts cloudapi.CreateFabricNetworkOpts
	if err = json.Unmarshal(body, &opts); err != nil {
		return err
	}

	network, err := c.CreateFabricNetwork(int16(id), opts)
	if err != nil {
		return err
	}

	return sendJSON(http.StatusCreated, network, w, r)
}

func (c *CloudAPI) handleGetFabricNetwork(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	id, err := strconv.Atoi(params.ByName("id"))
	if err != nil {
		return err
	}

	network, err := c.GetFabricNetwork(int16(id), params.ByName("network"))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusOK, network, w, r)
}

func (c *CloudAPI) handleDeleteFabricNetwork(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	id, err := strconv.Atoi(params.ByName("id"))
	if err != nil {
		return err
	}

	err = c.DeleteFabricNetwork(int16(id), params.ByName("network"))
	if err != nil {
		return err
	}

	return sendJSON(http.StatusNoContent, nil, w, r)
}

// ListServices handler

func (c *CloudAPI) handleGetServices(w http.ResponseWriter, r *http.Request, params httprouter.Params) error {
	services := map[string]string{
		"cloudapi": "https://us-west-1.api.example.com",
	}
	return sendJSON(http.StatusOK, services, w, r)
}

// Error responses

type NotFound struct{}

func (NotFound) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte("Resource Not Found"))
}

type MethodNotAllowed struct{}

func (MethodNotAllowed) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusMethodNotAllowed)
	w.Write([]byte("Method is not allowed"))
}

// SetupHTTP attaches all the needed handlers to provide the HTTP API.
func (c *CloudAPI) SetupHTTP(mux *httprouter.Router) {
	baseRoute := "/" + c.ServiceInstance.UserAccount

	mux.NotFound = NotFound{}
	mux.MethodNotAllowed = MethodNotAllowed{}

	// keys
	keysRoute := baseRoute + "/keys"
	mux.GET(keysRoute, c.handler((*CloudAPI).handleListKeys))
	mux.POST(keysRoute, c.handler((*CloudAPI).handleCreateKey))

	// key
	keyRoute := keysRoute + "/:id"
	mux.GET(keyRoute, c.handler((*CloudAPI).handleGetKey))
	mux.DELETE(keyRoute, c.handler((*CloudAPI).handleDeleteKey))

	// images
	imagesRoute := baseRoute + "/images"
	mux.GET(imagesRoute, c.handler((*CloudAPI).handleListImages))

	// image
	imageRoute := imagesRoute + "/:id"
	mux.GET(imageRoute, c.handler((*CloudAPI).handleGetImage))
	mux.POST(imageRoute, c.handler((*CloudAPI).handleCreateImageFromMachine))
	mux.DELETE(imageRoute, c.handler((*CloudAPI).handleDeleteImage))

	// packages
	packagesRoute := baseRoute + "/packages"
	mux.GET(packagesRoute, c.handler((*CloudAPI).handleListPackages))

	// package
	packageRoute := packagesRoute + "/:id"
	mux.GET(packageRoute, c.handler((*CloudAPI).handleGetPackage))

	// machines
	machinesRoute := baseRoute + "/machines"
	mux.GET(machinesRoute, c.handler((*CloudAPI).handleListMachines))
	mux.HEAD(machinesRoute, c.handler((*CloudAPI).handleCountMachines))
	mux.POST(machinesRoute, c.handler((*CloudAPI).handleCreateMachine))

	// machine
	machineRoute := machinesRoute + "/:id"
	mux.GET(machineRoute, c.handler((*CloudAPI).handleGetMachine))
	mux.POST(machineRoute, c.handler((*CloudAPI).handleUpdateMachine))
	mux.DELETE(machineRoute, c.handler((*CloudAPI).handleDeleteMachine))

	// machine metadata
	machineMetadataRoute := machineRoute + "/metadata"
	mux.GET(machineMetadataRoute, c.handler((*CloudAPI).handleGetMachineMetadata))
	mux.POST(machineMetadataRoute, c.handler((*CloudAPI).handleUpdateMachineMetadata))
	mux.DELETE(machineMetadataRoute, c.handler((*CloudAPI).handleDeleteAllMachineMetadata))

	// machine metadata (individual key)
	machineMetadataKeyRoute := machineMetadataRoute + "/:key"
	mux.DELETE(machineMetadataKeyRoute, c.handler((*CloudAPI).handleDeleteMachineMetadata))

	// machine tags
	machineTagsRoute := machineRoute + "/tags"
	mux.GET(machineTagsRoute, c.handler((*CloudAPI).handleListMachineTags))
	mux.POST(machineTagsRoute, c.handler((*CloudAPI).handleAddMachineTags))
	mux.PUT(machineTagsRoute, c.handler((*CloudAPI).handleReplaceMachineTags))
	mux.DELETE(machineTagsRoute, c.handler((*CloudAPI).handleDeleteMachineTags))

	// machine tag
	machineTagRoute := machineTagsRoute + "/:tag"
	mux.GET(machineTagRoute, c.handler((*CloudAPI).handleGetMachineTag))
	mux.DELETE(machineTagRoute, c.handler((*CloudAPI).handleDeleteMachineTag))

	// machine firewall rules
	machineFWRulesRoute := machineRoute + "/fwrules"
	mux.GET(machineFWRulesRoute, c.handler((*CloudAPI).handleMachineFirewallRules))

	// machine NICs
	machineNICsRoute := machineRoute + "/nics"
	mux.GET(machineNICsRoute, c.handler((*CloudAPI).handleListNICs))
	mux.POST(machineNICsRoute, c.handler((*CloudAPI).handleAddNIC))

	// machine NIC
	machineNICRoute := machineNICsRoute + "/:mac"
	mux.GET(machineNICRoute, c.handler((*CloudAPI).handleGetNIC))
	mux.DELETE(machineNICRoute, c.handler((*CloudAPI).handleRemoveNIC))

	// firewall rules
	firewallRulesRoute := baseRoute + "/fwrules"
	mux.GET(firewallRulesRoute, c.handler((*CloudAPI).handleListFirewallRules))
	mux.POST(firewallRulesRoute, c.handler((*CloudAPI).handleCreateFirewallRule))

	// firewall rule
	firewallRuleRoute := firewallRulesRoute + "/:id"
	mux.GET(firewallRuleRoute, c.handler((*CloudAPI).handleGetFirewallRule))
	mux.POST(firewallRuleRoute, c.handler((*CloudAPI).handleUpdateFirewallRule))
	mux.DELETE(firewallRuleRoute, c.handler((*CloudAPI).handleDeleteFirewallRule))
	mux.POST(firewallRuleRoute+"/enable", c.handler((*CloudAPI).handleEnableFirewallRule))
	mux.POST(firewallRuleRoute+"/disable", c.handler((*CloudAPI).handleDisableFirewallRule))

	// networks
	networksRoute := baseRoute + "/networks"
	mux.GET(networksRoute, c.handler((*CloudAPI).handleListNetworks))

	// network
	networkRoute := networksRoute + "/:id"
	mux.GET(networkRoute, c.handler((*CloudAPI).handleGetNetwork))

	// fabric VLANs
	fabricVLANsRoute := baseRoute + "/fabrics/:fabric/vlans"
	mux.GET(fabricVLANsRoute, c.handler((*CloudAPI).handleListFabricVLANs))
	mux.POST(fabricVLANsRoute, c.handler((*CloudAPI).handleCreateFabricVLAN))

	// fabric VLAN
	fabricVLANRoute := fabricVLANsRoute + "/:id"
	mux.GET(fabricVLANRoute, c.handler((*CloudAPI).handleGetFabricVLAN))
	mux.PUT(fabricVLANRoute, c.handler((*CloudAPI).handleUpdateFabricVLAN))
	mux.DELETE(fabricVLANRoute, c.handler((*CloudAPI).handleDeleteFabricVLAN))

	// fabric VLAN networks
	fabricVLANNetworksRoute := fabricVLANRoute + "/networks"
	mux.GET(fabricVLANNetworksRoute, c.handler((*CloudAPI).handleListFabricNetworks))
	mux.POST(fabricVLANNetworksRoute, c.handler((*CloudAPI).handleCreateFabricNetwork))

	// fabric VLAN network
	fabricVLANNetworkRoute := fabricVLANNetworksRoute + "/:network"
	mux.GET(fabricVLANNetworkRoute, c.handler((*CloudAPI).handleGetFabricNetwork))
	mux.DELETE(fabricVLANNetworkRoute, c.handler((*CloudAPI).handleDeleteFabricNetwork))

	// services
	servicesRoute := baseRoute + "/services"
	mux.GET(servicesRoute, c.handler((*CloudAPI).handleGetServices))
}
