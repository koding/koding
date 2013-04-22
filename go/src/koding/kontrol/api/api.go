package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"io/ioutil"
	"koding/fujin/proxyconfig"
	"koding/kontrol/daemon/workerconfig"
	"labix.org/v2/mgo/bson"
	"log"
	"net/http"
	"net/url"
	"strconv"
	"time"
)

type ListenTell struct {
	listen chan string
	tell   chan []byte
}

var listenTell *ListenTell

func (listenTell *ListenTell) Listen() string {
	return <-listenTell.listen
}

func (listenTell *ListenTell) Tell(data []byte) {
	listenTell.tell <- data
}

type Worker struct {
	Name      string    `json:"name"`
	Uuid      string    `json:"uuid"`
	Hostname  string    `json:"hostname"`
	Version   int       `json:"version"`
	Timestamp time.Time `json:"timestamp"`
	Pid       int       `json:"pid"`
	State     string    `json:"state"`
}

type Workers []Worker

type Proxy struct {
	Key      string
	Host     string
	Hostdata string
}
type Proxies []Proxy

type ProxyMachine struct {
	Uuid string
	Keys []string
}
type ProxyMachines []ProxyMachine

type ProxyPostMessage struct {
	Key      *string
	Host     *string
	Hostdata *string
	Uuid     *string
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

	rout := mux.NewRouter()
	rout.HandleFunc("/", home).Methods("GET")

	rout.HandleFunc("/workers", WorkersHandler).Methods("GET")
	rout.HandleFunc("/workers/{uuid}", WorkerHandler).Methods("GET")
	rout.HandleFunc("/workers/{uuid}/{action}", WorkerPutHandler).Methods("PUT")
	rout.HandleFunc("/workers/{uuid}", WorkerDeleteHandler).Methods("DELETE")

	rout.HandleFunc("/proxies", ProxiesHandler).Methods("GET")
	rout.HandleFunc("/proxies", ProxiesPostHandler).Methods("POST")
	// rout.HandleFunc("/proxies/{uuid}", ProxiesDeleteHandler).Methods("DELETE") // TODO
	rout.HandleFunc("/proxies/{uuid}", ProxyHandler).Methods("GET")
	rout.HandleFunc("/proxies/{uuid}", ProxyPostHandler).Methods("POST")
	rout.HandleFunc("/proxies/{uuid}", ProxyDeleteHandler).Methods("DELETE")

	rout.HandleFunc("/rollbar", rollbar).Methods("POST")

	log.Println("kontrol-api started")
	http.Handle("/", rout)
	http.ListenAndServe(":8000", nil)
}

// Get all registered proxies
// example: http GET "localhost:8000/proxies"
func ProxiesHandler(writer http.ResponseWriter, req *http.Request) {
	p := make(ProxyMachines, 0)
	proxy := proxyconfig.Proxy{}

	iter := proxyConfig.Collection.Find(nil).Iter()
	for iter.Next(&proxy) {
		keysList := make([]string, 0)
		for key, _ := range proxy.KeyRoutingTable.Keys {
			keysList = append(keysList, key)
		}

		machine := &ProxyMachine{proxy.Uuid, keysList}
		p = append(p, ProxyMachine(*machine))

	}

	data, err := json.MarshalIndent(p, "", "  ")
	if err != nil {
		log.Println("Marshall allWorkers into Json failed", err)
	}

	writer.Write([]byte(data))
}

// Delete proxy machine with uuid
// example http DELETE "localhost:8080/proxies/mahlika.local-915"
func ProxyDeleteHandler(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	buildSendProxyCmd("deleteProxy", "", "", "", uuid)
}

// Register a proxy
// Example: http POST "localhost:8000/proxies" uuid=mahlika.local-916
func ProxiesPostHandler(writer http.ResponseWriter, req *http.Request) {
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
			log.Println("reserved keyword, please choose another uuid name")
			return
		}
		uuid = *msg.Uuid
	} else {
		log.Println("aborting. no 'uuid' available")
		return
	}

	buildSendProxyCmd("addProxy", "", "", "", uuid)
}

// Add key with proxy host to proxy machine with uuid
// * If key is available tries to append it, if not creates a new key with host.
// * If key and host is available it does nothing
// example: http POST "localhost:8000/proxies/mahlika.local-915" key=2 host=localhost:8009
func ProxyPostHandler(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	var msg ProxyPostMessage
	var key string
	var host string
	var hostdata string

	body, _ := ioutil.ReadAll(req.Body)
	log.Println(string(body))

	err := json.Unmarshal(body, &msg)
	if err != nil {
		log.Print("bad json incoming msg: ", err)
	}

	if msg.Key != nil {
		key = *msg.Key
	} else {
		log.Println("aborting. no 'key' available")
		return
	}

	if msg.Host != nil {
		host = *msg.Host
	} else {
		log.Println("aborting. no 'host' available")
		return
	}

	// this is optional
	if msg.Hostdata != nil {
		log.Println(*msg.Hostdata)
		hostdata = *msg.Hostdata
	}

	if hostdata == "" {
		hostdata = "FromKontrolAPI"
	}

	// for default proxy assume that the main proxy will handle this. until
	// we come up with design decision for multiple proxies, use this
	if uuid == "default" {
		uuid = "proxy.in.koding.com"
	}

	buildSendProxyCmd("addKey", key, host, hostdata, uuid)
}

// Get all keys and hosts for proxy machine uuid
// example: http GET "localhost:8000/proxies/mahlika.local-915"
//
// accepts query filtering for key, host and hostdata
// example: http GET "localhost:8000/proxies/mahlika.local-915?key=2"
// example: http GET "localhost:8000/proxies/mahlika.local-915?host=localhost:8002"
// example: http GET "localhost:8000/proxies/mahlika.local-915?hostdata=FromKontrolAPI"
func ProxyHandler(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	v := req.URL.Query()
	key := v.Get("key")
	host := v.Get("host")
	hostdata := v.Get("hostdata")

	p := make(Proxies, 0)
	proxyMachine, _ := proxyConfig.GetProxy(uuid)
	for _, keys := range proxyMachine.KeyRoutingTable.Keys {
		for _, proxy := range keys {
			p = append(p, Proxy{proxy.Key, proxy.Host, proxy.HostData})
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
		log.Println("Marshall allWorkers into Json failed", err)
	}

	writer.Write([]byte(data))
}

// Get all registered workers
// http://localhost:8000/workers
// http://localhost:8000/workers?hostname=foo&state=started
// http://localhost:8000/workers?name=social
// http://localhost:8000/workers?state=stopped
func WorkersHandler(writer http.ResponseWriter, req *http.Request) {
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
func WorkerHandler(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	query := bson.M{"uuid": uuid}
	matchedWorkers := queryResult(query)
	data := buildWriteData(matchedWorkers)
	writer.Write(data)
}

// Delete worker with uuid
// Example: http DELETE "localhost:8000/workers/l8zqdZ1Dz3D14FscAmRxrw=="
func WorkerDeleteHandler(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	buildSendCmd("delete", "", uuid)
}

// Change workers states. Action may be:
// * kill (to kill the process of the worker)
// * stop (to stop the running process of the worker)
// * start (to start the stopped process of the worker)
//
// example: http PUT "localhost:8000/workers/e59c64aaa8192523ced12ffa0cddcd3c/stop"
func WorkerPutHandler(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid, action := vars["uuid"], vars["action"]

	buildSendCmd(action, "", uuid)
}

// Fallback function will be removed later
func home(writer http.ResponseWriter, request *http.Request) {
	query := bson.M{}
	allWorkers := queryResult(query)
	log.Println(allWorkers)

	data := buildWriteData(allWorkers)
	writer.Write(data)
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
func buildSendProxyCmd(action, key, host, hostdata, uuid string) {
	cmd := proxyconfig.ProxyMessage{action, key, host, hostdata, uuid}
	log.Println("Sending cmd to kontrold:", cmd)

	// Wrap message for dynamic unmarshaling at endpoint
	type Wrap struct{ Proxy proxyconfig.ProxyMessage }

	data, err := json.Marshal(&Wrap{cmd})
	if err != nil {
		log.Println("Json marshall error", data)
	}

	listenTell.Tell(data)
}
