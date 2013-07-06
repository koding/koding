package workerconfig

import (
	"fmt"
	"koding/kontrol/kontrolhelper"
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
	"time"
)

const (
	Started WorkerStatus = iota
	Killed
	Dead
	Waiting
)

type WorkerStatus int

type WorkerResponse struct {
	Name    string `json:"name"`
	Uuid    string `json:"uuid"`
	Command string `json:"command"`
}

type MemData struct {
	Rss       int    `json:"rss"`
	HeapTotal int    `json:"heaptotal"`
	HeapUsed  int    `json:"heapused"`
	Unit      string `json:"unit"`
}

type Monitor struct {
	Name   string
	Uuid   string
	Mem    *MemData
	Uptime int
}

type ApiRequest struct {
	Uuid    string `json:"uuid"`
	Command string `json:"command"`
}

type ClientRequest struct {
	Action   string
	Cmd      string
	Hostname string
	Pid      int
}

type Worker struct {
	Name              string       `json:"name"`
	ServiceUniqueName string       `json:"serviceUniqueName"`
	Uuid              string       `json:"uuid"`
	Hostname          string       `json:"hostname"`
	Version           int          `json:"version"`
	Timestamp         time.Time    `json:"timestamp"`
	Pid               int          `json:"pid"`
	Status            WorkerStatus `json:"status"`
	Cmd               string       `json:"cmd"`
	ProcessData       string       `json:"processData"`
	Number            int          `json:"number"`
	Message           struct {
		Command string `json:"command"`
		Option  string `json:"option"`
	} `json:"message"`
	CompatibleWith map[string][]int `json:"compatibleWith"`
	Port           int              `json:"port"`
	RabbitKey      string           `json:"rabbitKey"`
	Monitor        struct {
		Mem    MemData `json:"mem"`
		Uptime int     `json:"uptime"`
	} `json:"monitor"`
}

func NewWorkerResponse(name, uuid, command string) *WorkerResponse {
	return &WorkerResponse{
		Name:    name,
		Uuid:    uuid,
		Command: command,
	}
}

type WorkerConfig struct {
	Hostname   string
	Session    *mgo.Session
	Collection *mgo.Collection
}

// Start point. Needs to be called in order to use other methods
func Connect() (*WorkerConfig, error) {
	session, err := mgo.Dial(config.Current.Mongo)
	if err != nil {
		return nil, err
	}
	session.SetMode(mgo.Strong, true)
	session.SetSafe(&mgo.Safe{})
	database := session.DB("")

	col := database.C("jKontrolWorkers")

	wk := &WorkerConfig{
		Hostname:   kontrolhelper.CustomHostname(),
		Session:    session,
		Collection: col,
	}

	return wk, nil
}

func (w *WorkerConfig) Delete(uuid string) error {
	worker, err := w.GetWorker(uuid)
	if err != nil {
		return fmt.Errorf("delete method error '%s'", err)
	}

	log.Printf("deleting worker '%s' with hostname '%s' from the db", worker.Name, worker.Hostname)
	w.DeleteWorker(uuid)
	return nil
}

func (w *WorkerConfig) Kill(uuid, mode string) (WorkerResponse, error) {
	worker, err := w.GetWorker(uuid)
	if err != nil {
		return WorkerResponse{}, fmt.Errorf("kill method error '%s'", err)
	}
	log.Printf("killing worker with pid: %d on hostname: %s", worker.Pid, worker.Hostname)

	// create response to be sent
	command := "kill"
	if mode == "force" {
		command = "killForce"
	}
	response := *NewWorkerResponse(worker.Name, worker.Uuid, command)

	// mark as waiting until we got a message
	worker.Status = Waiting
	w.UpdateWorker(worker)

	return response, nil
}

func (w *WorkerConfig) Start(uuid string) (WorkerResponse, error) {
	worker, err := w.GetWorker(uuid)
	if err != nil {
		return WorkerResponse{}, fmt.Errorf("start method error '%s'", err)
	}

	var command string
	if worker.Status == Dead || worker.Status == Killed {
		log.Printf("starting worker: '%s' on '%s'", worker.Name, worker.Hostname)
		worker.Status = Waiting
		w.UpdateWorker(worker)
		command = "started.now"
	} else {
		command = "started.before"
	}

	response := *NewWorkerResponse(worker.Name, worker.Uuid, command)
	return response, nil
}

func (w *WorkerConfig) Update(worker Worker) error {
	// No check for uuid, this is a destructive action. Thus use with caution.
	// After creating a processes, the process sends a new "update" message with
	// child pid, a new uuid and his new status.
	result := Worker{}
	found := false

	iter := w.Collection.Find(bson.M{"uuid": worker.Uuid, "hostname": worker.Hostname}).Iter()
	for iter.Next(&result) {
		w.DeleteWorker(result.Uuid)
		found = true
	}

	if !found {
		return fmt.Errorf("no worker found with name '%s' and hostname '%s'", worker.Name, worker.Hostname)
	}

	result.Timestamp = worker.Timestamp
	result.Status = worker.Status
	result.Pid = worker.Pid
	result.Uuid = worker.Uuid
	result.Version = worker.Version

	log.Printf("[%s (%d)] updating with new info from '%s'", worker.Name, worker.Version, worker.Hostname)
	w.AddWorker(result)
	return nil
}

func (w *WorkerConfig) Ack(worker Worker) error {
	existingWorker, err := w.GetWorker(worker.Uuid)
	if err != nil {
		return fmt.Errorf("ack method error for hostanme %s worker %s version %d '%s'", worker.Hostname, worker.Name, worker.Version, err)
	}

	existingWorker.Timestamp = worker.Timestamp
	existingWorker.Status = worker.Status
	existingWorker.Monitor.Uptime = worker.Monitor.Uptime

	w.UpdateWorker(existingWorker)
	return nil
}

func (w *WorkerConfig) RefreshStatusAll() error {
	worker := Worker{}
	iter := w.Collection.Find(nil).Iter()
	for iter.Next(&worker) {
		if worker.Status == Dead {
			continue
		}

		if worker.Timestamp.Add(15 * time.Second).Before(time.Now().UTC()) {
			log.Printf("[%s (%d)] no activity at '%s' (pid: %d). marking as dead\n", worker.Name, worker.Version, worker.Hostname, worker.Pid)
			worker.Status = Dead
			worker.Monitor.Mem = MemData{}
			worker.Monitor.Uptime = 0
			w.UpdateWorker(worker)
		} // otherwise the workers are still alive
	}

	return nil
}

func (w *WorkerConfig) GetWorker(uuid string) (Worker, error) {
	result := Worker{}
	err := w.Collection.Find(bson.M{"uuid": uuid}).One(&result)
	if err != nil {
		return result, fmt.Errorf("no worker with the uuid %s exist.", uuid)
	}

	return result, nil

}

func (w *WorkerConfig) UpdateWorker(worker Worker) {
	err := w.Collection.Update(bson.M{"uuid": worker.Uuid}, worker)
	if err != nil {
		log.Println(err)
	}
}

func (w *WorkerConfig) AddWorker(worker Worker) {
	err := w.Collection.Insert(worker)
	if err != nil {
		log.Println(err)
	}

}

func (w *WorkerConfig) DeleteWorker(uuid string) {
	err := w.Collection.Remove(bson.M{"uuid": uuid})
	if err != nil {
		log.Println(err)
	}
}

func (w *WorkerConfig) NumberOfWorker(name string, version int) int {
	count, _ := w.Collection.Find(bson.M{"name": name, "version": version}).Count()
	return count
}
