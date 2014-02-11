package workerconfig

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/tools/logger"
	"time"
)

const HEARTBEAT_INTERVAL = time.Second * 10
const HEARTBEAT_DELAY = time.Second * 10

type WorkerResponse struct {
	Name    string `json:"name"`
	Uuid    string `json:"uuid"`
	Command string `json:"command"`
	Log     string `json:"log"`
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

var log = logger.New("kontroldaemon")

func NewWorkerResponse(name, uuid, command, log string) *WorkerResponse {
	return &WorkerResponse{
		Name:    name,
		Uuid:    uuid,
		Command: command,
		Log:     log,
	}
}

func Delete(uuid string) error {
	worker, err := modelhelper.GetWorker(uuid)
	if err != nil {
		return fmt.Errorf("delete method error '%s'", err)
	}

	log.Info("deleting worker '%s' with hostname '%s' from the db", worker.Name, worker.Hostname)
	modelhelper.DeleteWorker(uuid)
	return nil
}

func Kill(uuid, mode string) (WorkerResponse, error) {
	worker, err := modelhelper.GetWorker(uuid)
	if err != nil {
		return WorkerResponse{}, fmt.Errorf("kill method error '%s'", err)
	}
	log.Info("killing worker with pid: %d on hostname: %s", worker.Pid, worker.Hostname)

	// create response to be sent
	command := "kill"
	if mode == "force" {
		command = "killForce"
	}
	response := *NewWorkerResponse(worker.Name, worker.Uuid, command, "you got a kill message")

	// mark as waiting until we got a message
	worker.Status = models.Waiting
	modelhelper.UpdateWorker(worker)

	return response, nil
}

func Start(uuid string) (WorkerResponse, error) {
	worker, err := modelhelper.GetWorker(uuid)
	if err != nil {
		return WorkerResponse{}, fmt.Errorf("start method error '%s'", err)
	}

	var command string
	if worker.Status == models.Dead || worker.Status == models.Killed {
		log.Info("starting worker: '%s' on '%s'", worker.Name, worker.Hostname)
		worker.Status = models.Waiting
		modelhelper.UpdateWorker(worker)
		command = "start"
	} else {
		command = "noPermission"
	}

	response := *NewWorkerResponse(worker.Name, worker.Uuid, command, "you got a start message")
	return response, nil
}

func Update(worker models.Worker) error {
	r, err := modelhelper.GetWorker(worker.Uuid)
	if err != nil {
		return fmt.Errorf("no worker found with name '%s' and hostname '%s'",
			worker.Name,
			worker.Hostname,
		)
	}

	r.Timestamp = time.Now().Add(HEARTBEAT_INTERVAL)
	r.Status = worker.Status
	r.Pid = worker.Pid
	r.Uuid = worker.Uuid
	r.Version = worker.Version

	log.Info("[%s (%d)] update allowed from: '%s' - '%s'",
		worker.Name,
		worker.Version,
		worker.Hostname,
		worker.Uuid,
	)

	modelhelper.UpsertWorker(r)
	return nil
}

func Ack(worker models.Worker) error {
	worker.Timestamp = time.Now().Add(HEARTBEAT_INTERVAL)
	r, err := modelhelper.GetWorker(worker.Uuid)
	if err != nil {
		// if not found insert it
		modelhelper.UpsertWorker(worker)
		return nil
	}

	// only change those fields
	r.Timestamp = worker.Timestamp
	r.Status = models.Started
	r.Monitor.Uptime = worker.Monitor.Uptime
	modelhelper.UpdateIDWorker(r)
	return nil
}
