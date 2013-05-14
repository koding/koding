package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"koding/kontrol/kontroldaemon/clientconfig"
	"koding/kontrol/kontroldaemon/workerconfig"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"koding/tools/config"
	"labix.org/v2/mgo/bson"
	"log"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"
)

type Worker struct {
	Name      string    `json:"name"`
	Uuid      string    `json:"uuid"`
	Hostname  string    `json:"hostname"`
	Version   int       `json:"version"`
	Timestamp time.Time `json:"timestamp"`
	Pid       int       `json:"pid"`
	State     string    `json:"state"`
	Uptime    int       `json:"uptime"`
	Port      int       `json:"port"`
}

type Workers []Worker

type Proxy struct {
	Key       string
	Host      string
	Hostdata  string
	RabbitKey string
}
type Proxies []Proxy

type ProxyMachine struct {
	Uuid string
	Keys []string
}
type ProxyMachines []ProxyMachine

type RulesPostMessage struct {
	IpRegex *string
}

type ProxyPostMessage struct {
	Name      *string
	Username  *string
	Domain    *string
	Key       *string
	RabbitKey *string
	Host      *string
	Hostdata  *string
	Uuid      *string
}

type DeployPostMessage struct {
	Build  *string
	Git    *string
	Config *string
}

var StatusCode = map[workerconfig.WorkerStatus]string{
	workerconfig.Running:    "running",
	workerconfig.Pending:    "waiting",
	workerconfig.Waiting:    "waiting",
	workerconfig.Stopped:    "stopped",
	workerconfig.Notstarted: "stopped",
	workerconfig.Killed:     "dead",
	workerconfig.Dead:       "dead",
}

var clientDB *clientconfig.ClientConfig
var kontrolConfig *workerconfig.WorkerConfig
var proxyConfig *proxyconfig.ProxyConfiguration

func init() {
	log.SetPrefix("kontrol-api ")
}

func main() {
	amqpWrapper := setupAmqp()
	listenTell = setupListenTell(amqpWrapper)

	var err error
	kontrolConfig, err = workerconfig.Connect()
	if err != nil {
		log.Fatalf("wokerconfig mongodb connect: %s", err)
	}

	proxyConfig, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	clientDB, err = clientconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	port := strconv.Itoa(config.Current.Kontrold.Api.Port)

	rout := mux.NewRouter()
	rout.HandleFunc("/", home).Methods("GET")

	// Deployment handlers
	rout.HandleFunc("/deployments", GetClients).Methods("GET")
	rout.HandleFunc("/deployments", CreateClient).Methods("POST")
	rout.HandleFunc("/deployments/{build}", GetClient).Methods("GET")

	// Worker handlers
	rout.HandleFunc("/workers", GetWorkers).Methods("GET")
	rout.HandleFunc("/workers/{uuid}", GetWorker).Methods("GET")
	rout.HandleFunc("/workers/{uuid}/{action}", UpdateWorker).Methods("PUT")
	rout.HandleFunc("/workers/{uuid}", DeleteWorker).Methods("DELETE")

	// Proxy handlers
	rout.HandleFunc("/proxies", GetProxies).Methods("GET")
	rout.HandleFunc("/proxies", CreateProxy).Methods("POST")
	rout.HandleFunc("/proxies/{uuid}", DeleteProxy).Methods("DELETE")

	// Proxy service handlers
	rout.HandleFunc("/proxies/{uuid}/services", GetProxyUsers).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/services/{username}", GetProxyServices).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/services/{username}", CreateProxyUser).Methods("POST")
	rout.HandleFunc("/proxies/{uuid}/services/{username}/{servicename}", GetProxyService).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/services/{username}/{servicename}", CreateProxyService).Methods("POST")
	rout.HandleFunc("/proxies/{uuid}/services/{username}/{servicename}", DeleteProxyService).Methods("DELETE")
	rout.HandleFunc("/proxies/{uuid}/services/{username}/{servicename}/{key}", DeleteProxyServiceKey).Methods("DELETE")

	// Proxy domain handlers
	rout.HandleFunc("/proxies/{uuid}/domains", GetProxyDomains).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/domains/{domain}", CreateProxyDomain).Methods("POST")
	rout.HandleFunc("/proxies/{uuid}/domains/{domain}", DeleteProxyDomain).Methods("DELETE")

	// Proxy rule handlers
	rout.HandleFunc("/proxies/{uuid}/rules", GetRules).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/rules/{username}", GetUserRules).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/rules/{username}/{servicename}", GetUserServiceRules).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/rules/{username}/{servicename}", CreateUserServiceRules).Methods("POST")

	// Rollbar api
	rout.HandleFunc("/rollbar", rollbar).Methods("POST")

	log.Printf("kontrol api is started. serving at :%s ...", port)

	http.Handle("/", rout)
	err = http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Println(err)
	}
}

func GetRules(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	users := make([]string, 0)
	proxyMachine, _ := proxyConfig.GetProxy(uuid)
	for username := range proxyMachine.Rules {
		users = append(users, username)
	}
	data, err := json.MarshalIndent(users, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func GetUserRules(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	username := vars["username"]
	services := make([]string, 0)

	proxyMachine, _ := proxyConfig.GetProxy(uuid)
	_, ok := proxyMachine.Rules[username]
	if !ok {
		resp := fmt.Sprintf("getting services of user rules is not possible. no user %s exists", username)
		io.WriteString(writer, resp)
		return
	}

	rules := proxyMachine.Rules[username]
	for name, _ := range rules.Services {
		services = append(services, name)
	}

	data, err := json.MarshalIndent(services, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}
	writer.Write([]byte(data))
}

func GetUserServiceRules(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	username := vars["username"]
	servicename := vars["servicename"]

	proxyMachine, _ := proxyConfig.GetProxy(uuid)
	_, ok := proxyMachine.Rules[username]
	if !ok {
		resp := fmt.Sprintf("getting services of user rules is not possible. no user %s exists", username)
		io.WriteString(writer, resp)
		return
	}

	rules := proxyMachine.Rules[username]
	restriction := rules.Services[servicename]

	data, err := json.MarshalIndent(restriction, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}
	writer.Write([]byte(data))
}

func CreateUserServiceRules(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]
	username := vars["username"]

	var msg RulesPostMessage
	var ipregex string

	body, _ := ioutil.ReadAll(req.Body)
	log.Println(string(body))

	err := json.Unmarshal(body, &msg)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.IpRegex != nil {
		ipregex = *msg.IpRegex
	} else {
		err := "no 'ipregex' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "addRule"
	cmd.Uuid = uuid
	cmd.Username = username
	cmd.ServiceName = servicename
	cmd.IpRegex = ipregex

	buildSendProxyCmd(cmd)

	url := fmt.Sprintf("rule '%s' is added for the user %s and service %s", ipregex, username, servicename)
	io.WriteString(writer, url)
	return

}

func CreateClient(writer http.ResponseWriter, req *http.Request) {
	log.Println("POST /deployments")
	var msg DeployPostMessage
	var build string
	var git string
	var config string

	body, _ := ioutil.ReadAll(req.Body)

	err := json.Unmarshal(body, &msg)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Build != nil {
		build = *msg.Build
	} else {
		err := "aborting. no 'build' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Git != nil {
		git = *msg.Git
	} else {
		err := "aborting. no 'git' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Config != nil {
		config = *msg.Config
	} else {
		err := "aborting. no 'config' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	client := clientconfig.ServerInfo{
		BuildNumber: build,
		GitBranch:   git,
		ConfigUsed:  config,
		Config:      nil,
		Hostname:    clientconfig.Hostname{},
		IP:          clientconfig.IP{},
	}

	clientDB.AddClient(client)

	var url string
	url = fmt.Sprintf("deploy info posted build: %s, git branch: %s and config used: %s", build, git, config)
	io.WriteString(writer, url)
	return

}

// Get all registered proxies
// example: http GET "localhost:8000/proxies"
func GetClients(writer http.ResponseWriter, req *http.Request) {
	clients := make([]clientconfig.ServerInfo, 0)
	client := clientconfig.ServerInfo{}
	log.Println("GET /deployments")

	iter := clientDB.Collection.Find(nil).Iter()
	for iter.Next(&client) {
		clients = append(clients, client)
	}

	data, err := json.MarshalIndent(clients, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func GetClient(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	build := vars["build"]
	log.Printf("GET /deployments/%s\n", build)

	client := clientconfig.ServerInfo{}
	clients := make([]clientconfig.ServerInfo, 0)

	if build == "latest" {
		iter := clientDB.Collection.Find(nil).Iter()
		for iter.Next(&client) {
			clients = append(clients, client)
		}

		if len(clients) == 0 {
			io.WriteString(writer, "[]") // return empty slice
			return
		}

		builds := make([]int, len(clients))

		for i, val := range clients {
			builds[i], _ = strconv.Atoi(val.BuildNumber)
		}

		sort.Ints(builds)
		latestBuild := builds[len(builds)-1] // get largest build number
		for _, val := range clients {
			build, _ := strconv.Atoi(val.BuildNumber)

			if latestBuild == build {
				data, err := json.MarshalIndent(val, "", "  ")
				if err != nil {
					io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
					return
				}
				writer.Write([]byte(data))
				return
			}
		}
	}

	query := bson.M{"buildnumber": build}
	iter := clientDB.Collection.Find(query).Iter()
	for iter.Next(&client) {
		data, err := json.MarshalIndent(client, "", "  ")
		if err != nil {
			io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
			return
		}

		writer.Write([]byte(data))
		return
	}

}

// Get all registered proxies
// example: http GET "localhost:8000/proxies"
func GetProxies(writer http.ResponseWriter, req *http.Request) {
	proxies := make([]string, 0)
	proxy := proxyconfig.Proxy{}
	iter := proxyConfig.Collection.Find(nil).Iter()
	for iter.Next(&proxy) {
		proxies = append(proxies, proxy.Uuid)

	}

	data, err := json.MarshalIndent(proxies, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

// Delete proxy machine with uuid
// example http DELETE "localhost:8080/proxies/mahlika.local-915"
func DeleteProxy(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "deleteProxy"
	cmd.Uuid = uuid

	buildSendProxyCmd(cmd)
	resp := fmt.Sprintf("'%s' is deleted", uuid)
	io.WriteString(writer, resp)
}

// Register a user proxy
// Example: http POST "localhost:8000/proxies/{uuid}/{username}"
func CreateProxy(writer http.ResponseWriter, req *http.Request) {
	var msg ProxyPostMessage
	var uuid string

	body, _ := ioutil.ReadAll(req.Body)
	log.Println(string(body))

	err := json.Unmarshal(body, &msg)
	if err != nil {
		log.Print("bad json incoming msg: ", err)
	}

	if msg.Uuid != nil {
		if *msg.Uuid == "default" {
			err := "reserved keyword, please choose another uuid name"
			io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
			return
		}
		uuid = *msg.Uuid
	} else {
		err := "aborting. no 'uuid' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "addProxy"
	cmd.Uuid = uuid

	buildSendProxyCmd(cmd)

	resp := fmt.Sprintf("'%s' is registered", uuid)
	io.WriteString(writer, resp)
}

// Register a proxy
// example: http POST "localhost:8000/proxies/mahlika.local-915/services/{username}"
func CreateProxyUser(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	username := vars["username"]

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "addUser"
	cmd.Uuid = uuid
	cmd.Username = username

	buildSendProxyCmd(cmd)
	resp := fmt.Sprintf("user '%s' is added to proxy uuid: '%s'", username, uuid)
	io.WriteString(writer, resp)
}

// Delete service for the given name
// exameple: http DELETE /proxies/mahlika.local-915/services/arslan/{serviceName}
func DeleteProxyService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]
	username := vars["username"]

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "deleteServiceName"
	cmd.Uuid = uuid
	cmd.ServiceName = servicename
	cmd.Username = username

	buildSendProxyCmd(cmd)
	resp := fmt.Sprintf("service: '%s' is deleted on proxy uuid: '%s'", servicename, uuid)
	io.WriteString(writer, resp)
}

// Delete key for the given name and key
// exameple: http DELETE /proxies/mahlika.local-915/services/{username}/{serviceName}/{keyname}
func DeleteProxyServiceKey(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	key := vars["key"]
	servicename := vars["servicename"]
	username := vars["username"]

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "deleteKey"
	cmd.Uuid = uuid
	cmd.Key = key
	cmd.ServiceName = servicename
	cmd.Username = username

	buildSendProxyCmd(cmd)
	resp := fmt.Sprintf("key: '%s' is deleted for service: '%s'", key, servicename)
	io.WriteString(writer, resp)
}

// Delete domain for the given name and key
// exameple: http DELETE /proxies/mahlika.local-915/domains/blog.arsln.org
func DeleteProxyDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	domain := vars["domain"]

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "deleteDomain"
	cmd.Uuid = uuid
	cmd.DomainName = domain

	buildSendProxyCmd(cmd)
	resp := fmt.Sprintf("domain: '%s' is deleted on proxy uuid: '%s'", domain, uuid)
	io.WriteString(writer, resp)
}

// Get all domains registered to a proxy machine
// example: http GET "localhost:8000/proxies/mahlika.local-915/domains"
func GetProxyDomains(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	proxyMachine, _ := proxyConfig.GetProxy(uuid)

	domains := proxyMachine.DomainRoutingTable

	data, err := json.MarshalIndent(domains, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

// Add domain to the domain routingtable
// example: http POST "localhost:8000/proxies/mahlika.local-915/domains/blog.arsln.org" name=server key=15 username=arslan
func CreateProxyDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	domain := vars["domain"]

	var msg ProxyPostMessage
	var name string
	var username string
	var key string
	var host string

	body, _ := ioutil.ReadAll(req.Body)
	log.Println(string(body))

	err := json.Unmarshal(body, &msg)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Name != nil {
		name = *msg.Name
	} else {
		err := "no 'name' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Username != nil {
		username = *msg.Username
	} else {
		err := "no 'username' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Key != nil {
		key = *msg.Key
	} else {
		err := "no 'key' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	// this is optional feature
	if msg.Host != nil {
		host = *msg.Host
	}

	// for default proxy assume that the main proxy will handle this. until
	// we come up with design decision for multiple proxies, use this
	if uuid == "default" {
		uuid = "proxy.in.koding.com"
	}

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "addDomain"
	cmd.Username = username
	cmd.Uuid = uuid
	cmd.Key = key
	cmd.ServiceName = name
	cmd.DomainName = domain
	cmd.Host = host
	cmd.HostData = "FromKontrolAPI"

	buildSendProxyCmd(cmd)

	var resp string
	if host != "" {
		resp = fmt.Sprintf("'%s' will proxy to '%s'", domain, host)
	} else {
		resp = fmt.Sprintf("'%s' will proxy to '%s-%s.x.koding.com'", domain, name, key)
	}

	io.WriteString(writer, resp)
	return
}

// Add key with proxy host to proxy machine with uuid
// * If servicename is not available an new one is created
// * If key is available tries to append it, if not creates a new key with host.
// * If key and host is available it does nothing
// example: http POST "localhost:8000/proxies/mahlika.local-915/services/arslan/server" key=2 host=localhost:8009 rabbitkey=1234567890
func CreateProxyService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]
	username := vars["username"]

	var msg ProxyPostMessage
	var key string
	var host string
	var hostdata string
	var rabbitkey string

	body, _ := ioutil.ReadAll(req.Body)
	log.Println(string(body))

	err := json.Unmarshal(body, &msg)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Key != nil {
		key = *msg.Key
	} else {
		err := "no 'key' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Host != nil {
		host = *msg.Host
	} else {
		err := "no 'host' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	// this is optional
	if msg.Hostdata != nil {
		hostdata = *msg.Hostdata
	}

	if msg.RabbitKey != nil {
		rabbitkey = *msg.RabbitKey
	}

	if hostdata == "" {
		hostdata = "FromKontrolAPI"
	}

	// for default proxy assume that the main proxy will handle this. until
	// we come up with design decision for multiple proxies, use this
	if uuid == "default" {
		uuid = "proxy.in.koding.com"
	}

	var cmd proxyconfig.ProxyMessage
	cmd.Action = "addKey"
	cmd.Uuid = uuid
	cmd.Key = key
	cmd.RabbitKey = rabbitkey
	cmd.ServiceName = servicename
	cmd.Username = username
	cmd.Host = host
	cmd.HostData = hostdata

	buildSendProxyCmd(cmd)

	var url string
	if username == "koding" {
		url = fmt.Sprintf("http://%s-%s.x.koding.com", servicename, key)
	} else {
		url = fmt.Sprintf("http://%s-%s-%s.kd.io", servicename, key, username)
	}
	io.WriteString(writer, url)
	return
}

func GetProxyUsers(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	users := make([]string, 0)
	proxyMachine, _ := proxyConfig.GetProxy(uuid)

	for username := range proxyMachine.RoutingTable {
		users = append(users, username)
	}

	data, err := json.MarshalIndent(users, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

// Get all services registered to a proxy machine
// example: http GET "localhost:8000/proxies/mahlika.local-915/services/{username}"
func GetProxyServices(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	username := vars["username"]

	services := make([]string, 0)
	proxyMachine, _ := proxyConfig.GetProxy(uuid)

	_, ok := proxyMachine.RoutingTable[username]
	if !ok {
		resp := fmt.Sprintf("getting proxy services is not possible. no user %s exists", username)
		io.WriteString(writer, resp)
		return
	}
	user := proxyMachine.RoutingTable[username]

	for name, _ := range user.Services {
		services = append(services, name)
	}

	data, err := json.MarshalIndent(services, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

// Get all keys and hosts for a given proxy service registerd to a proxy uuid
// example: http GET "localhost:8000/proxies/mahlika.local-915/services/arslan/foo"
//
// accepts query filtering for key, host and hostdata
// example: http GET "localhost:8000/proxies/mahlika.local-915/services/arslan/foo?key=2"
// example: http GET "localhost:8000/proxies/mahlika.local-915/services/arslan/foo?host=localhost:8002"
// example: http GET "localhost:8000/proxies/mahlika.local-915/services/arslan/foo?hostdata=FromKontrolAPI"
func GetProxyService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]
	username := vars["username"]

	v := req.URL.Query()
	key := v.Get("key")
	host := v.Get("host")
	hostdata := v.Get("hostdata")

	p := make(Proxies, 0)
	proxyMachine, _ := proxyConfig.GetProxy(uuid)

	_, ok := proxyMachine.RoutingTable[username]
	if !ok {
		resp := fmt.Sprintf("getting proxy service is not possible. no user %s exists", username)
		io.WriteString(writer, resp)
		return
	}
	user := proxyMachine.RoutingTable[username]

	keyRoutingTable := user.Services[servicename]

	for _, keys := range keyRoutingTable.Keys {
		for _, proxy := range keys {
			p = append(p, Proxy{proxy.Key, proxy.Host, proxy.HostData, proxy.RabbitKey})
		}
	}

	s := make([]interface{}, len(p))
	for i, v := range p {
		s[i] = v
	}

	t := NewMatcher(s).
		ByString("Key", key).
		ByString("Host", host).
		ByString("Hostdata", hostdata).
		Run()

	matchedProxies := make(Proxies, len(t))
	for i, item := range t {
		w, _ := item.(Proxy)
		matchedProxies[i] = w
	}

	var res []Proxy
	if len(v) == 0 { // no query available, means return all proxies
		res = p
	} else {
		res = matchedProxies
	}

	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

// Get all registered workers
// http://localhost:8000/workers
// http://localhost:8000/workers?hostname=foo&state=started
// http://localhost:8000/workers?name=social
// http://localhost:8000/workers?state=stopped
func GetWorkers(writer http.ResponseWriter, req *http.Request) {
	log.Println("GET /workers")
	queries, _ := url.ParseQuery(req.URL.RawQuery)

	var latestVersion bool
	query := bson.M{}
	for key, value := range queries {
		switch key {
		case "version", "pid":
			if value[0] == "latest" {
				latestVersion = true
				break
			}
			v, _ := strconv.Atoi(value[0])
			query[key] = v
		case "state":
			for status, state := range StatusCode {
				if value[0] == state {
					query["status"] = status
				}
			}
		default:
			if key == "name" {
				name := value[0]
				if counts := strings.Count(value[0], "-"); counts > 0 {
					s := strings.Split(value[0], "-")
					name = s[0]
				}
				query[key] = bson.RegEx{Pattern: "^" + name, Options: "i"}
			} else {
				query[key] = value[0]
			}
		}
	}

	matchedWorkers := queryResult(query, latestVersion)
	data, err := createJson(matchedWorkers)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}
	writer.Write(data)

}

// Get worker with uuid
// Example :http://localhost:8000/workers/134f945b3327b775a5f424be804d75e3
func GetWorker(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	log.Printf("GET /workers/%s\n", uuid)

	query := bson.M{"uuid": uuid}
	matchedWorkers := queryResult(query, false)
	data, err := createJson(matchedWorkers)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}
	writer.Write(data)
}

// Delete worker with uuid
// Example: http DELETE "localhost:8000/workers/l8zqdZ1Dz3D14FscAmRxrw=="
func DeleteWorker(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	log.Printf("DELETE /workers/%s\n", uuid)

	buildSendCmd("delete", "", uuid)
	resp := fmt.Sprintf("worker: '%s' is deleted from db", uuid)
	io.WriteString(writer, resp)
}

// Change workers states. Action may be:
// * kill (to kill the process of the worker)
// * stop (to stop the running process of the worker)
// * start (to start the stopped process of the worker)
//
// example: http PUT "localhost:8000/workers/e59c64aaa8192523ced12ffa0cddcd3c/stop"
func UpdateWorker(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid, action := vars["uuid"], vars["action"]
	log.Printf("%s /workers/%s\n", strings.ToUpper(action), uuid)

	buildSendCmd(action, "", uuid)
	resp := fmt.Sprintf("worker: '%s' is updated in db", uuid)
	io.WriteString(writer, resp)
}

// Fallback function will be removed later
func home(writer http.ResponseWriter, request *http.Request) {

	io.WriteString(writer, "Hello world - kontrol api!\n")
}

func queryResult(query bson.M, latestVersion bool) Workers {
	workers := make(Workers, 0)
	worker := workerconfig.MsgWorker{}

	iter := kontrolConfig.Collection.Find(query).Iter()
	for iter.Next(&worker) {
		apiWorker := &Worker{
			worker.Name,
			worker.Uuid,
			worker.Hostname,
			worker.Version,
			worker.Timestamp,
			worker.Pid,
			StatusCode[worker.Status],
			worker.Monitor.Uptime,
			worker.Port,
		}

		workers = append(workers, *apiWorker)
	}

	// finding the largest number of a field in mongo is kinda problematic.
	// therefore we are doing it on our side
	if latestVersion {
		versions := make([]int, len(workers))

		if len(workers) == 0 {
			return workers
		}

		for i, val := range workers {
			versions[i] = val.Version
		}

		sort.Ints(versions)
		maxVersion := versions[len(versions)-1] // get largest version number

		filteredWorkers := make(Workers, 0)
		for _, val := range workers {
			if maxVersion == val.Version {
				filteredWorkers = append(filteredWorkers, val)
			}
		}

		return filteredWorkers
	}

	return workers
}

func createJson(w Workers) ([]byte, error) {
	data, err := json.MarshalIndent(w, "", "  ")
	if err != nil {
		return nil, err
	}

	return data, nil
}

// Creates and send request message for workers. Sends to kontrold.
func buildSendCmd(action, host, uuid string) {
	cmd := workerconfig.Request{Command: action, Hostname: host, Uuid: uuid}
	log.Println("Sending cmd to kontrold:", cmd)

	// Wrap message for dynamic unmarshaling at endpoint
	type Wrap struct{ Worker workerconfig.Request }

	data, err := json.Marshal(&Wrap{cmd})
	if err != nil {
		log.Println("Json marshall error", data)
	}

	listenTell.Tell(data)
}

// Creates and send request message for proxies. Sends to kontrold.
func buildSendProxyCmd(cmd proxyconfig.ProxyMessage) {
	log.Println("Sending cmd to kontrold:", cmd)

	// Wrap message for dynamic unmarshaling at endpoint
	type Wrap struct{ Proxy proxyconfig.ProxyMessage }

	data, err := json.Marshal(&Wrap{cmd})
	if err != nil {
		log.Println("Json marshall error", data)
	}

	listenTell.Tell(data)
}
