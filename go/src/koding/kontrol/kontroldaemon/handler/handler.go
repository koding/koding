package handler

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/streadway/amqp"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kontrol/kontroldaemon/workerconfig"
	"koding/kontrol/kontrolhelper"
	"koding/tools/slog"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"strconv"
	"strings"
	"time"
)

type IncomingMessage struct {
	Worker  *models.Worker
	Monitor *models.Monitor
}

var producer *kontrolhelper.Producer

func Startup() {
	var err error
	producer, err = kontrolhelper.CreateProducer("worker")
	if err != nil {
		slog.Println(err)
	}

	err = producer.Channel.ExchangeDeclare("clientExchange", "fanout", true, false, false, false, nil)
	if err != nil {
		slog.Printf("clientExchange exchange.declare: %s\n", err)
	}

	runHelperFunctions()

	slog.Println("handler is initialized")
}

var waitCounter = make(map[string]int)

// runHelperFunctions contains several indepenendent helper functions that do
// certain tasks.
func runHelperFunctions() {
	// HeartBeat checker for workers
	tickerWorker := time.NewTicker(workerconfig.HEARTBEAT_INTERVAL)
	go func() {
		queryFunc := func(c *mgo.Collection) error {
			worker := models.Worker{}
			iter := c.Find(nil).Iter()
			for iter.Next(&worker) {
				if time.Now().Before(worker.Timestamp.Add(workerconfig.HEARTBEAT_DELAY)) {
					waitCounter[worker.Uuid] = 0
					continue // still alive, pick up the next one
				}

				// It's just another precaution improvement.  We wait three
				// times until we got a message. If we don't get any message,
				// then we assume it's dead.

				waitCount, ok := waitCounter[worker.Uuid]
				if !ok {
					waitCounter[worker.Uuid]++
					continue
				}

				if waitCount != 3 {
					slog.Printf("[%s (%d)] WARNING. no message received. waitCount is '%d'\n",
						worker.Name,
						worker.Version,
						waitCount,
					)
					waitCounter[worker.Uuid]++
					continue
				}

				slog.Printf("[%s (%d)] no activity at '%s' - '%s' (pid: %d). removing it from db\n",
					worker.Name,
					worker.Version,
					worker.Hostname,
					worker.Uuid,
					worker.Pid,
				)

				modelhelper.DeleteWorker(worker.Uuid)
			}

			if err := iter.Close(); err != nil {
				return err
			}

			return nil
		}

		for _ = range tickerWorker.C {
			mongodb.Run("jKontrolWorkers", queryFunc)
		}
	}()

	// Cleanup dead deployments at intervals. This goroutine will lookup at
	// each information if a deployment has running workers. If workers for a
	// certain deployment is not running anymore, then it will remove the
	// deployment information and all workers associated with that deployment
	// build.
	tickerDeployment := time.NewTicker(time.Hour * 1)
	go func() {
		for _ = range tickerDeployment.C {
			slog.Println("cleaner started to remove unused deployments and dead workers")
			infos := modelhelper.GetClients()
			for _, info := range infos {
				version, _ := strconv.Atoi(info.BuildNumber)

				// look if any workers are running for a certain version
				foundWorker := false
				query := func(c *mgo.Collection) error {
					iter := c.Find(bson.M{"version": version, "status": int(models.Started)}).Iter()
					worker := models.Worker{}
					for iter.Next(&worker) {
						foundWorker = true
					}

					if err := iter.Close(); err != nil {
						return err
					}

					return nil
				}

				mongodb.Run("jKontrolWorkers", query)

				// ... if not remove deployment information and dead workers of that version
				if !foundWorker {
					slog.Printf("removing deployment info for build number %s\n", info.BuildNumber)
					err := modelhelper.DeleteClient(info.BuildNumber)
					if err != nil {
						slog.Println(err)
					}

					slog.Printf("removing dead workers for build number %s\n", info.BuildNumber)
					query := func(c *mgo.Collection) error {
						_, err := c.RemoveAll(bson.M{"version": version, "status": int(models.Dead)})
						return err
					}

					err = mongodb.Run("jKontrolWorkers", query)
					if err != nil {
						slog.Println(err)
					}
				}
			}
		}
	}()
}

func ClientMessage(data amqp.Delivery) {
	if data.RoutingKey == "kontrol-client" {
		var info models.ServerInfo
		err := json.Unmarshal(data.Body, &info)
		if err != nil {
			slog.Printf("bad json client msg: %s err: %s\n", string(data.Body), err)
		}

		modelhelper.AddClient(info)
	}
}

func WorkerMessage(data []byte) {
	var msg IncomingMessage
	err := json.Unmarshal(data, &msg)
	if err != nil {
		slog.Printf("bad json incoming msg: %s err: %s\n", string(data), err)
	}

	if msg.Monitor != nil {
		err := SaveMonitorData(msg.Monitor)
		if err != nil {
			slog.Println(err)
		}
	} else if msg.Worker != nil {
		err = DoWorkerCommand(msg.Worker.Message.Command, *msg.Worker)
		if err != nil {
			slog.Println(err)
		}
	} else {
		slog.Println("incoming message is in wrong format")
	}
}

func ApiMessage(data []byte) {
	var req workerconfig.ApiRequest
	err := json.Unmarshal(data, &req)
	if err != nil {
		slog.Printf("bad json api msg: %s err: %s\n", string(data), err)
	}

	err = DoApiRequest(req.Command, req.Uuid)
	if err != nil {
		slog.Println(err)
	}
}

// DoWorkerCommand is used to handle messages coming from workers.
func DoWorkerCommand(command string, worker models.Worker) error {
	if worker.Uuid == "" {
		fmt.Errorf("worker %s does have an empty uuid", worker.Name)
	}

	switch command {
	case "add", "addWithProxy":
		// This is a large and complex process, handle it seperately.
		// "res" will be send to the worker, it contains the permission result
		res, err := handleAdd(worker)
		if err != nil {
			return err
		}
		go deliver(res)

		// rest is proxy related
		if command != "addWithProxy" {
			return nil
		}

		if worker.Port == 0 { // zero port is useless for proxy
			return fmt.Errorf("register to kontrol proxy not possible. port number is '0' for %s", worker.Name)
		}

		mode := "roundrobin"
		if worker.Name == "broker" {
			mode = "sticky"
		}

		port := strconv.Itoa(worker.Port)
		key := strconv.Itoa(worker.Version)
		err = modelhelper.UpsertKey(
			"koding",    // username
			"",          // persistence, empty means disabled
			mode,        // loadbalancing mode
			worker.Name, // servicename
			key,         // version
			worker.Hostname+":"+port, // host
			"FromKontrolDaemon",      // hostdata
			"",                       // rabbitkey, not used
		)
		if err != nil {
			return fmt.Errorf("register to kontrol proxy not possible: %s", err.Error())
		}
	case "ack":
		err := workerconfig.Ack(worker)
		if err != nil {
			return err
		}
	case "update":
		slog.Printf("[%s (%d)] update request from: '%s' - '%s'\n",
			worker.Name,
			worker.Version,
			worker.Hostname,
			worker.Uuid,
		)
		err := workerconfig.Update(worker)
		if err != nil {
			return err
		}
	default:
		return fmt.Errorf(" command not recognized: %s", command)
	}

	return nil
}

// DoApiRequest is used to make actions on workers. You can kill, delete or
// start any worker with this api.
func DoApiRequest(command, uuid string) error {
	if uuid == "" {
		errors.New("empty uuid is not allowed.")
	}

	slog.Printf("[%s] received: %s\n", uuid, command)
	switch command {
	case "delete":
		err := workerconfig.Delete(uuid)
		if err != nil {
			return err
		}
	case "kill":
		res, err := workerconfig.Kill(uuid, "normal")
		if err != nil {
			slog.Println(err)
		}
		go deliver(res)
	case "start":
		res, err := workerconfig.Start(uuid)
		if err != nil {
			slog.Println(err)
		}
		go deliver(res)
	default:
		return fmt.Errorf(" command not recognized: %s", command)
	}
	return nil
}

func SaveMonitorData(data *models.Monitor) error {
	worker, err := modelhelper.GetWorker(data.Uuid)
	if err != nil {
		return fmt.Errorf("monitor data error '%s'", err)
	}

	worker.Monitor.Mem = *data.Mem
	worker.Monitor.Uptime = data.Uptime
	modelhelper.UpdateWorker(worker)
	return nil
}

func handleAdd(worker models.Worker) (workerconfig.WorkerResponse, error) {
	option := worker.Message.Option

	switch option {
	case "force":
		// force mode immediately run the worker, however before it will run,
		// it tries to find all workers with the same name(foo and foo-1 counts
		// as the same) on other host's. Basically 'force' mode makes the
		// worker exclusive on all machines and no other worker with the same
		// name can run anymore.
		slog.Printf("[%s (%d)] killing all other workers except hostname '%s'\n",
			worker.Name, worker.Version, worker.Hostname)

		result := models.Worker{}
		query := func(c *mgo.Collection) error {
			iter := c.Find(bson.M{
				"name": bson.RegEx{Pattern: "^" + normalizeName(worker.Name),
					Options: "i"},
				"hostname": bson.M{"$ne": worker.Hostname},
			}).Iter()
			for iter.Next(&result) {
				res, err := workerconfig.Kill(result.Uuid, "force")
				if err != nil {
					slog.Println(err)
				}
				go deliver(res)

				err = workerconfig.Delete(result.Uuid)
				if err != nil {
					slog.Println(err)
				}
			}

			return nil

		}

		mongodb.Run("jKontrolWorkers", query)

		startLog := fmt.Sprintf("[%s (%d) - (%s)] starting at '%s' - '%s'\n",
			worker.Name,
			worker.Version,
			option,
			worker.Hostname,
			worker.Uuid,
		)
		slog.Println(startLog)

		worker.Status = models.Started
		worker.ObjectId = bson.NewObjectId()
		modelhelper.UpsertWorker(worker)

		response := *workerconfig.NewWorkerResponse(
			worker.Name,
			worker.Uuid,
			"start",
			startLog,
		)
		return response, nil
	case "one", "version":
		query := bson.M{}
		reason := ""

		// one means that only one single instance of the worker can work. For
		// example if we start an emailWorker with the mode "one", another
		// emailWorker don't get the permission to run.
		if option == "one" {
			query = bson.M{
				"name":   worker.Name,
				"status": bson.M{"$in": []int{int(models.Started), int(models.Waiting)}},
			}

			reason = "startMode is 'one'. workers with same name is runnning on other machines"
		}

		// version is like one, but it's allow only workers of the same name
		// and version. For example if an authWorker of version 13 starts with
		// the mode "version", than only authWorkers of version 13 can start,
		// any other authworker different than 13 (say, 10, 14, ...) don't get
		// the permission to run.
		if option == "version" {
			query = bson.M{
				"name": bson.RegEx{Pattern: "^" + normalizeName(worker.Name),
					Options: "i"},
				"version": bson.M{"$ne": worker.Version},
				"status":  bson.M{"$in": []int{int(models.Started), int(models.Waiting)}},
			}

			reason = "startMode is 'version'. worker with a different version is already running."
		}

		worker.ObjectId = bson.NewObjectId()
		worker.Status = models.Started

		// If the query above for 'one' and 'version' doesn't match anything,
		// then add our new worker. Apply() is atomic and uses findAndModify.
		// Adding it causes no err, therefore the worker get 'start' message.
		// However if the query matches, then the 'upsert' will fail (means
		// that there is some workers that are running).
		change := mgo.Change{
			Update: worker,
			Upsert: true,
		}

		result := models.Worker{}
		err := mongodb.Run("jKontrolWorkers", func(c *mgo.Collection) error {
			_, err := c.Find(query).Apply(change, &result)
			return err
		})

		if err == nil {
			startLog := fmt.Sprintf("[%s (%d) - (%s)] starting at '%s' - '%s'\n",
				worker.Name, worker.Version, option, worker.Hostname, worker.Uuid)

			slog.Println(startLog)
			response := *workerconfig.NewWorkerResponse(worker.Name, worker.Uuid, "start", startLog)
			return response, nil
		}

		denyLog := fmt.Sprintf("[%s (%d)] denied at '%s'. reason: %s",
			worker.Name, worker.Version, worker.Hostname, reason)

		response := *workerconfig.NewWorkerResponse(worker.Name, worker.Uuid, "noPermission", denyLog)
		return response, nil // contains start or noPermission

	case "many":
		// many just starts the worker. That means a worker can be started as
		// many times as we wished with this option.
		startLog := fmt.Sprintf("[%s (%d) - (%s)] starting at '%s' - '%s'",
			worker.Name,
			worker.Version,
			option,
			worker.Hostname,
			worker.Uuid,
		)
		slog.Println(startLog)

		worker.ObjectId = bson.NewObjectId()
		worker.Status = models.Started
		worker.Timestamp = time.Now().Add(workerconfig.HEARTBEAT_INTERVAL)
		modelhelper.UpsertWorker(worker)

		response := *workerconfig.NewWorkerResponse(
			worker.Name,
			worker.Uuid,
			"start",
			startLog,
		)
		return response, nil //
	default:
		return workerconfig.WorkerResponse{},
			errors.New("no option specified for add action. aborting add handler...")
	}

	return workerconfig.WorkerResponse{}, errors.New("couldn't add any worker")

}

func deliver(res workerconfig.WorkerResponse) {
	data, err := json.Marshal(res)
	if err != nil {
		slog.Printf("could not marshall worker: %s", err)
	}

	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
		Priority:        0, // 0-9
	}

	if res.Uuid == "" {
		slog.Printf("can't send to worker. appId is missing")
	}
	workerOut := "output.worker." + res.Uuid
	err = producer.Channel.Publish("workerExchange", workerOut, false, false, msg)
	if err != nil {
		slog.Printf("error while publishing message: %s", err)
	}
}

// convert foo-1, foo-*, etc to foo
func normalizeName(name string) string {
	if counts := strings.Count(name, "-"); counts > 0 {
		return strings.Split(name, "-")[0]
	}
	return name
}
