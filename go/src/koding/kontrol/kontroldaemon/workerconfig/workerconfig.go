package workerconfig

import (
	"fmt"
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
	"os"
	"time"
)

const HEARTBEAT_INTERVAL = time.Second * 10
const HEARTBEAT_DELAY = time.Second * 10

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
	Log     string `json:"log"`
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
	Name               string       `json:"name"`
	ServiceGenericName string       `bson:"serviceGenericName" json:"serviceGenericName"`
	ServiceUniqueName  string       `bson:"serviceUniqueName" json:"serviceUniqueName"`
	Uuid               string       `json:"uuid"`
	Hostname           string       `json:"hostname"`
	Version            int          `json:"version"`
	Timestamp          time.Time    `json:"timestamp"`
	Pid                int          `json:"pid"`
	Status             WorkerStatus `json:"status"`
	Cmd                string       `json:"cmd"`
	ProcessData        string       `json:"processData"`
	Number             int          `json:"number"`
	Message            struct {
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

func NewWorkerResponse(name, uuid, command, log string) *WorkerResponse {
	return &WorkerResponse{
		Name:    name,
		Uuid:    uuid,
		Command: command,
		Log:     log,
	}
}

type WorkerConfig struct {
	Hostname string
	Session  *mgo.Session
}

// Start point. Needs to be called in order to use other methods
func Connect() (*WorkerConfig, error) {
	hostname, _ := os.Hostname()
	w := &WorkerConfig{Hostname: hostname}
	w.CreateSession(config.Current.Mongo)
	return w, nil
}

func (w *WorkerConfig) CreateSession(url string) {
	var err error
	w.Session, err = mgo.Dial(url)
	if err != nil {
		panic(err) // no, not really
	}

	w.Session.SetSafe(&mgo.Safe{})
}

func (w *WorkerConfig) Close() {
	w.Session.Close()
}

func (w *WorkerConfig) Copy() *mgo.Session {
	return w.Session.Copy()
}

func (w *WorkerConfig) GetSession() *mgo.Session {
	if w.Session == nil {
		w.CreateSession(config.Current.Mongo)
	}
	return w.Copy()
}

func (w *WorkerConfig) RunCollection(collection string, s func(*mgo.Collection) error) error {
	session := w.GetSession()
	defer session.Close()
	c := session.DB("").C(collection)
	return s(c)
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
	response := *NewWorkerResponse(worker.Name, worker.Uuid, command, "you got a kill message")

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
		command = "start"
	} else {
		command = "noPermission"
	}

	response := *NewWorkerResponse(worker.Name, worker.Uuid, command, "you got a start message")
	return response, nil
}

func (w *WorkerConfig) Update(worker Worker) error {
	// No check for uuid, this is a destructive action. Thus use with caution.
	// After creating a processes, the process sends a new "update" message with
	// child pid, a new uuid and his new status.
	result := Worker{}
	found := false

	query := func(c *mgo.Collection) error {
		iter := c.Find(bson.M{"uuid": worker.Uuid}).Iter()
		for iter.Next(&result) {
			found = true
		}

		return nil
	}

	w.RunCollection("jKontrolWorkers", query)

	if !found {
		return fmt.Errorf("no worker found with name '%s' and hostname '%s'",
			worker.Name,
			worker.Hostname,
		)
	}

	result.Timestamp = time.Now().Add(HEARTBEAT_INTERVAL)
	result.Status = worker.Status
	result.Pid = worker.Pid
	result.Uuid = worker.Uuid
	result.Version = worker.Version

	log.Printf("[%s (%d)] update allowed from: '%s' - '%s'",
		worker.Name,
		worker.Version,
		worker.Hostname,
		worker.Uuid,
	)

	w.UpsertWorker(result)
	return nil
}

func (w *WorkerConfig) Ack(worker Worker) error {
	worker.Timestamp = time.Now().Add(HEARTBEAT_INTERVAL)
	r, err := w.GetWorker(worker.Uuid)
	if err != nil {
		// if not found insert it
		w.UpsertWorker(worker)
		return nil
	}

	// only change those fields
	r.Timestamp = worker.Timestamp
	r.Status = Started
	r.Monitor.Uptime = worker.Monitor.Uptime
	w.UpdateWorker(r)
	return nil
}

func (w *WorkerConfig) GetWorker(uuid string) (Worker, error) {
	result := Worker{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"uuid": uuid}).One(&result)
	}

	err := w.RunCollection("jKontrolWorkers", query)
	if err != nil {
		return result, fmt.Errorf("no worker with the uuid %s exist.", uuid)
	}

	return result, nil
}

func (w *WorkerConfig) UpdateWorker(worker Worker) {
	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"uuid": worker.Uuid}, worker)
	}

	err := w.RunCollection("jKontrolWorkers", query)
	if err != nil {
		log.Println(err)
	}
}

func (w *WorkerConfig) UpsertWorker(worker Worker) error {
	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"uuid": worker.Uuid}, worker)
		return err
	}

	return w.RunCollection("jKontrolWorkers", query)
}

func (w *WorkerConfig) DeleteWorker(uuid string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"uuid": uuid})
	}

	return w.RunCollection("jKontrolWorkers", query)
}

func (w *WorkerConfig) NumberOfWorker(name string, version int) int {
	var count int

	query := func(c *mgo.Collection) error {
		count, _ = c.Find(bson.M{"name": name, "version": version}).Count()
		return nil
	}

	w.RunCollection("jKontrolWorkers", query)
	return count
}
