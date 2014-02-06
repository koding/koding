package main

import (
	"encoding/json"
	"flag"
	"koding/db/models"
	"koding/kontrol/kontroldaemon/workerconfig"
	"koding/kontrol/kontrolhelper"
	"koding/tools/config"
	"koding/tools/process"
	"log"
	"os"

	"github.com/streadway/amqp"
)

type ConfigFile struct {
	Mongo string
	Mq    struct {
		Host          string
		Port          int
		ComponentUser string
		Password      string
		Vhost         string
	}
}

func init() {
	log.SetPrefix("kontrold-client ")
}

var producer *kontrolhelper.Producer
var configProfile = flag.String("c", "", "Configuration profile from file")
var conf *config.Config

func main() {
	flag.Parse()
	if *configProfile == "" {
		log.Fatal("Please define config file with -c")
	}

	conf = config.MustConfig(*flagProfile)

	var err error
	producer, err = kontrolhelper.CreateProducer("client")
	if err != nil {
		log.Fatalf(err.Error())
	}

	data, err := gatherData()
	if err != nil {
		log.Fatalf(err.Error())
	}

	deliver(data)
}

func gatherData() ([]byte, error) {
	log.Println("gathering information...")
	buildNumber := kontrolhelper.ReadVersion()
	configused := kontrolhelper.ReadFile("CONFIG_USED")
	gitbranch := kontrolhelper.ReadFile("GIT_BRANCH")
	gitcommit := kontrolhelper.ReadFile("GIT_COMMIT")

	publicHostname, _ := os.Hostname()

	localHostname, err := process.RunCmd("ec2metadata", "--local-hostname")
	if err != nil {
		log.Println(err.Error())
	}

	publicIP, err := process.RunCmd("ec2metadata", "--public-ipv4")
	if err != nil {
		log.Println(err.Error())
	}

	localIp, err := process.RunCmd("ec2metadata", "--local-ipv4")
	if err != nil {
		log.Println(err.Error())
	}

	configJSON, err := process.RunCmd("node", "-e", "require('koding-config-manager').printJson('main."+configused+"')")
	if err != nil {
		log.Println(err.Error())
	}

	config := &models.ConfigFile{}
	err = json.Unmarshal(configJSON, &config)
	if err != nil {
		log.Fatalf("Could not unmarshal configuration: %s\nConfiguration source output:\n%s\n", err.Error(), configJSON)
	}

	s := &models.ServerInfo{
		BuildNumber: buildNumber,
		GitBranch:   gitbranch,
		GitCommit:   gitcommit,
		ConfigUsed:  configused,
		Config:      config,
		Hostname: models.Hostname{
			Public: publicHostname,
			Local:  string(localHostname),
		},
		IP: models.IP{
			Public: string(publicIP),
			Local:  string(localIp),
		},
	}

	data, err := json.Marshal(s)
	if err != nil {
		log.Println(err.Error())
	}

	log.Println(".. I'm done")
	log.Println("Data is: ", string(data))

	return data, nil
}

func startConsuming() {
	connection := kontrolhelper.CreateAmqpConnection()
	channel := kontrolhelper.CreateChannel(connection)

	err := channel.ExchangeDeclare("clientExchange", "fanout", true, false, false, false, nil)
	if err != nil {
		log.Fatalf("info exchange.declare: %s", err)
	}

	if _, err := channel.QueueDeclare("", false, true, false, false, nil); err != nil {
		log.Fatalf("clientProducer queue.declare: %s", err)
	}

	if err := channel.QueueBind("", "", "clientExchange", false, nil); err != nil {
		log.Fatalf("clientProducer queue.bind: %s", err)
	}

	stream, err := channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Fatalf("clientProducer basic.consume: %s", err)
	}

	log.Println("starting to listen for requests...")
	for d := range stream {
		log.Printf("handle got %dB message data: [%v] %s %s",
			len(d.Body),
			d.DeliveryTag,
			d.Body,
			d.AppId)

		var req workerconfig.ClientRequest
		err := json.Unmarshal(d.Body, &req)
		if err != nil {
			log.Print("bad json incoming msg: ", err)
		}

		matchAction(req.Action, req.Cmd, req.Hostname, req.Pid)

	}
}

func matchAction(action, cmd, hostname string, pid int) {
	funcs := map[string]func(cmd, hostname string, pid int) error{
		"start": start,
		"check": check,
		"kill":  kill,
		"stop":  stop,
	}

	host, _ := os.Hostname()
	if hostname != "" && hostname != host {
		log.Println("command is for a different machine")
		return
	}

	if pid == 0 && action != "start" {
		log.Printf("please provide pid number for '%s'\n", action)
	}

	err := funcs[action](cmd, hostname, pid)
	if err != nil {
		log.Println("call function err", err)
	}

}

func start(cmd, hostname string, pid int) error {
	log.Printf("trying to start command '%s'", cmd)

	_, err := process.RunCmd(cmd)
	if err != nil {
		return err
	}

	log.Printf("cmd '%s' started", cmd)
	return nil
}

func check(cmd, hostname string, pid int) error {
	err := process.CheckPid(pid)
	if err != nil {
		return err
	}

	log.Printf("local process with %s pid is alive", pid)
	return nil
}

func kill(cmd, hostname string, pid int) error {
	err := process.KillPid(pid)
	if err != nil {
		return err
	}

	log.Printf("local process with %s pid is killed", pid)
	return nil
}

func stop(cmd, hostname string, pid int) error {
	err := process.StopPid(pid)
	if err != nil {
		return err
	}

	log.Printf("local process with %s pid is get SIGSTOP", pid)
	return nil
}

func deliver(data []byte) {
	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
	}

	err := producer.Channel.Publish("clientExchange", "kontrol-client", false, false, msg)
	if err != nil {
		log.Printf("error while publishing client message: %s", err)
	}
}
