package handler

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/streadway/amqp"
	"io/ioutil"
	"koding/fujin/proxyconfig"
	"koding/kontrol/daemon/handler/proxy"
	"koding/kontrol/daemon/workerconfig"
	"koding/tools/amqputil"
	"koding/tools/config"
	"koding/tools/utils"
	"log"
	"os"
	"strconv"
	"strings"
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
	Proxy  *proxyconfig.ProxyMessage
	Cli    *cliRequest
}

type ProcessConfig map[string]ProcessWorker

type ProcessWorker struct {
	Cmd            string           `json:"cmd"`
	Number         int              `json:"number"`
	Host           []string         `json:"host"`
	Version        int              `json:"version"`
	CompatibleWith map[string][]int `json:"compatibleWith"`
}

type Producer struct {
	conn    *amqp.Connection
	channel *amqp.Channel
	name    string
	done    chan error
}

var processConfig ProcessConfig
var kontrolConfig *workerconfig.WorkerConfig
var proxyConfig *proxyconfig.ProxyConfiguration

var workerProducer *Producer
var cliProducer *Producer
var webapiProducer *Producer
var clientProducer *Producer

func init() {
	log.SetPrefix("kontrold-handler ")
}

func NewProducer(name string) *Producer {
	return &Producer{
		conn:    nil,
		channel: nil,
		name:    name,
		done:    make(chan error),
	}
}

func Startup() {
	var err error
	workerProducer, err = createProducer("worker")
	if err != nil {
		log.Println(err)
	}

	cliProducer, err = createProducer("cli")
	if err != nil {
		log.Println(err)
	}

	webapiProducer, err = createProducer("webapi")
	if err != nil {
		log.Println(err)
	}

	clientProducer, err = createProducer("client")
	if err != nil {
		log.Println(err)
	}

	err = clientProducer.channel.ExchangeDeclare("clientExchange", "fanout", true, false, false, false, nil)
	if err != nil {
		log.Printf("Supervisor: worker exchange.declare: %s", err)
	}

	kontrolConfig = workerconfig.NewWorkerConfig()
	kontrolConfig.ReadConfig()

	proxyConfig = proxyconfig.NewProxyConfiguration()
	proxyConfig.ReadConfig()

	var worker workerconfig.MsgWorker

	configFile := "kontrold-process.config.json"
	file, err := ioutil.ReadFile(configFile)
	if err != nil {
		return
	}
	err = json.Unmarshal(file, &processConfig)
	if err != nil {
		log.Print("bad json unmarshalling process config file", err)
		return
	}

	for name, prop := range processConfig {

		if prop.Number == 1 {
			worker.Name = name
			kontrolConfig.RegisteredHosts[name] = prop.Host
		} else {
			// for multiple kontrolConfig we are just creating the first entry. After
			// starting the process our internal config will be updated
			// automatically, no need to create entries for them
			worker.Name = name + "-1"
			worker.Number = prop.Number

			// but for approval we have to setup explicit permission
			for i := 0; i < prop.Number; i++ {
				// i + 1 because names begin index 1, like foo-1, foo-2
				kontrolConfig.RegisteredHosts[name+"-"+strconv.Itoa(i+1)] = prop.Host
			}
		}

		worker.Version = prop.Version
		worker.CompatibleWith = prop.CompatibleWith
		worker.Cmd = prop.Cmd
		worker.Hostname = customHostname()
		worker.Uuid = utils.RandomString()
		worker.Pid = 0
		worker.Status = workerconfig.Notstarted
		worker.Number = prop.Number

		ok, _ := kontrolConfig.IsEmpty()
		if ok {
			kontrolConfig.AddWorker(worker)
		} else {
			ok, _ := kontrolConfig.HasName(worker.Name)
			if !ok {
				kontrolConfig.AddWorker(worker)
			}
			// there are already kontrolConfig in the config file, nothing to do.
		}

		if err := kontrolConfig.SaveToConfig(); err != nil {
			log.Println(err)
		}
	}

	err = kontrolConfig.SaveToConfig()
	if err != nil {
		log.Println(err)
	}

	log.Printf("ready on host %s", kontrolConfig.Hostname)
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
		// from kontrol-api PUT or DELETE /workers/{uuid}/....
		err = DoRequest(msg.Worker.Command, msg.Worker.Hostname, msg.Worker.Uuid, "", appId)
		if err != nil {
			log.Println(err)
		}
	} else if msg.Proxy != nil {
		// from kontrol-api PUT or DELETE /proxies/{uuid}/action}
		proxy.DoProxy(*msg.Proxy)
	} else if msg.Cli != nil {
		// from kontrol-cli directly (TODO: should use kontrol-api instead of communicating with rabbitmq)
		err = DoRequest(msg.Cli.Command, msg.Cli.Hostname, msg.Cli.Uuid, msg.Cli.Data, appId)
		if err != nil {
			log.Println(err)
		}
	} else {
		log.Println("incoming api message is in wrong format")
	}
}

func DoAction(command, option string, worker workerconfig.MsgWorker) error {
	if isEmpty, err := kontrolConfig.IsEmpty(); isEmpty && command != "add" {
		return fmt.Errorf(" do action", err)
	}

	if command == "" {
		return errors.New(" empty command, nothing to do")
	}

	if command == "add" {
		// This is a large and complex process, handle it seperately.
		// "res" will be send to the worker, it contains the permission result
		res, err := handleAdd(worker)
		if err != nil {
			return err
		}

		workerJson, err := json.Marshal(res)
		if err != nil {
			log.Printf("could not marshall worker: %s", err)
		}

		go deliver(workerJson, workerProducer, res.Uuid)

		return nil
	}

	actions := map[string]func(worker workerconfig.MsgWorker) error{
		"ack":    func(worker workerconfig.MsgWorker) error { return kontrolConfig.Ack(worker) },
		"update": func(worker workerconfig.MsgWorker) error { return kontrolConfig.Update(worker) },
	}

	if _, ok := actions[command]; !ok {
		return fmt.Errorf(" command not recognized: ", command)
	}

	if config.Verbose && command != "ack" {
		log.Printf("'%s' worker '%s' with pid: '%d'", command, worker.Name, worker.Pid)
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
		return fmt.Errorf("do request", err)
	}

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
			go deliver(response, webapiProducer, "")
		} else {
			go deliver(response, cliProducer, appId)
		}
		return nil
	}
	if command == "delete" {
		err := kontrolConfig.Delete(hostname, uuid)
		if err != nil {
			return err
		}
		return nil
	}

	actions := map[string]func(hostname, uuid string) (workerconfig.MsgWorker, error){
		"kill": func(hostname, uuid string) (workerconfig.MsgWorker, error) { return kontrolConfig.Kill(hostname, uuid) },
		"stop": func(hostname, uuid string) (workerconfig.MsgWorker, error) { return kontrolConfig.Stop(hostname, uuid) },
		"start": func(hostname, uuid string) (workerconfig.MsgWorker, error) {
			return kontrolConfig.Start(hostname, uuid)
		},
	}

	if _, ok := actions[command]; !ok {
		return fmt.Errorf("command not recognized: ", command)
	}

	if hostname == "" && uuid == "" {
		// Apply action to all workers
		if config.Verbose {
			log.Printf("'%s' all workers", command)
		}
		for _, workerData := range kontrolConfig.RegisteredWorkers {
			res, err := actions[command](workerData.Hostname, workerData.Uuid)
			if err != nil {
				log.Println(err)
			}
			go sendWorker(res)
		}
	} else if hostname != "" && uuid == "" {
		// Apply action on all workers on the hostname
		if config.Verbose {
			log.Printf("'%s' all workers on the hostname '%s'", command, hostname)
		}
		for _, workerData := range kontrolConfig.RegisteredWorkers {
			if workerData.Hostname == hostname {
				res, err := actions[command](hostname, workerData.Uuid)
				if err != nil {
					log.Println(err)
				}
				go sendWorker(res)
			}
		}
	} else if uuid != "" {
		// Apply action on single worker, hostname is just for backward compatibility
		workerRes := kontrolConfig.RegisteredWorkers[uuid]
		if hostname == "" {
			hostname = workerRes.Hostname
		}

		if config.Verbose && command != "ack" {
			log.Printf(" '%s' worker '%s' on host '%s'", command, workerRes.Name, workerRes.Hostname)
		}

		res, err := actions[command](hostname, uuid)
		if err != nil {
			return err
		}
		go sendWorker(res)
	}

	return nil
}

func SaveMonitorData(data *workerconfig.Monitor) error {
	err := kontrolConfig.HasUuid(data.Uuid)
	if err != nil {
		return fmt.Errorf("monitor data error '%s'", err)
	}

	workerResult := kontrolConfig.RegisteredWorkers[data.Uuid]
	workerResult.Monitor.Mem = *data.Mem
	workerResult.Monitor.Uptime = data.Uptime
	kontrolConfig.RegisteredWorkers[data.Uuid] = workerResult
	kontrolConfig.SaveToConfig()

	return nil
}

func handleAdd(worker workerconfig.MsgWorker) (workerconfig.MsgWorker, error) {
	option := worker.Message.Option

	if !kontrolConfig.ApprovedHost(worker.Name, worker.Hostname) {
		worker.Message.Result = "not.allowed"
		return worker, errors.New("Worker is not in approved host before")
	}

	if option == "force" {
		log.Println("force option is enabled.")

		// TODO: Force for the same name on all other hostnames, or just on that hostname?
		//			 If force should be enabled only on the same hostname that us the following line:
		// if workerData.Status != pending && workerData.Name == worker.Name && workerData.Hostname == worker.Hostname {

		// First stop all alive workers for the same name type.
		log.Println("trying to stop and kill all other workers with the same name.")
		for _, workerData := range kontrolConfig.RegisteredWorkers {
			if workerData.Status != workerconfig.Pending && workerData.Name == worker.Name {
				res, err := kontrolConfig.Stop(workerData.Hostname, workerData.Uuid)
				if err != nil {
					log.Println("", err)
				}
				go sendWorker(res)

				res, err = kontrolConfig.Kill(workerData.Hostname, workerData.Uuid)
				if err != nil {
					log.Println("", err)
				}
				go sendWorker(res)

			}
		}

		// Then add the new worker to a buffer, and wait.
		worker.Status = workerconfig.Pending
		kontrolConfig.AddWorker(worker)
		if err := kontrolConfig.SaveToConfig(); err != nil {
			log.Printf(" %s", err)
		}

		lenPendingWorkers := kontrolConfig.NumberOfWorker(worker.Name, worker.Hostname, workerconfig.Pending, true)

		// Until we have all of them. For example if our worker type spawns 4
		// workers then we wait until we have 4 pending workers.

		if lenPendingWorkers == worker.Number {
			// Then delete the old workers (those we stoped and killed above)
			log.Println("trying to delete remaining old workers with the same name.")
			for _, workerData := range kontrolConfig.RegisteredWorkers {
				// Use this as written above if TODO is yes!!
				//if workerData.Message.Result == "killed.now" && workerData.Name == worker.Name && workerData.Hostname == worker.Hostname {
				if workerData.Message.Result == "killed.now" && workerData.Name == worker.Name {
					kontrolConfig.DeleteWorker(workerData.Uuid)
				}
			}

			log.Println("trying to start new worker.")
			// and add our new workers (which means we are starting them)
			for _, workerData := range kontrolConfig.RegisteredWorkers {
				//if workerData.Status == pending && workerData.Name == worker.Name && workerData.Hostname == workerData.Hostname {
				if workerData.Status == workerconfig.Pending && workerData.Name == worker.Name {
					workerData.Message.Result = "added.now"
					workerData.Status = workerconfig.Running
					log.Println("start our new worker")
					log.Printf("'add' worker '%s' with pid: '%d'", workerData.Name, workerData.Pid)
					kontrolConfig.AddWorker(workerData)
					if err := kontrolConfig.SaveToConfig(); err != nil {
						log.Printf(" %s", err)
					}

					return workerData, nil
				}
			}
		}
	} else {
		availableWorkers := kontrolConfig.NumberOfWorker(worker.Name, worker.Hostname, workerconfig.Pending, false)
		// If there is no other workers of same name(type) on the same hostname than add it immediadetly ...
		log.Printf("for '%s' workers allowed: %d, workers available: %d",
			worker.Name,
			worker.Number,
			availableWorkers)

		if availableWorkers < worker.Number {
			log.Printf("adding worker '%s'", worker.Name)
			worker.Message.Result = "added.now"
			worker.Status = workerconfig.Running
			kontrolConfig.AddWorker(worker)
			if err := kontrolConfig.SaveToConfig(); err != nil {
				log.Printf(" %s", err)
			}
			return worker, nil
		}

		log.Printf("a worker of the type '%s' is already registered. Checking for status...", worker.Name)

		// TODO: Adding user in this interval doesn't do anything, add 10-11 seconds timeout
		for _, workerData := range kontrolConfig.RegisteredWorkers {
			if workerData.Name == worker.Name && workerData.Hostname == worker.Hostname {
				err := kontrolConfig.RefreshStatus(workerData.Uuid)
				if err != nil {
					log.Println("couldn't refresh data", err)
				}
			}
		}

		var gotPermission bool = false
		for _, workerData := range kontrolConfig.RegisteredWorkers {
			if workerData.Name == worker.Name && workerData.Hostname == worker.Hostname {
				if workerData.Status == workerconfig.Notstarted ||
					workerData.Status == workerconfig.Killed ||
					workerData.Status == workerconfig.Dead {

					log.Printf("remote worker '%s' on hostname '%s' with uuid '%s' is not responding. Deleting it.",
						workerData.Name,
						workerData.Hostname,
						workerData.Uuid)
					kontrolConfig.DeleteWorker(workerData.Uuid)

					log.Printf("adding worker '%s' on hostname '%s' with uuid '%s' as started",
						worker.Name,
						worker.Hostname,
						worker.Uuid)
					worker.Message.Result = "first.start"
					worker.Status = workerconfig.Running

					kontrolConfig.AddWorker(worker)
					if err := kontrolConfig.SaveToConfig(); err != nil {
						log.Printf(" %s", err)
					}
					gotPermission = true
				}
			}
		}

		if !gotPermission {
			log.Printf("another worker is already workerconfig.Running. No permission to worker '%s' on hostname '%s'", worker.Name, worker.Hostname)
			worker.Message.Result = "added.before"
		}

		return worker, nil // contains first.start or added.before
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

func deliver(data []byte, producer *Producer, appId string) {
	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
		Priority:        0, // 0-9
	}

	switch producer.name {
	case "cli":
		if appId == "" {
			log.Printf(" Can't send to cli. appId is missing")
		}
		cliOut := "output.cli." + appId
		err := cliProducer.channel.Publish("infoExchange", cliOut, false, false, msg)
		if err != nil {
			log.Printf("error while publishing cli message: %s", err)
		}
		//if config.Verbose {
		//log.Printf("SENDING CLI data to %s", cliOut)
		//}
	case "client":
		err := clientProducer.channel.Publish("clientExchange", "", false, false, msg)
		if err != nil {
			log.Printf("error while publishing client message: %s", err)
		}
		if config.Verbose {
			log.Printf("SENDING CLIENT data %s", string(data))
		}
	case "webapi":
		err := webapiProducer.channel.Publish("infoExchange", "output.webapi", false, false, msg)
		if err != nil {
			log.Printf("error while publishing webapi message: %s", err)
		}
		if config.Verbose {
			log.Println("SENDING WEBAPI data ", string(data))
		}
	case "worker":
		if appId == "" {
			log.Printf("can't send to worker. appId is missing")
		}
		workerOut := "output.worker." + appId
		err := workerProducer.channel.Publish("workerExchange", workerOut, false, false, msg)
		if err != nil {
			log.Printf("error while publishing message: %s", err)
		}
		// if config.Verbose {
		// 	log.Printf("SENDING WORKER data %s to %s", string(data), workerOut)
		// }
	}

	// defer workerProducer.conn.Close()
	// defer workerProducer.channel.Close()

}

func createProducer(name string) (*Producer, error) {
	p := NewProducer(name)

	if config.Verbose {
		log.Printf("creating connection for sending %s messages", p.name)
	}

	user := config.Current.Kontrold.Login
	password := config.Current.Kontrold.Password
	host := config.Current.Kontrold.Host
	port := config.Current.Kontrold.Port

	p.conn = amqputil.CreateAmqpConnection(user, password, host, port)
	p.channel = amqputil.CreateChannel(p.conn)

	return p, nil
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

func buildReq(action, cmd, hostname string, pid int) []byte {
	req := workerconfig.ClientRequest{action, cmd, hostname, pid}
	log.Println("Sending cmd to kontrold-client:", req)

	data, err := json.Marshal(req)
	if err != nil {
		log.Println("Json marshall error", req)
	}
	return data
}
