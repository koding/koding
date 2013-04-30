package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"koding/kontrol/daemon/workerconfig"
	"koding/kontrol/proxy/proxyconfig"
	"koding/tools/config"
	"labix.org/v2/mgo/bson"
	"log"
	"net/http"
	"net/url"
	"strconv"
	"time"
)

// Gateway to messages from/to kontrold via amqp.
var listenTell *ListenTell

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

type ProxyPostMessage struct {
	Name      *string
	Domain    *string
	Key       *string
	RabbitKey *string
	Host      *string
	Hostdata  *string
	Uuid      *string
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

	port := strconv.Itoa(config.Current.Kontrold.Api.Port)

	rout := mux.NewRouter()
	rout.HandleFunc("/", home).Methods("GET")

	// Worker handlers
	rout.HandleFunc("/workers", GetWorkers).Methods("GET")
	rout.HandleFunc("/workers/{uuid}", GetWorker).Methods("GET")
	rout.HandleFunc("/workers/{uuid}/{action}", UpdateWorker).Methods("PUT")
	rout.HandleFunc("/workers/{uuid}", DeleteWorker).Methods("DELETE")

	// Proxy handlers
	rout.HandleFunc("/proxies", GetProxies).Methods("GET")
	rout.HandleFunc("/proxies", CreateProxy).Methods("POST")
	rout.HandleFunc("/proxies/{uuid}", DeleteProxy).Methods("DELETE")
	rout.HandleFunc("/proxies/{uuid}/services", GetProxyServices).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/services/{servicename}", GetProxyService).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/services/{servicename}", CreateProxyService).Methods("POST")
	rout.HandleFunc("/proxies/{uuid}/services/{servicename}", DeleteProxyService).Methods("DELETE")
	rout.HandleFunc("/proxies/{uuid}/services/{servicename}/{key}", DeleteProxyServiceKey).Methods("DELETE")
	rout.HandleFunc("/proxies/{uuid}/domains", GetProxyDomains).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}/domains/{domain}", CreateProxyDomain).Methods("POST")
	rout.HandleFunc("/proxies/{uuid}/domains/{domain}", DeleteProxyDomain).Methods("DELETE")

	// Rollbar api
	rout.HandleFunc("/rollbar", rollbar).Methods("POST")

	log.Printf("kontrol api is started. serving at :%s ...", port)

	http.Handle("/", rout)
	err = http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Println(err)
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

	buildSendProxyCmd("deleteProxy", "", "", "", "", "", "", uuid)
	resp := fmt.Sprintf("'%s' is deleted", uuid)
	io.WriteString(writer, resp)
}

// Register a proxy
// Example: http POST "localhost:8000/proxies" uuid=mahlika.local-916
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

	buildSendProxyCmd("addProxy", "", "", "", "", "", "", uuid)

	resp := fmt.Sprintf("'%s' is registered", uuid)
	io.WriteString(writer, resp)
}

// Delete service for the given name
// exameple: http DELETE /proxies/mahlika.local-915/{serviceName}
func DeleteProxyService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]

	buildSendProxyCmd("deleteName", "", servicename, "", "", "", "", uuid)
	resp := fmt.Sprintf("service: '%s' is deleted on proxy uuid: '%s'", servicename, uuid)
	io.WriteString(writer, resp)
}

// Delete key for the given name and key
// exameple: http DELETE /proxies/mahlika.local-915/{serviceName}/{keyname}
func DeleteProxyServiceKey(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	key := vars["key"]
	servicename := vars["servicename"]

	buildSendProxyCmd("deleteKey", "", servicename, key, "", "", "", uuid)
	resp := fmt.Sprintf("key: '%s' is deleted for service: '%s'", key, servicename)
	io.WriteString(writer, resp)
}

// Delete key for the given name and key
// exameple: http DELETE /proxies/mahlika.local-915/domains/blog.arsln.org
func DeleteProxyDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	domain := vars["domain"]

	buildSendProxyCmd("deleteDomain", domain, "", "", "", "", "", uuid)
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
// example: http POST "localhost:8000/proxies/mahlika.local-915/domains/blog.arsln.org" name=server key=15
func CreateProxyDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	domain := vars["domain"]

	var msg ProxyPostMessage
	var name string
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

	buildSendProxyCmd("addDomain", domain, name, key, "", host, "FromKontrolAPI", uuid)

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
// * If name is not available an new one is created
// * If key is available tries to append it, if not creates a new key with host.
// * If key and host is available it does nothing
// example: http POST "localhost:8000/proxies/mahlika.local-915/services/server" key=2 host=localhost:8009 rabbitkey=1234567890
func CreateProxyService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]

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

	if msg.Key != nil {
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

	buildSendProxyCmd("addKey", "", servicename, key, rabbitkey, host, hostdata, uuid)

	url := fmt.Sprintf("http://%s-%s.x.koding.com", servicename, key)
	io.WriteString(writer, url)
	return
}

// Get all services registered to a proxy machine
// example: http GET "localhost:8000/proxies/mahlika.local-915/services"
func GetProxyServices(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	services := make([]string, 0)
	proxyMachine, _ := proxyConfig.GetProxy(uuid)

	for name, _ := range proxyMachine.Services {
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
// example: http GET "localhost:8000/proxies/mahlika.local-915/foo"
//
// accepts query filtering for key, host and hostdata
// example: http GET "localhost:8000/proxies/mahlika.local-915/foo?key=2"
// example: http GET "localhost:8000/proxies/mahlika.local-915/foo?host=localhost:8002"
// example: http GET "localhost:8000/proxies/mahlika.local-915/foo?hostdata=FromKontrolAPI"
func GetProxyService(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	servicename := vars["servicename"]

	v := req.URL.Query()
	key := v.Get("key")
	host := v.Get("host")
	hostdata := v.Get("hostdata")

	p := make(Proxies, 0)
	proxyMachine, _ := proxyConfig.GetProxy(uuid)
	keyRoutingTable := proxyMachine.Services[servicename]

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
	queries, _ := url.ParseQuery(req.URL.RawQuery)

	query := bson.M{}
	for key, value := range queries {
		switch key {
		case "version", "pid":
			v, _ := strconv.Atoi(value[0])
			query[key] = v
		case "state":
			for status, state := range StatusCode {
				if value[0] == state {
					query["status"] = status
				}
			}
		default:
			query[key] = value[0]
		}
	}

	matchedWorkers := queryResult(query)
	data := buildWriteData(matchedWorkers)
	writer.Write(data)

}

// Get worker with uuid
// Example :http://localhost:8000/workers/134f945b3327b775a5f424be804d75e3
func GetWorker(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	query := bson.M{"uuid": uuid}
	matchedWorkers := queryResult(query)
	data := buildWriteData(matchedWorkers)
	writer.Write(data)
}

// Delete worker with uuid
// Example: http DELETE "localhost:8000/workers/l8zqdZ1Dz3D14FscAmRxrw=="
func DeleteWorker(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

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

	buildSendCmd(action, "", uuid)
	resp := fmt.Sprintf("worker: '%s' is updated in db", uuid)
	io.WriteString(writer, resp)
}

// Fallback function will be removed later
func home(writer http.ResponseWriter, request *http.Request) {

	io.WriteString(writer, "Hello world - kontrol api!\n")
}

func queryResult(query bson.M) Workers {
	err := kontrolConfig.RefreshStatusAll()
	if err != nil {
		log.Println(err)
	}

	log.Println(query)

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

	return workers
}

func buildWriteData(w Workers) []byte {
	data, err := json.MarshalIndent(w, "", "  ")
	if err != nil {
		log.Println("Marshall allWorkers into Json failed", err)
	}

	return data
}

// Creates and send request message for workers. Sends to kontrold.
func buildSendCmd(action, host, uuid string) {
	cmd := workerconfig.Request{action, host, uuid}
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
func buildSendProxyCmd(action, domainname, servicename, key, rabbitkey, host, hostdata, uuid string) {
	var cmd proxyconfig.ProxyMessage
	cmd.Action = action
	cmd.Uuid = uuid
	cmd.Key = key
	cmd.RabbitKey = rabbitkey
	cmd.ServiceName = servicename
	cmd.DomainName = domainname
	cmd.Host = host
	cmd.HostData = hostdata

	log.Println("Sending cmd to kontrold:", cmd)

	// Wrap message for dynamic unmarshaling at endpoint
	type Wrap struct{ Proxy proxyconfig.ProxyMessage }

	data, err := json.Marshal(&Wrap{cmd})
	if err != nil {
		log.Println("Json marshall error", data)
	}

	listenTell.Tell(data)
}
