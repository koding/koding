package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"koding/kontrol/kontroldaemon/workerconfig"
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

var StatusCode = map[workerconfig.WorkerStatus]string{
	workerconfig.Started: "started",
	workerconfig.Waiting: "waiting",
	workerconfig.Killed:  "dead",
	workerconfig.Dead:    "dead",
}

func GetWorkers(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("GET /workers")
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
				// if searched for social-1, social-2, then return all workers
				// that begins with social
				query[key] = bson.RegEx{Pattern: "^" + name, Options: "i"}
			} else {
				query[key] = value[0]
			}
		}
	}

	matchedWorkers := queryResult(query, latestVersion)
	data, err := json.MarshalIndent(matchedWorkers, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}
	writer.Write(data)

}

func GetWorker(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	fmt.Printf("GET /workers/%s\n", uuid)

	query := bson.M{"uuid": uuid}
	matchedWorkers := queryResult(query, false)
	data, err := json.MarshalIndent(matchedWorkers, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}
	writer.Write(data)
}

func UpdateWorker(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid, action := vars["uuid"], vars["action"]
	fmt.Printf("%s /workers/%s\n", strings.ToUpper(action), uuid)

	buildSendCmd(action, uuid)
	resp := fmt.Sprintf("worker: '%s' is updated in db", uuid)
	io.WriteString(writer, resp)
}

func DeleteWorker(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]
	fmt.Printf("DELETE /workers/%s\n", uuid)

	buildSendCmd("delete", uuid)
	resp := fmt.Sprintf("worker: '%s' is deleted from db", uuid)
	io.WriteString(writer, resp)
}

func queryResult(query bson.M, latestVersion bool) Workers {
	workers := make(Workers, 0)
	worker := workerconfig.Worker{}

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

func buildSendCmd(action, uuid string) {
	cmd := workerconfig.ApiRequest{Uuid: uuid, Command: action}
	data, err := json.Marshal(cmd)
	if err != nil {
		log.Println("Json marshall error", data)
	}

	log.Println("Sending cmd to kontrold:", cmd)
	amqpWrapper.Publish(data)
}
