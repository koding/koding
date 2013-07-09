package handler

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/streadway/amqp"
	"koding/kontrol/kontroldaemon/clientconfig"
	"koding/kontrol/kontroldaemon/workerconfig"
	"koding/kontrol/kontrolhelper"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"labix.org/v2/mgo/bson"
	"log"
	"os"
	"strconv"
	"strings"
	"time"
)

type IncomingMessage struct {
	Worker  *workerconfig.Worker
	Monitor *workerconfig.Monitor
}

var kontrolDB *workerconfig.WorkerConfig
var proxyDB *proxyconfig.ProxyConfiguration
var clientDB *clientconfig.ClientConfig
var producer *kontrolhelper.Producer

func init() {
	log.SetPrefix(fmt.Sprintf("kontrold [%5d] ", os.Getpid()))
}

func Startup() {
	var err error
	producer, err = kontrolhelper.CreateProducer("worker")
	if err != nil {
		log.Println(err)
	}

	err = producer.Channel.ExchangeDeclare("clientExchange", "fanout", true, false, false, false, nil)
	if err != nil {
		log.Printf("clientExchange exchange.declare: %s", err)
	}

	kontrolDB, err = workerconfig.Connect()
	if err != nil {
		log.Fatalf("workerconfig mongodb connect: %s", err)
	}

	clientDB, err = clientconfig.Connect()
	if err != nil {
		log.Fatalf("clientconfig mongodb connect: %s", err)
	}

	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	runHelperFunctions()

	log.Println("kontrold handler is initialized")
}

// runHelperFunctions contains several indepenendent helper functions that do
// certain tasks.
func runHelperFunctions() {
	// cleanup death workers from the the DB at certain intervals
	ticker := time.NewTicker(time.Minute * 20)
	go func() {
		for _ = range ticker.C {
			log.Println("cleanup death workers")
			iter := kontrolDB.Collection.Find(bson.M{"status": int(workerconfig.Dead)}).Iter()
			result := workerconfig.Worker{}
			for iter.Next(&result) {
				// If it's still death just remove it
				if result.Timestamp.Add(time.Minute * 2).Before(time.Now().UTC()) {
					log.Printf("removing death worker '%s - %s - %d'", result.Name, result.Hostname, result.Version)
					kontrolDB.DeleteWorker(result.Uuid)
				}
			}
		}
	}()

	// update workers status
	tickerWorker := time.NewTicker(time.Second * 1)
	go func() {
		for _ = range tickerWorker.C {
			err := kontrolDB.RefreshStatusAll()
			if err != nil {
				log.Println("couldn't update worker data", err)
			}
		}
	}()

	// cleanup death deployments at intervals
	tickerDeployment := time.NewTicker(time.Hour * 12)
	go func() {
		for _ = range tickerDeployment.C {
			log.Println("starting to remove unused deployments")
			infos := clientDB.GetClients()
			for _, info := range infos {
				version, _ := strconv.Atoi(info.BuildNumber)

				iter := kontrolDB.Collection.Find(bson.M{"version": version}).Iter()
				worker := workerconfig.Worker{}
				foundWorker := false

				for iter.Next(&worker) {
					foundWorker = true
				}

				// remove deployment if no workers are available
				if !foundWorker {
					log.Printf("removing deployment with build number %s\n", info.BuildNumber)
					err := clientDB.DeleteClient(info.BuildNumber)
					if err != nil {
						log.Println(err)
					}
				}
			}
		}
	}()
}

func ClientMessage(data amqp.Delivery) {
	if data.RoutingKey == "kontrol-client" {
		var info clientconfig.ServerInfo
		err := json.Unmarshal(data.Body, &info)
		if err != nil {
			log.Print("bad json client msg: ", err)
		}

		clientDB.AddClient(info)
	}
}

func WorkerMessage(data []byte) {
	var msg IncomingMessage
	err := json.Unmarshal(data, &msg)
	if err != nil {
		log.Print("bad json incoming msg: ", err)
	}

	if msg.Monitor != nil {
		err := SaveMonitorData(msg.Monitor)
		if err != nil {
			log.Println(err)
		}
	} else if msg.Worker != nil {
		err = DoWorkerCommand(msg.Worker.Message.Command, *msg.Worker)
		if err != nil {
			log.Println(err)
		}
	} else {
		log.Println("incoming message is in wrong format")
	}
}

func ApiMessage(data []byte) {
	var req workerconfig.ApiRequest
	err := json.Unmarshal(data, &req)
	if err != nil {
		log.Print("bad json incoming msg: ", err)
	}

	err = DoApiRequest(req.Command, req.Uuid)
	if err != nil {
		log.Println(err)
	}
}

// DoWorkerCommand is used to handle messages coming from workers.
func DoWorkerCommand(command string, worker workerconfig.Worker) error {
	if worker.Uuid == "" {
		fmt.Errorf("worker %s does have an empty uuid", worker.Name)
	}

	switch command {
	case "add", "addWithProxy":
		log.Printf("[%s (%d)] received: %s - %s ", worker.Name, worker.Version, command, worker.Message.Option)
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
		err = proxyDB.UpsertKey(
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
		err := kontrolDB.Ack(worker)
		if err != nil {
			return err
		}
	case "update":
		log.Printf("[%s (%d)] received: %s", worker.Name, worker.Version, command)
		err := kontrolDB.Update(worker)
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
	log.Printf("[%s] received: %s", uuid, command)
	switch command {
	case "delete":
		err := kontrolDB.Delete(uuid)
		if err != nil {
			return err
		}
	case "kill":
		res, err := kontrolDB.Kill(uuid, "normal")
		if err != nil {
			log.Println(err)
		}
		go deliver(res)
	case "start":
		res, err := kontrolDB.Start(uuid)
		if err != nil {
			log.Println(err)
		}
		go deliver(res)
	default:
		return fmt.Errorf(" command not recognized: %s", command)
	}
	return nil
}

func SaveMonitorData(data *workerconfig.Monitor) error {
	worker, err := kontrolDB.GetWorker(data.Uuid)
	if err != nil {
		return fmt.Errorf("monitor data error '%s'", err)
	}

	worker.Monitor.Mem = *data.Mem
	worker.Monitor.Uptime = data.Uptime
	kontrolDB.UpdateWorker(worker)
	return nil
}

func handleAdd(worker workerconfig.Worker) (workerconfig.WorkerResponse, error) {
	option := worker.Message.Option

	switch option {
	case "force":
		/* force mode immediately run the worker, however before it will run,
		it tries to find all workers with the same name(foo and foo-1
		counts as the same) on other host's. Basically 'force' mode makes
		the worker exclusive on all machines and no other worker with the
		same name can run anymore.  */
		log.Printf("[%s (%d)] killing all other workers except hostname '%s'\n", worker.Name, worker.Version, worker.Hostname)
		result := workerconfig.Worker{}
		iter := kontrolDB.Collection.Find(bson.M{
			"name":     bson.RegEx{Pattern: "^" + normalizeName(worker.Name), Options: "i"},
			"hostname": bson.M{"$ne": worker.Hostname},
		}).Iter()

		for iter.Next(&result) {
			res, err := kontrolDB.Kill(result.Uuid, "force")
			if err != nil {
				log.Println(err)
			}
			go deliver(res)

			err = kontrolDB.Delete(result.Uuid)
			if err != nil {
				log.Println(err)
			}
		}

		log.Printf("[%s (%d)] starting at '%s'", worker.Name, worker.Version, worker.Hostname)
		worker.Status = workerconfig.Started
		kontrolDB.AddWorker(worker)

		response := *workerconfig.NewWorkerResponse(worker.Name, worker.Uuid, "add")
		return response, nil
	case "one", "version":
		/* one mode will try to start a worker that has a different version
		than the current available workers. But before it starts it look for
		other workers. If there is worker available that are already started
		with a different version then the worker don't get any permission. If
		not it get's the permission to run.
		Basically 'one' mode makes the worker 'version' exclusive. That means
		only workers with that exclusive version has the permission to run.  */

		query := bson.M{}
		reason := ""
		if option == "version" {
			query = bson.M{
				"name":    bson.RegEx{Pattern: "^" + normalizeName(worker.Name), Options: "i"},
				"version": bson.M{"$ne": worker.Version},
				"status": bson.M{"$in": []int{
					int(workerconfig.Started),
					int(workerconfig.Waiting),
				}}}
			reason = "workers with different versions: "
		}

		if option == "one" {
			query = bson.M{
				"name": worker.Name,
				"status": bson.M{"$in": []int{
					int(workerconfig.Started),
					int(workerconfig.Waiting),
				}}}
			reason = "workers with same names: "
		}

		result := workerconfig.Worker{}
		otherWorkers := false
		iter := kontrolDB.Collection.Find(query).Iter()
		for iter.Next(&result) {
			reason = reason + fmt.Sprintf("\n version: %d (pid: %d) at %s", result.Version, result.Pid, result.Hostname)
			otherWorkers = true
		}

		if !otherWorkers {
			log.Printf("[%s (%d)] starting at '%s'", worker.Name, worker.Version, worker.Hostname)
			worker.Status = workerconfig.Started
			kontrolDB.AddWorker(worker)
			response := *workerconfig.NewWorkerResponse(worker.Name, worker.Uuid, "add")
			return response, nil
		}

		log.Printf("[%s (%d)] denied at '%s'. reason: %s", worker.Name, worker.Version, worker.Hostname, reason)
		response := *workerconfig.NewWorkerResponse(worker.Name, worker.Uuid, "added.before")
		return response, nil // contains first.start or added.before
	case "many":
		log.Printf("[%s (%d)] starting at '%s'", worker.Name, worker.Version, worker.Hostname)
		worker.Status = workerconfig.Started
		kontrolDB.AddWorker(worker)
		response := *workerconfig.NewWorkerResponse(worker.Name, worker.Uuid, "first.start")
		return response, nil //
	default:
		return workerconfig.WorkerResponse{}, errors.New("no option specified for add action. aborting add handler...")
	}

	return workerconfig.WorkerResponse{}, errors.New("couldn't add any worker")

}

func deliver(res workerconfig.WorkerResponse) {
	data, err := json.Marshal(res)
	if err != nil {
		log.Printf("could not marshall worker: %s", err)
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
		log.Printf("can't send to worker. appId is missing")
	}
	workerOut := "output.worker." + res.Uuid
	err = producer.Channel.Publish("workerExchange", workerOut, false, false, msg)
	if err != nil {
		log.Printf("error while publishing message: %s", err)
	}
	// log.Println("SENDING WORKER data ", string(data))
}

// convert foo-1, foo-*, etc to foo
func normalizeName(name string) string {
	if counts := strings.Count(name, "-"); counts > 0 {
		return strings.Split(name, "-")[0]
	}
	return name
}
