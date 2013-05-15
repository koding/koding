package workerconfig

import (
	"errors"
	"fmt"
	"koding/kontrol/kontrolhelper"
	"koding/tools/config"
	"koding/tools/process"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
	"os"
	"regexp"
	"time"
)

const (
	Stopped WorkerStatus = iota
	Running
	Pending
	Notstarted
	Killed
	Dead
	Waiting
)

type WorkerStatus int

type WorkerMessage struct {
	Command string `json:"command"`
	Option  string `json:"option"`
	Result  string `json:"result"`
}

// WorkerResponse will replace WorkerMessage as a seperated message format
// Not used currently, wip...
type WorkerResponse struct {
	Name      string    `json:"name"`
	Uuid      string    `json:"uuid"`
	Result    string    `json:"result"`
	Timestamp time.Time `json:"timestamp"`
}

func NewWorkerResponse(name, uuid, result string, timestamp time.Time) *WorkerResponse {
	return &WorkerResponse{
		Name:      name,
		Uuid:      uuid,
		Result:    result,
		Timestamp: timestamp,
	}
}

type Worker struct {
	Name      string       `json:"name"`
	Uuid      string       `json:"uuid"`
	Hostname  string       `json:"hostname"`
	Version   int          `json:"version"`
	Timestamp time.Time    `json:"timestamp"`
	Pid       int          `json:"pid"`
	Status    WorkerStatus `json:"status"`
	Port      int          `json:"port"`
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

type StatusResponse struct {
	Hostname map[string][]SingleStatusResponse `json:"status"`
}

type SingleStatusResponse struct {
	Name      string       `json:"name"`
	Uuid      string       `json:"uuid"`
	Hostname  string       `json:"hostname"`
	Version   int          `json:"version"`
	Timestamp time.Time    `json:"timestamp"`
	Pid       int          `json:"pid"`
	Status    WorkerStatus `json:"status"`
	Memory    int          `json:"memory"`
	Uptime    int          `json:"uptime"`
	Port      int          `json:"port"`
}

type Request struct {
	Command  string
	Hostname string
	Uuid     string
}

type ClientRequest struct {
	Action   string
	Cmd      string
	Hostname string
	Pid      int
}

func NewSingleStatusResponse(name, uuid, hostname string, version, pid int, status WorkerStatus, mem, uptime, port int) *SingleStatusResponse {
	return &SingleStatusResponse{
		Name:      name,
		Uuid:      uuid,
		Hostname:  hostname,
		Version:   version,
		Pid:       pid,
		Status:    status,
		Timestamp: time.Now().UTC(),
		Memory:    mem,
		Uptime:    uptime,
		Port:      port,
	}
}

func NewStatusResponse() *StatusResponse {
	return &StatusResponse{
		Hostname: make(map[string][]SingleStatusResponse),
	}
}

type WorkerConfig struct {
	Hostname        string
	RegisteredHosts map[string][]string
	Session         *mgo.Session
	Collection      *mgo.Collection
}

type MsgWorker struct {
	Name           string           `json:"name"`
	Uuid           string           `json:"uuid"`
	Hostname       string           `json:"hostname"`
	Version        int              `json:"version"`
	Timestamp      time.Time        `json:"timestamp"`
	Pid            int              `json:"pid"`
	Status         WorkerStatus     `json:"status"`
	Cmd            string           `json:"cmd"`
	ProcessData    string           `json:"processData"`
	Number         int              `json:"number"`
	Message        WorkerMessage    `json:"message"`
	CompatibleWith map[string][]int `json:"compatibleWith"`
	Port           int              `json:"port"`
	RabbitKey      string           `json:"rabbitKey"`
	Monitor        struct {
		Mem    MemData `json:"mem"`
		Uptime int     `json:"uptime"`
	} `json:"monitor"`
}

// Start point. Needs to be called in order to use other methods
func Connect() (*WorkerConfig, error) {
	host := config.Current.Kontrold.Mongo.Host
	session, err := mgo.Dial(host)
	if err != nil {
		return nil, err
	}
	session.SetMode(mgo.Strong, true)

	col := session.DB("kontrol").C("workers")

	wk := &WorkerConfig{
		Hostname:        kontrolhelper.CustomHostname(),
		RegisteredHosts: make(map[string][]string),
		Session:         session,
		Collection:      col,
	}

	return wk, nil
}

func (w *WorkerConfig) Status(hostname, uuid string) (*StatusResponse, error) {
	res := *NewStatusResponse()
	err := w.RefreshStatusAll()
	if err != nil {
		log.Println("couldn't refresh data", err)
	}

	addSingleResponse := func(d MsgWorker) {
		res.Hostname[d.Hostname] = append(res.Hostname[d.Hostname],
			*NewSingleStatusResponse(
				d.Name,
				d.Uuid,
				d.Hostname,
				d.Version,
				d.Pid,
				d.Status,
				d.Monitor.Mem.HeapTotal,
				d.Monitor.Uptime,
				d.Port))

	}
	result := MsgWorker{}
	if hostname == "" && uuid == "" {
		iter := w.Collection.Find(nil).Iter()
		for iter.Next(&result) {
			addSingleResponse(result)
		}

	} else if hostname != "" && uuid == "" {
		iter := w.Collection.Find(bson.M{"hostname": hostname}).Iter()
		for iter.Next(&result) {
			addSingleResponse(result)
		}

	} else if hostname != "" && uuid != "" {
		iter := w.Collection.Find(bson.M{"hostname": hostname, "uuid": uuid}).Iter()
		for iter.Next(&result) {
			addSingleResponse(result)
		}
	} else if hostname == "" && uuid != "" {
		return nil, errors.New("please provide hostname for creating status repsonse")
	}

	return &res, nil
}

func (w *WorkerConfig) RefreshStatus(uuid string) error {
	workerData, err := w.GetWorker(uuid)
	if err != nil {
		return err
	}

	if workerData.Timestamp.IsZero() {
		workerData.Status = Notstarted
		workerData.Monitor.Mem = MemData{}
		workerData.Monitor.Uptime = 0
	} else if workerData.Timestamp.Add(15 * time.Second).Before(time.Now().UTC()) {
		workerData.Status = Dead
		workerData.Monitor.Mem = MemData{}
		workerData.Monitor.Uptime = 0
	} // otherwise the workers are still alive

	w.UpdateWorker(workerData)
	return nil
}

func (w *WorkerConfig) RefreshStatusAll() error {
	result := MsgWorker{}
	iter := w.Collection.Find(nil).Iter()
	for iter.Next(&result) {
		err := w.RefreshStatus(result.Uuid)
		if err != nil {
			return err
		}
	}

	return nil
}

func (w *WorkerConfig) Delete(hostname, uuid string) error {
	workerResult, err := w.GetWorker(uuid)
	if err != nil {
		return fmt.Errorf("delete method error '%s'", err)
	}

	log.Printf("deleting worker '%s' with hostname '%s' from the db", workerResult.Name, hostname)
	w.DeleteWorker(uuid)
	return nil
}

func (w *WorkerConfig) Stop(hostname, uuid string) (MsgWorker, error) {
	workerResult, err := w.GetWorker(uuid)
	if err != nil {
		return workerResult, fmt.Errorf("stop method error '%s'", err)
	}
	if workerResult.Status == Running {
		workerResult.Status = Waiting
		workerResult.Message.Result = "stopped.now"
	} else {
		workerResult.Message.Result = "stopped.before"
	}

	log.Printf("stopping worker '%s' on '%s'", workerResult.Name, hostname)

	w.UpdateWorker(workerResult)
	return workerResult, nil
}

func (w *WorkerConfig) Kill(hostname, uuid string) (MsgWorker, error) {
	workerResult, err := w.GetWorker(uuid)
	if err != nil {
		return workerResult, fmt.Errorf("kill method error '%s'", err)
	}

	workerResult.Message.Result = "killed.now"
	workerResult.Status = Waiting
	log.Printf("killing worker with pid: %d on hostname: %s", workerResult.Pid, hostname)

	w.UpdateWorker(workerResult)
	return workerResult, nil
}

func (w *WorkerConfig) Start(hostname, uuid string) (MsgWorker, error) {
	workerResult, err := w.GetWorker(uuid)
	if err != nil {
		return workerResult, fmt.Errorf("start method error '%s'", err)
	}

	if workerResult.Status == Stopped || workerResult.Status == Killed {
		workerResult.Status = Waiting
		workerResult.Message.Result = "started.now"
		log.Printf("starting worker: '%s' on '%s'", workerResult.Name, hostname)
	} else if workerResult.Status == Notstarted || workerResult.Status == Dead {

		// data := buildReq("start", workerResult.Cmd, hostname, workerResult.Pid)
		// go deliver(data, clientProducer, "")
		_, err := os.Getwd()
		if err != nil {
			log.Println(err)
		}

		// TODO don't execute if salt-master is not up
		// FIXME remove sudo and cwd from the salt command
		// out, err := process.RunCmd("sudo", "salt", hostname, "--async", "cmd.run", workerResult.Cmd, "cwd="+pwd)
		out, err := process.RunCmd("echo", workerResult.Cmd)
		if err != nil {
			log.Println(err)
		}

		log.Println(string(out))
		workerResult.Message.Result = ""
		return workerResult, nil

	} else {
		workerResult.Message.Result = "started.before"
	}

	w.UpdateWorker(workerResult)
	return workerResult, nil
}

func (w *WorkerConfig) UpdateWorker(worker MsgWorker) {
	err := w.Collection.Update(bson.M{"uuid": worker.Uuid}, worker)
	if err != nil {
		log.Println(err)
	}
}

func (w *WorkerConfig) AddWorker(worker MsgWorker) {
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

func (w *WorkerConfig) ApprovedHost(name, host string) bool {
	// TODO: Should use mongodb
	v := len(w.RegisteredHosts)
	if v == 0 {
		// if empty means no process file was read, thus assume as approved
		return true
	}

	val, ok := w.RegisteredHosts[name]
	if ok {
		if val == nil {
			// if no host key is defined in process file assume as approved
			return true
		}
	}

	for _, val := range w.RegisteredHosts[name] {
		r, err := regexp.Compile(val)
		if err != nil {
			log.Printf("there is a problem with regexp.\n")
			return false
		}

		if r.MatchString(host) == true {
			log.Printf("worker '%s' with hostname '%s' matched '%s'. Approved...", name, host, val)
			return true
		}
	}
	log.Printf("worker '%s' with hostname '%s' didn't matched anything. Not approved...", name, host)
	return false
}

func (w *WorkerConfig) NumberOfWorker(workerName, workerHostname string) int {
	count, _ := w.Collection.Find(bson.M{"name": workerName, "hostname": workerHostname}).Count()

	return count
}

func (w *WorkerConfig) Update(worker MsgWorker) error {
	// No check for uuid, this is a destructive action. Thus use with caution.
	// After creating a processes, the process sends a new "update" message with
	// child pid, a new uuid and his new status.
	result := MsgWorker{}
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

	log.Printf("updating worker '%s' - '%s' - '%s'", worker.Name, worker.Hostname, worker.Uuid)
	w.AddWorker(result)
	return nil
}

func (w *WorkerConfig) Ack(worker MsgWorker) error {
	workerResult, err := w.GetWorker(worker.Uuid)
	if err != nil {
		return fmt.Errorf("ack method error '%s'", err)
	}

	workerResult.Message.Result = "alive"
	workerResult.Message.Command = "acked.now" //Not used by anyone, future...
	workerResult.Timestamp = worker.Timestamp
	workerResult.Status = worker.Status
	workerResult.Monitor.Uptime = worker.Monitor.Uptime

	w.UpdateWorker(workerResult)
	return nil
}

func (w *WorkerConfig) IsEmpty() (bool, error) {
	v, _ := w.Collection.Count()
	if v == 0 {
		return true, fmt.Errorf("no workers registered. Please register before you can continue.")
	}
	return false, fmt.Errorf("%s workers are registered.", v)
}

func (w *WorkerConfig) GetWorker(uuid string) (MsgWorker, error) {
	result := MsgWorker{}
	err := w.Collection.Find(bson.M{"uuid": uuid}).One(&result)
	if err != nil {
		return result, fmt.Errorf("no worker with the uuid %s exist.", uuid)
	}

	return result, nil

}
