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
	"koding/tools/config"
	"labix.org/v2/mgo/bson"
	"log"
	"strconv"
	"time"
)

type cliRequest struct {
	workerconfig.Request
	Data string `json:"data"`
}

type IncomingMessage struct {
	Worker  *workerconfig.MsgWorker
	Monitor *workerconfig.Monitor
}

type ApiMessage struct {
	Worker *workerconfig.Request
	Cli    *cliRequest
}

var kontrolConfig *workerconfig.WorkerConfig
var proxyDB *proxyconfig.ProxyConfiguration
var clientDB *clientconfig.ClientConfig

var workerProducer *kontrolhelper.Producer
var cliProducer *kontrolhelper.Producer
var apiProducer *kontrolhelper.Producer
var clientProducer *kontrolhelper.Producer

func init() {
	log.SetPrefix("kontrol-daemonhandler ")
}

func Startup() {
	var err error
	workerProducer, err = kontrolhelper.CreateProducer("worker")
	if err != nil {
		log.Println(err)
	}

	cliProducer, err = kontrolhelper.CreateProducer("cli")
	if err != nil {
		log.Println(err)
	}

	apiProducer, err = kontrolhelper.CreateProducer("api")
	if err != nil {
		log.Println(err)
	}

	clientProducer, err = kontrolhelper.CreateProducer("client")
	if err != nil {
		log.Println(err)
	}

	err = clientProducer.Channel.ExchangeDeclare("clientExchange", "fanout", true, false, false, false, nil)
	if err != nil {
		log.Printf("Supervisor: worker exchange.declare: %s", err)
	}

	kontrolConfig, err = workerconfig.Connect()
	if err != nil {
		log.Fatalf("wokerconfig mongodb connect: %s", err)
	}

	clientDB, err = clientconfig.Connect()
	if err != nil {
		log.Fatalf("wokerconfig mongodb connect: %s", err)
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
			iter := kontrolConfig.Collection.Find(bson.M{"status": int(workerconfig.Dead)}).Iter()
			result := workerconfig.MsgWorker{}
			for iter.Next(&result) {
				// If it's still death just remove it
				if result.Timestamp.Add(time.Minute * 2).Before(time.Now().UTC()) {
					log.Printf("removing death worker '%s - %s - %s'", result.Name, result.Hostname, result.Uuid)
					kontrolConfig.DeleteWorker(result.Uuid)
				}
			}
		}
	}()

	// update workers
	tickerWorker := time.NewTicker(time.Second * 1)
	go func() {
		for _ = range tickerWorker.C {
			err := kontrolConfig.RefreshStatusAll()
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
		err = DoAction(msg.Worker.Message.Command, msg.Worker.Message.Option, *msg.Worker)
		if err != nil {
			log.Println(err)
		}
	} else {
		log.Println("incoming message is in wrong format")
	}

}

func HandleApiMessage(data []byte, appId string) {
	var msg ApiMessage
	err := json.Unmarshal(data, &msg)
	if err != nil {
		log.Print("bad json incoming msg: ", err)
	}

	if msg.Worker != nil {
		err = DoRequest(msg.Worker.Command, msg.Worker.Hostname, msg.Worker.Uuid, "", appId)
		if err != nil {
			log.Println(err)
		}
	} else if msg.Cli != nil {
		err = DoRequest(msg.Cli.Command, msg.Cli.Hostname, msg.Cli.Uuid, msg.Cli.Data, appId)
		if err != nil {
			log.Println(err)
		}
	} else {
		log.Println("incoming api message is in wrong format")
	}
}

func DoAction(command, option string, worker workerconfig.MsgWorker) error {
	if command == "" {
		return errors.New(" empty command, nothing to do")
	}

	if command == "add" || command == "addWithProxy" {
		log.Printf("ACTION RECEIVED: --  %s  --", command)
		// This is a large and complex process, handle it seperately.
		// "res" will be send to the worker, it contains the permission result
		res, err := handleAdd(worker)
		if err != nil {
			return err
		}
		go sendWorker(res)

		// register to kontrol proxy
		if command != "addWithProxy" {
			return nil
		}

		if worker.Port == 0 { // but not if it has port of 0
			return fmt.Errorf("register to kontrol proxy not possible. port number is '0' for %s", worker.Name)
		}

		port := strconv.Itoa(worker.Port)
		key := strconv.Itoa(worker.Version)
		err = proxyDB.AddKey(
			"koding",
			worker.Name, //service name
			key,
			worker.Hostname+":"+port, // host
			"FromKontrolDaemon",
			"",
		)
		if err != nil {
			return fmt.Errorf("register to kontrol proxy not possible: %s", err.Error())
		}

		return nil
	}

	if isEmpty, err := kontrolConfig.IsEmpty(); isEmpty {
		return fmt.Errorf(" do action: %s", err.Error())
	}

	actions := map[string]func(worker workerconfig.MsgWorker) error{
		"ack":    func(worker workerconfig.MsgWorker) error { return kontrolConfig.Ack(worker) },
		"update": func(worker workerconfig.MsgWorker) error { return kontrolConfig.Update(worker) },
	}

	if _, ok := actions[command]; !ok {
		return fmt.Errorf(" command not recognized: %s", command)
	}

	if config.Verbose && command != "ack" {
		log.Printf("ACTION RECEIVED: --  %s  --", command)
	}

	err := actions[command](worker)
	if err != nil {
		return err
	}

	return nil
}

func DoRequest(command, hostname, uuid, data, appId string) error {
	if command == "" {
		return errors.New("empty command, nothing to do")
	}

	if isEmpty, err := kontrolConfig.IsEmpty(); isEmpty {
		return fmt.Errorf("do request %s", err.Error())
	}

	log.Printf("ACTION RECEIVED: --  %s  --", command)

	if command == "cmd" {
		req := buildReq("start", data, hostname, 0)
		go deliver(req, clientProducer, "")
		return nil
	}

	if command == "status" {
		res, err := kontrolConfig.Status(hostname, uuid)
		if err != nil {
			log.Println(err)
		}

		response, err := json.Marshal(res)
		if appId == "" {
			go deliver(response, apiProducer, "")
		} else {
			go deliver(response, cliProducer, appId)
		}
		return nil
	}

	if command == "delete" {
		result := workerconfig.MsgWorker{}
		if hostname == "" && uuid == "" {
			// Apply action to all workers
			log.Printf("'%s' all workers", command)
			iter := kontrolConfig.Collection.Find(nil).Iter()
			for iter.Next(&result) {
				err := killAndDelete(result.Hostname, result.Uuid)
				if err != nil {
					return err
				}
			}
			return nil
		} else if hostname != "" && uuid == "" {
			// Apply action on all workers on the hostname
			log.Printf("'%s' all workers on the hostname '%s'", command, hostname)
			iter := kontrolConfig.Collection.Find(bson.M{"hostname": hostname}).Iter()
			for iter.Next(&result) {
				err := killAndDelete(result.Hostname, result.Uuid)
				if err != nil {
					return err
				}
			}
			return nil
		}

		err := killAndDelete(hostname, uuid)
		if err != nil {
			return err
		}
		return nil
	}

	actions := map[string]func(hostname, uuid string) (workerconfig.MsgWorker, error){
		"kill": func(hostname, uuid string) (workerconfig.MsgWorker, error) {
			return kontrolConfig.Kill(hostname, uuid)
		},
		"stop": func(hostname, uuid string) (workerconfig.MsgWorker, error) {
			return kontrolConfig.Stop(hostname, uuid)
		},
		"start": func(hostname, uuid string) (workerconfig.MsgWorker, error) {
			return kontrolConfig.Start(hostname, uuid)
		},
	}

	if _, ok := actions[command]; !ok {
		return fmt.Errorf("command not recognized: %s", command)
	}

	result := workerconfig.MsgWorker{}
	if hostname == "" && uuid == "" {
		// Apply action to all workers
		log.Printf("'%s' all workers", command)
		iter := kontrolConfig.Collection.Find(nil).Iter()
		for iter.Next(&result) {
			res, err := actions[command](result.Hostname, result.Uuid)
			if err != nil {
				log.Println(err)
			}
			go sendWorker(res)
		}
	} else if hostname != "" && uuid == "" {
		// Apply action on all workers on the hostname
		log.Printf("'%s' all workers on the hostname '%s'", command, hostname)
		iter := kontrolConfig.Collection.Find(bson.M{"hostname": hostname}).Iter()
		for iter.Next(&result) {
			res, err := actions[command](result.Hostname, result.Uuid)
			if err != nil {
				log.Println(err)
			}
			go sendWorker(res)
		}
	} else if uuid != "" {
		// Apply action on single worker, hostname is just for backward compatibility
		workerResult, err := kontrolConfig.GetWorker(uuid)
		if err != nil {
			return fmt.Errorf("dorequest method error '%s'", err)
		}

		if hostname == "" {
			hostname = workerResult.Hostname
		}

		if command != "ack" {
			log.Printf(" '%s' worker '%s' on host '%s'", command, workerResult.Name, hostname)
		}

		res, err := actions[command](hostname, workerResult.Uuid)
		if err != nil {
			return err
		}
		go sendWorker(res)
	}

	return nil
}

func killAndDelete(hostname, uuid string) error {
	// Kill the worker for preventing him sending messages to us
	res, err := kontrolConfig.Kill(hostname, uuid)
	if err != nil {
		log.Println(err)
	}
	go sendWorker(res)

	err = kontrolConfig.Delete(hostname, uuid)
	if err != nil {
		return err
	}
	return nil

}

func SaveMonitorData(data *workerconfig.Monitor) error {
	workerResult, err := kontrolConfig.GetWorker(data.Uuid)
	if err != nil {
		return fmt.Errorf("monitor data error '%s'", err)
	}

	workerResult.Monitor.Mem = *data.Mem
	workerResult.Monitor.Uptime = data.Uptime
	kontrolConfig.UpdateWorker(workerResult)
	return nil
}

func handleAdd(worker workerconfig.MsgWorker) (workerconfig.MsgWorker, error) {
	option := worker.Message.Option

	switch option {
	case "force":
		log.Println("force option is enabled.")

		// First kill and delete all alive workers for the same name type.
		log.Printf("trying to kill and delete all workers with the name '%s' on the hostname '%s'", worker.Name, worker.Hostname)

		iter := kontrolConfig.Collection.Find(bson.M{"name": worker.Name}).Iter()
		result := workerconfig.MsgWorker{}
		for iter.Next(&result) {
			err := killAndDelete(result.Hostname, result.Uuid)
			if err != nil {
				log.Println(err)
			}
		}

		// kontrolConfig.AddWorker(worker)
		worker.Message.Result = "added.now"
		worker.Status = workerconfig.Running
		log.Println("start our new worker")
		log.Printf("'add' worker '%s' with pid: '%d'", worker.Name, worker.Pid)
		kontrolConfig.AddWorker(worker)

		return worker, nil
	case "one":
		availableWorkers := kontrolConfig.NumberOfWorker(worker.Name, worker.Hostname)
		if availableWorkers < 1 {
			log.Printf("adding worker '%s' - '%s' - '%s'", worker.Name, worker.Hostname, worker.Uuid)
			worker.Message.Result = "added.now"
			worker.Status = workerconfig.Running
			kontrolConfig.AddWorker(worker)
			return worker, nil
		}

		log.Printf("worker '%s' is already registered. checking for status...", worker.Name)
		err := kontrolConfig.RefreshStatusAll()
		if err != nil {
			log.Println("couldn't refresh data", err)
		}

		iter := kontrolConfig.Collection.Find(bson.M{
			"name":     worker.Name,
			"hostname": worker.Hostname,
			"status": bson.M{"$in": []int{
				int(workerconfig.Notstarted),
				int(workerconfig.Killed),
				int(workerconfig.Dead),
			}}}).Iter()

		var gotPermission bool = false

		result := workerconfig.MsgWorker{}
		for iter.Next(&result) {
			kontrolConfig.DeleteWorker(result.Uuid)

			log.Printf("worker '%s' is not alive anymore. permission grant to run for the new worker", worker.Name)
			log.Printf("adding worker '%s' - '%s' - '%s'", worker.Name, worker.Hostname, worker.Uuid)

			worker.Message.Result = "first.start"
			worker.Status = workerconfig.Running

			kontrolConfig.AddWorker(worker)
			gotPermission = true
		}

		if !gotPermission {
			log.Printf("another worker is already running. no permission to worker '%s' on hostname '%s'", worker.Name, worker.Hostname)
			worker.Message.Result = "added.before"
		}

		return worker, nil // contains first.start or added.before
	case "many":
		log.Printf("adding worker '%s' - '%s' - '%s'", worker.Name, worker.Hostname, worker.Uuid)
		worker.Message.Result = "first.start"
		worker.Status = workerconfig.Running
		kontrolConfig.AddWorker(worker)
		return worker, nil //
	default:
		return worker, errors.New("no option specified for add action. aborting add handler...")
	}

	return worker, errors.New("couldn't add any worker")

}

func sendWorker(res workerconfig.MsgWorker) {
	workerJson, err := json.Marshal(res)
	if err != nil {
		log.Printf("could not marshall worker: %s", err)
	}

	go deliver(workerJson, workerProducer, res.Uuid)
	return
}

func deliver(data []byte, producer *kontrolhelper.Producer, appId string) {
	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
		Priority:        0, // 0-9
	}

	switch producer.Name {
	case "cli":
		if appId == "" {
			log.Printf(" Can't send to cli. appId is missing")
		}
		cliOut := "output.cli." + appId
		err := cliProducer.Channel.Publish("infoExchange", cliOut, false, false, msg)
		if err != nil {
			log.Printf("error while publishing cli message: %s", err)
		}
	case "client":
		err := clientProducer.Channel.Publish("clientExchange", "", false, false, msg)
		if err != nil {
			log.Printf("error while publishing client message: %s", err)
		}
		if config.Verbose {
			log.Printf("SENDING CLIENT data %s", string(data))
		}
	case "api":
		err := apiProducer.Channel.Publish("infoExchange", "output.api", false, false, msg)
		if err != nil {
			log.Printf("error while publishing api message: %s", err)
		}
		if config.Verbose {
			log.Println("SENDING API data ", string(data))
		}
	case "worker":
		if appId == "" {
			log.Printf("can't send to worker. appId is missing")
		}
		workerOut := "output.worker." + appId
		err := workerProducer.Channel.Publish("workerExchange", workerOut, false, false, msg)
		if err != nil {
			log.Printf("error while publishing message: %s", err)
		}
	}
}

func buildReq(action, cmd, hostname string, pid int) []byte {
	req := workerconfig.ClientRequest{Action: action, Cmd: cmd, Hostname: hostname, Pid: pid}
	log.Println("Sending cmd to kontrold-client:", req)

	data, err := json.Marshal(req)
	if err != nil {
		log.Println("Json marshall error", req)
	}
	return data
}
