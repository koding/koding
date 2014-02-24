package main

import (
	"encoding/json"
	"fmt"
	"io"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/tools/config"
	"math"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"github.com/gorilla/mux"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type ApiWorker struct {
	Name               string    `json:"name"`
	Version            int       `json:"version"`
	Environment        string    `json:"environment"`
	Hostname           string    `json:"hostname"`
	ServiceGenericName string    `json:"serviceGenericName"`
	ServiceUniqueName  string    `json:"serviceUniqueName"`
	Uuid               string    `json:"uuid"`
	Timestamp          time.Time `json:"timestamp"`
	Pid                int       `json:"pid"`
	State              string    `json:"state"`
	Uptime             int       `json:"uptime"`
	Port               int       `json:"port"`
}

type Workers []ApiWorker

var StatusCode = map[models.WorkerStatus]string{
	models.Started: "started",
	models.Waiting: "waiting",
	models.Killed:  "dead",
	models.Dead:    "dead",
}

const (
	WorkersCollection = "jKontrolWorkers"
	WorkersDB         = "kontrol"
)

var (
	kontrolDB *mongodb.MongoDB

	// used for loadbalance modes, like roundrobin or random
	index AtomicUint32
)

func GetWorkerURL(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	workerName := vars["workername"]

	queries, _ := url.ParseQuery(req.URL.RawQuery)
	worker := models.Worker{}
	workers := make(Workers, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(bson.M{"name": workerName}).Iter()
		for iter.Next(&worker) {
			apiWorker := &ApiWorker{
				Name:               worker.Name,
				Version:            worker.Version,
				Environment:        worker.Environment,
				Hostname:           worker.Hostname,
				ServiceGenericName: worker.ServiceGenericName,
				ServiceUniqueName:  worker.ServiceUniqueName,
				Uuid:               worker.Uuid,
				Timestamp:          worker.Timestamp,
				Pid:                worker.Pid,
				State:              StatusCode[worker.Status],
				Uptime:             worker.Monitor.Uptime,
				Port:               worker.Port,
			}

			workers = append(workers, *apiWorker)
		}

		return nil
	}

	kontrolDB.RunOnDatabase(WorkersDB, WorkersCollection, query)

	// use http for all workers because they don't have ssl certs
	protocolScheme := "http:"

	brokerConf := config.Broker{}
	switch workerName {
	case "brokerKite":
		brokerConf = conf.BrokerKite
	case "broker":
		brokerConf = conf.Broker
	default:
	}

	// broker has ssl cert and a custom url scheme, look what it's it
	if workerName == "broker" || workerName == "brokerKite" {
		if brokerConf.WebProtocol != "" {
			protocolScheme = brokerConf.WebProtocol
		} else {
			protocolScheme = "https:" // fallback
		}
	}

	hostnames := make([]string, len(workers))
	for i, worker := range workers {
		hostnames[i] = fmt.Sprintf("%s//%s:%d", protocolScheme, worker.Hostname, worker.Port)
	}

	var data []byte
	var err error

	_, ok := queries["all"]
	if ok {
		// return all hostnames back
		data, err = json.MarshalIndent(hostnames, "", "  ")
		if err != nil {
			io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
			return
		}
	} else {
		// quit early when there is no workers available
		if len(workers) == 0 {
			writer.Write([]byte(string("")))
			return
		}

		// return only one hostname back, roundrobin
		oldIndex := index.Get() // gives 0 for first time

		N := float64(len(hostnames))
		newIndex := int(math.Mod(float64(oldIndex+1), N))
		hostname := hostnames[newIndex]

		index.CompareAndSwap(oldIndex, uint32(newIndex))

		data = []byte(fmt.Sprintf("\"%s\"", hostname))
	}

	writer.Write(data)
}

type AtomicUint32 uint32

func (i *AtomicUint32) Add(n uint32) uint32 {
	return atomic.AddUint32((*uint32)(i), n)
}

func (i *AtomicUint32) Set(n uint32) {
	atomic.StoreUint32((*uint32)(i), n)
}

func (i *AtomicUint32) Get() uint32 {
	return atomic.LoadUint32((*uint32)(i))
}

func (i *AtomicUint32) CompareAndSwap(oldval, newval uint32) (swapped bool) {
	return atomic.CompareAndSwapUint32((*uint32)(i), oldval, newval)
}

func GetWorkers(writer http.ResponseWriter, req *http.Request) {
	queries, _ := url.ParseQuery(req.URL.RawQuery)

	var latestVersion bool
	var sortFields []string // not initialized means do not sort
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
		case "sort":
			sortFields = []string{value[0]}
			// override "state" with status, they are not the same in db
			if value[0] == "state" {
				sortFields = []string{"status"}
			}
		default:
			if key == "name" {
				name := value[0]
				if counts := strings.Count(value[0], "-"); counts > 0 {
					s := strings.Split(value[0], "-")
					name = s[0]
				}
				// if searched for social-1, social-2, then return all workers
				// that begins with social
				query[key] = bson.RegEx{Pattern: name, Options: "i"}
			} else {
				query[key] = value[0]
			}
		}
	}

	matchedWorkers := queryResult(query, latestVersion, sortFields)
	data, err := json.MarshalIndent(matchedWorkers, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}
	writer.Write(data)

}

func queryResult(query bson.M, latestVersion bool, sortFields []string) Workers {
	workers := make(Workers, 0)
	worker := models.Worker{}

	queryFunc := func(c *mgo.Collection) error {
		// sorting is no-op when sortFields is empty
		iter := c.Find(query).Sort(sortFields...).Iter()
		for iter.Next(&worker) {
			apiWorker := &ApiWorker{
				Name:               worker.Name,
				Version:            worker.Version,
				Environment:        worker.Environment,
				Hostname:           worker.Hostname,
				ServiceGenericName: worker.ServiceGenericName,
				ServiceUniqueName:  worker.ServiceUniqueName,
				Uuid:               worker.Uuid,
				Timestamp:          worker.Timestamp,
				Pid:                worker.Pid,
				State:              StatusCode[worker.Status],
				Uptime:             worker.Monitor.Uptime,
				Port:               worker.Port,
			}

			workers = append(workers, *apiWorker)
		}
		return nil
	}

	kontrolDB.RunOnDatabase(WorkersDB, WorkersCollection, queryFunc)

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

func GetWorker(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	query := bson.M{"uuid": uuid}
	matchedWorkers := queryResult(query, false, nil)
	data, err := json.MarshalIndent(matchedWorkers, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}
	writer.Write(data)
}
