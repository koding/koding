package main

import (
	"encoding/json"
	"io/ioutil"
	"labix.org/v2/mgo/bson"
	"log"
	"net/http"
)

type Rollbar struct {
	EventName string      `json:"event_name"`
	Item      RollbarItem `json:"item"`
}

type RollbarItem struct {
	Body RollbarItemMsg `json:"body"`
}

type RollbarItemMsg struct {
	Message string `json:"message"`
}

type Service struct {
	Name string
}

var Services = map[string]Service{
	"gobroker": Service{"gobroker"},
	"social":   Service{"social"},
	"auth":     Service{"auth"},
	"email":    Service{"email"},
}

var ProblemToServices = map[string][]Service{
	"disconnected": []Service{
		Services["auth"],
		Services["email"]},
}

func rollbar(writer http.ResponseWriter, request *http.Request) {
	rollbar, err := parseRollbarReq(request)
	if err != nil {
		log.Println("Rollar parse error", err)
	}

	workers := findWorkersRelevantToProblem(rollbar.Problem())
	for _, worker := range workers {
		switch worker.State {
		case "notresponding":
			worker.Restart()
		}
	}
}

func parseRollbarReq(request *http.Request) (Rollbar, error) {
	b, err := ioutil.ReadAll(request.Body)
	defer request.Body.Close()

	var rollbar Rollbar
	err = json.Unmarshal(b, &rollbar)

	return rollbar, err
}

func findWorkersRelevantToProblem(problem string) []Worker {
	query := bson.M{}
	allWorkers := queryResult(query, false) // for empty bson.M it returns all workers
	s := make([]interface{}, len(allWorkers))
	for i, v := range allWorkers {
		s[i] = v
	}

	services := ProblemToServices["disconnected"]
	log.Println(services)

	matcher := NewMatcher(s)

	for _, service := range services {
		matcher.ByString("Name", service.Name)
	}

	t := matcher.Run()
	matchedWorkers := make(Workers, len(t))
	for i, item := range t {
		w, _ := item.(Worker)
		matchedWorkers[i] = w
	}

	return matchedWorkers
}

func (worker *Worker) Restart() {
	buildSendCmd("stop", worker.Hostname, worker.Uuid)
	buildSendCmd("start", worker.Hostname, worker.Uuid)
}

//func tryRestart(worker Worker, numOfTries int) int {
//var tries int
//oldStatus := service.StatusString
//newStatus := service.StatusString

//TODO: restart mutliple times if first time didn't work
//for tries := 5; numOfTries < tries; tries++ {

//newStatus = getStatusOfService(service.Name)

//TODO: wait a while
//if newStatus == oldStatus {
//return numOfTries
//} else {
//service.Restart()
//}
//}

//return numOfTries
//}

func (rollbar *Rollbar) Problem() string {
	return rollbar.Item.Body.Message
}
