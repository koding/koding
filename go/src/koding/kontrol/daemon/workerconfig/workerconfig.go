package workerconfig

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"koding/tools/process"
	"log"
	"os"
	"regexp"
	"strings"
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
	Worker
	Memory int `json:"memory"`
	Uptime int `json:"uptime"`
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

func NewSingleStatusResponse(name, uuid, hostname string, version, pid int, status WorkerStatus, mem, uptime int) *SingleStatusResponse {
	return &SingleStatusResponse{
		Worker: Worker{
			Name:      name,
			Uuid:      uuid,
			Hostname:  hostname,
			Version:   version,
			Pid:       pid,
			Status:    status,
			Timestamp: time.Now().UTC(),
		},
		Memory: mem,
		Uptime: uptime,
	}
}

func NewStatusResponse() *StatusResponse {
	return &StatusResponse{
		Hostname: make(map[string][]SingleStatusResponse),
	}
}

type WorkerConfig struct {
	Hostname          string
	RegisteredWorkers map[string]MsgWorker
	RegisteredHosts   map[string][]string
}

func NewWorkerConfig() *WorkerConfig {
	wk := &WorkerConfig{
		Hostname:          customHostname(),
		RegisteredWorkers: make(map[string]MsgWorker),
		RegisteredHosts:   make(map[string][]string),
	}

	return wk
}

type MsgWorker struct {
	Worker
	Cmd            string           `json:"cmd"`
	Number         int              `json:"number"`
	Message        WorkerMessage    `json:"message"`
	CompatibleWith map[string][]int `json:"compatibleWith"`
	Monitor        struct {
		Mem    MemData `json:"mem"`
		Uptime int     `json:"uptime"`
	} `json:"monitor"`
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
				d.Monitor.Uptime))
	}

	if hostname == "" && uuid == "" {
		for _, d := range w.RegisteredWorkers {
			addSingleResponse(d)
		}
	} else if hostname != "" && uuid == "" {
		for _, d := range w.RegisteredWorkers {
			if d.Hostname == hostname {
				addSingleResponse(d)
			}
		}
	} else if hostname != "" && uuid != "" {
		for _, d := range w.RegisteredWorkers {
			if d.Hostname == hostname && d.Uuid == uuid {
				addSingleResponse(d)
			}
		}
	} else if hostname == "" && uuid != "" {
		return nil, errors.New("please provide hostname for creating status repsonse")
	}

	return &res, nil
}

func (w *WorkerConfig) RefreshStatus(uuid string) error {
	err := w.HasUuid(uuid)
	if err != nil {
		return err
	}

	workerData := w.RegisteredWorkers[uuid]
	if workerData.Timestamp.IsZero() {
		workerData.Status = Notstarted
		workerData.Monitor.Mem = MemData{}
		workerData.Monitor.Uptime = 0
	} else {
		if workerData.Timestamp.Add(11 * time.Second).Before(time.Now().UTC()) {
			workerData.Status = Dead
			workerData.Monitor.Mem = MemData{}
			workerData.Monitor.Uptime = 0
		} else {
			// Worker is alive (started, stopped or child is killed), nothing to be changed
		}
	}

	w.RegisteredWorkers[uuid] = workerData
	if err := w.SaveToConfig(); err != nil {
		log.Printf(" %s", err)
		return err
	}

	return nil
}

func (w *WorkerConfig) RefreshStatusAll() error {
	for _, workerData := range w.RegisteredWorkers {
		err := w.RefreshStatus(workerData.Uuid)
		if err != nil {
			return err
		}
	}

	return nil
}

func (w *WorkerConfig) Delete(hostname, uuid string) error {
	err := w.HasUuid(uuid)
	if err != nil {
		return fmt.Errorf("deleting not possible '%s'", err)
	}

	workerResult := w.RegisteredWorkers[uuid]

	if workerResult.Status != Notstarted && workerResult.Status != Killed && workerResult.Status != Dead {
		return fmt.Errorf("deleting not possible. Worker '%s' on '%s' is still alive", workerResult.Name, workerResult.Hostname)
	}

	delete(w.RegisteredWorkers, uuid)
	log.Printf("deleting worker '%s' with hostname '%s' from the config", workerResult.Name, hostname)

	if err := w.SaveToConfig(); err != nil {
		log.Printf(" %s", err)
	}
	return nil
}

func (w *WorkerConfig) Stop(hostname, uuid string) (MsgWorker, error) {
	workerResult := w.RegisteredWorkers[uuid]
	if workerResult.Status == Running {
		workerResult.Status = Waiting
		workerResult.Message.Result = "stopped.now"
	} else {
		workerResult.Message.Result = "stopped.before"
	}

	log.Printf("stopping remote worker '%s' on '%s'", workerResult.Name, hostname)

	w.RegisteredWorkers[workerResult.Uuid] = workerResult
	if err := w.SaveToConfig(); err != nil {
		log.Printf(" %s", err)
	}

	return workerResult, nil
}

func (w *WorkerConfig) Kill(hostname, uuid string) (MsgWorker, error) {
	workerResult := w.RegisteredWorkers[uuid]
	workerResult.Message.Result = "killed.now"
	workerResult.Status = Waiting
	log.Printf("killing remote worker with pid: %d on hostname: %s", workerResult.Pid, hostname)

	w.RegisteredWorkers[workerResult.Uuid] = workerResult
	if err := w.SaveToConfig(); err != nil {
		log.Printf(" %s", err)
	}

	return workerResult, nil
}

func (w *WorkerConfig) Start(hostname, uuid string) (MsgWorker, error) {
	workerResult := w.RegisteredWorkers[uuid]
	if workerResult.Status == Stopped || workerResult.Status == Killed {
		workerResult.Status = Waiting
		workerResult.Message.Result = "started.now"
		log.Printf("starting remote worker: '%s' on '%s'", workerResult.Name, hostname)
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

	w.RegisteredWorkers[workerResult.Uuid] = workerResult
	if err := w.SaveToConfig(); err != nil {
		log.Printf(" %s", err)
	}

	return workerResult, nil
}

func (w *WorkerConfig) AddWorker(worker MsgWorker) {
	w.RegisteredWorkers[worker.Uuid] = worker
}

func (w *WorkerConfig) ApprovedHost(name, host string) bool {
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

func (w *WorkerConfig) NumberOfWorker(workerName, workerHostname string, status WorkerStatus, includeOnlyStatus bool) int {
	var count int = 0

	if includeOnlyStatus {
		for _, data := range w.RegisteredWorkers {
			if data.Name == workerName && data.Hostname == workerHostname && data.Status == status {
				count = count + 1
			}
		}
	} else {
		for _, data := range w.RegisteredWorkers {
			if data.Name == workerName && data.Hostname == workerHostname && data.Status != status {
				count = count + 1
			}
		}
	}

	return count
}

func (w *WorkerConfig) Update(worker MsgWorker) error {
	// No check for uuid, this is a destructive action. Thus use with caution.
	// After creating a processes, the process sends a new "update" message with
	// child pid, a new uuid and his new status.
	for _, workerData := range w.RegisteredWorkers {
		if workerData.Name == worker.Name && workerData.Hostname == worker.Hostname {
			delete(w.RegisteredWorkers, workerData.Uuid)
			workerData.Timestamp = worker.Timestamp
			workerData.Status = worker.Status
			workerData.Pid = worker.Pid
			workerData.Uuid = worker.Uuid
			workerData.Version = worker.Version
			w.RegisteredWorkers[workerData.Uuid] = workerData

			log.Printf("got new information from worker '%s' on hostname '%s' with uuid '%s'. Updating...",
				worker.Name,
				worker.Hostname,
				worker.Uuid)

			if err := w.SaveToConfig(); err != nil {
				log.Printf(" %s", err)
			}
		}
	}
	return nil
}

func (w *WorkerConfig) Ack(worker MsgWorker) error {
	err := w.HasUuid(worker.Uuid)
	if err != nil {
		return fmt.Errorf("ack method error '%s'", err)
	}

	workerResult := w.RegisteredWorkers[worker.Uuid]

	// if config.Verbose {
	// 	log.Printf(" remote worker '%s' on '%s' with pid: %d is alive", workerResult.Name, workerResult.Hostname, workerResult.Pid)
	// }

	// Fixme
	// if workerResult.Cmd == "" {
	// 	for name, prop := range processConfig {
	// 		if name == worker.Name {
	// 			log.Printf("updating worker cmd: %+v", worker)
	// 			workerResult.Cmd = prop.Cmd
	// 		}
	// 	}
	// }

	workerResult.Message.Result = "alive"
	workerResult.Message.Command = "acked.now" //Not used by anyone, future...
	workerResult.Timestamp = worker.Timestamp
	workerResult.Status = worker.Status

	w.RegisteredWorkers[worker.Uuid] = workerResult
	if err := w.SaveToConfig(); err != nil {
		log.Printf(" %s", err)
	}
	return nil
}

func (w *WorkerConfig) ReadConfig() {
	configFile := customHostname() + "-kontrold.json"

	file, err := ioutil.ReadFile(configFile)
	if err != nil {
		return
	}

	*w = WorkerConfig{} // zeroed because otherwise the old values can be still exist
	err = json.Unmarshal(file, &w)
	if err != nil {
		log.Print("bad json unmarshalling config file", err)
		return
	}
}

func (w *WorkerConfig) SaveToConfig() error {
	data, err := json.MarshalIndent(w, "", "  ")
	if err != nil {
		return fmt.Errorf("could not marshall json: %s", err)
	}
	// log.Printf(" Current status of config file: %s", data)

	configFile := customHostname() + "-kontrold.json"
	err = ioutil.WriteFile(configFile, data, 0644)
	if err != nil {
		return fmt.Errorf("could not save to config.json: %s", err)
	}

	return nil
}

func (w *WorkerConfig) IsEmpty() (bool, error) {
	v := len(w.RegisteredWorkers)
	if v == 0 {
		return true, fmt.Errorf("no workers registered. Please register before you can continue.")
	}
	return false, fmt.Errorf("%s workers are registered.", v)
}

func (w *WorkerConfig) HasName(name string) (bool, error) {
	// log.Println(" Checking for duplicates")
	for _, data := range w.RegisteredWorkers {
		if data.Name == name {
			return true, nil
		}
	}
	return false, fmt.Errorf("no worker found. Please register worker '%s' before you can continue", name)
}

func (w *WorkerConfig) HasUuid(uuid string) error {
	_, ok := w.RegisteredWorkers[uuid]
	if ok {
		return nil
	}
	return fmt.Errorf("no worker with the uuid %s exist.", uuid)
}

func customHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		log.Println(err)
	}

	// hostVersion := hostname + "-" + readVersion()
	hostVersion := hostname

	return hostVersion
}

func readVersion() string {
	file, err := ioutil.ReadFile("VERSION")
	if err != nil {
		log.Println(err)
	}

	return strings.TrimSpace(string(file))
}
