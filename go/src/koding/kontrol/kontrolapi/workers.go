package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/kontrol/kontroldaemon/workerconfig"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"
)

type ApiWorker struct {
	Name               string    `json:"name"`
	ServiceGenericName string    `json:"serviceGenericName"`
	ServiceUniqueName  string    `json:"serviceUniqueName"`
	Uuid               string    `json:"uuid"`
	Hostname           string    `json:"hostname"`
	Version            int       `json:"version"`
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
				query[key] = bson.RegEx{Pattern: "^" + name, Options: "i"}
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

func UpdateWorker(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid, action := vars["uuid"], vars["action"]

	buildSendCmd(action, uuid)
	resp := fmt.Sprintf("worker: '%s' is updated in db", uuid)
	io.WriteString(writer, resp)
}

func DeleteWorker(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	uuid := vars["uuid"]

	buildSendCmd("delete", uuid)
	resp := fmt.Sprintf("worker: '%s' is deleted from db", uuid)
	io.WriteString(writer, resp)
}

func queryResult(query bson.M, latestVersion bool, sortFields []string) Workers {
	workers := make(Workers, 0)
	worker := models.Worker{}

	queryFunc := func(c *mgo.Collection) error {
		// sorting is no-op when sortFields is empty
		iter := c.Find(query).Sort(sortFields...).Iter()
		for iter.Next(&worker) {
			apiWorker := &ApiWorker{
				worker.Name,
				worker.ServiceGenericName,
				worker.ServiceUniqueName,
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
		return nil
	}

	mongodb.Run("jKontrolWorkers", queryFunc)

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
