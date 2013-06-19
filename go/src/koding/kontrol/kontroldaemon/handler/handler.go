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

	// cleanup death workers at intervals
	ticker := time.NewTicker(time.Hour * 1)
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

	// update workers
	tickerWorker := time.NewTicker(time.Second * 1)
	go func() {
		for _ = range tickerWorker.C {
			err := kontrolDB.RefreshStatusAll()
			if err != nil {
				log.Println("couldn't update worker data", err)
			}
		}
	}()

	log.Println("kontrold handler plugin is initialized")
}

func HandleClientMessage(data amqp.Delivery) {
	if data.RoutingKey == "kontrol-client" {
		var info clientconfig.ServerInfo
		err := json.Unmarshal(data.Body, &info)
		if err != nil {
			log.Print("bad json client msg: ", err)
		}

		clientDB.AddClient(info)
	}
}

func HandleWorkerMessage(data []byte) {
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

func HandleApiMessage(data []byte) {
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

func DoWorkerCommand(command string, worker workerconfig.Worker) error {
	switch command {
	case "add", "addWithProxy":
		log.Printf("ACTION RECEIVED: --  %s  --", command)
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

		loadBalance := "roundrobin"
		if worker.Name == "broker" {
			loadBalance = "sticky"
		}

		port := strconv.Itoa(worker.Port)
		key := strconv.Itoa(worker.Version)
		err = proxyDB.UpsertKey(
			"koding",    // username
			loadBalance, // loadbalancing mode
			worker.Name, // servicename
			key,         // version
			worker.Hostname+":"+port, // host
			"FromKontrolDaemon",      // hostdata
			"",                       // rabbitkey, not used
			0,                        // currentindex, not used
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
		log.Printf("ACTION RECEIVED: --  %s  --", command)
		err := kontrolDB.Update(worker)
		if err != nil {
			return err
		}
	default:
		return fmt.Errorf(" command not recognized: %s", command)
	}

	return nil
}

func DoApiRequest(command, uuid string) error {
	log.Printf("ACTION RECEIVED: --  %s  --", command)
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
		log.Printf("force kill all workers with name '%s' and not hostname '%s'\n", worker.Name, worker.Hostname)
		result := workerconfig.Worker{}
		iter := kontrolDB.Collection.Find(bson.M{
			"name":     worker.Name,
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

		log.Printf("start our new worker '%s' with version %d and pid: '%d'\n", worker.Name, worker.Version, worker.Pid)

		worker.Status = workerconfig.Running
		kontrolDB.AddWorker(worker)

		response := *workerconfig.NewWorkerResponse(worker.Name, worker.Uuid, "add")
		return response, nil
	case "one":
		var command string
		otherWorkers := false
		result := workerconfig.Worker{}
		iter := kontrolDB.Collection.Find(bson.M{
			"name":    worker.Name,
			"version": bson.M{"$ne": worker.Version},
		}).Iter()
		for iter.Next(&result) {
			otherWorkers = true
		}

		if !otherWorkers {
			log.Printf("adding worker '%s' - '%s' - '%d'", worker.Name, worker.Hostname, worker.Version)
			worker.Status = workerconfig.Running
			kontrolDB.AddWorker(worker)
			response := *workerconfig.NewWorkerResponse(worker.Name, worker.Uuid, "add")
			return response, nil
		}

		log.Printf("worker '%s' is already registered. checking for status...", worker.Name)
		err := kontrolDB.RefreshStatusAll()
		if err != nil {
			log.Println("couldn't refresh data", err)
		}

		iter = kontrolDB.Collection.Find(bson.M{
			"name":    worker.Name,
			"version": bson.M{"$ne": worker.Version},
			"status": bson.M{"$in": []int{
				int(workerconfig.Notstarted),
				int(workerconfig.Killed),
				int(workerconfig.Dead),
			}}}).Iter()

		var gotPermission bool = false
		result = workerconfig.Worker{}
		for iter.Next(&result) {
			kontrolDB.DeleteWorker(result.Uuid)

			log.Printf("worker '%s' is not alive anymore. permission grant to run for the new worker", worker.Name)
			log.Printf("adding worker '%s' - '%s' - '%d'", worker.Name, worker.Hostname, worker.Version)

			worker.Status = workerconfig.Running
			kontrolDB.AddWorker(worker)
			command = "first.start"
			gotPermission = true
		}

		if !gotPermission {
			log.Printf("another worker other then version '%d' is already running.", worker.Version)
			log.Printf("no permission to worker '%s' on hostname '%s'", worker.Name, worker.Hostname)
			command = "added.before"
		}

		response := *workerconfig.NewWorkerResponse(worker.Name, worker.Uuid, command)
		return response, nil // contains first.start or added.before
	case "many":
		log.Printf("adding worker '%s' - '%s' - '%d'", worker.Name, worker.Hostname, worker.Version)
		worker.Status = workerconfig.Running
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
