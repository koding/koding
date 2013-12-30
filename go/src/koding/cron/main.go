package main

import (
    "fmt"
    "github.com/robfig/cron"
    "koding/workers/topicmodifier"
    "os"
    "os/signal"
    "syscall"
)

var Cron *cron.Cron

// later on this could be implemented as kite, and then we will no longer need hard coded
// method scheduling. Service just calls addFunc and registers itself
func init() {
    Cron = cron.New()
}

func main() {
    fmt.Println("start")

    addTopicModifierConsumer()

    Cron.Start()
    registerSignalHandler()
}

func addTopicModifierConsumer() {
    addFunc("@every 5m", topicmodifier.ConsumeMessage)
}

func registerSignalHandler() {
    signals := make(chan os.Signal, 1)
    signal.Notify(signals)
    for {
        signal := <-signals
        switch signal {
        case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP:
            shutdown()
        }
    }
}

func addFunc(spec string, cmd func()) {
    Cron.AddFunc(spec, cmd)
}

func shutdown() {
    Cron.Stop()
    fmt.Println("Stopping it")
    err := topicmodifier.Shutdown()
    if err != nil {
        panic(err)
    }
    os.Exit(1)
}
