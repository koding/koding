package main

import (
	"fmt"

	"github.com/koding/logging"
)

func main() {

	// Default logger
	logging.Debug("Debug")
	logging.Info("Info")
	logging.Notice("Notice")
	logging.Warning("Warning")
	logging.Error("Error")
	logging.Critical("Critical")

	// Custom logger with default handler
	l := logging.NewLogger("test")

	l.Debug("Debug")
	l.Info("Info")
	l.Notice("Notice")
	l.Warning("Warning")
	l.Error("Error")
	l.Critical("Critical")

	// Custom logger with custom handler
	l2 := logging.NewLogger("test2")
	l2.SetHandler(&MyHandler{})

	l2.Debug("Debug")
	l2.Info("Info")
	l2.Notice("Notice")
	l2.Warning("Warning")
	l2.Error("Error")
	l2.Critical("Critical")
}

type MyHandler struct {
	logging.BaseHandler
}

func (h *MyHandler) Handle(rec *logging.Record) {
	fmt.Printf(rec.Format, rec.Args...)
}

func (h *MyHandler) Close() {
}
