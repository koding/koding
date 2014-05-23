package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"os"
	"os/signal"
	"socialapi/workers/common/runner"
	"socialapi/workers/dailyemailnotifier/controller"
	"socialapi/workers/emailnotifier/models"
	"socialapi/workers/helper"
	"syscall"
)

var Name = "EmailDailyNotifier"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	// init redis connection
	redisConn := helper.MustInitRedisConn(r.Conf.Redis)
	defer redisConn.Close()

	es := &models.EmailSettings{
		Username:        r.Conf.SendGrid.Username,
		Password:        r.Conf.SendGrid.Password,
		FromMail:        r.Conf.SendGrid.FromMail,
		FromName:        r.Conf.SendGrid.FromName,
		ForcedRecipient: r.Conf.SendGrid.ForcedRecipient,
	}

	handler, err := controller.NewDailyEmailNotifierWorkerController(
		r.Log,
		es,
	)
	if err != nil {
		r.Log.Error("an error occurred", err)
	}

	registerSignalHandler(handler)
}

func registerSignalHandler(h *controller.DailyEmailNotifierWorkerController) {
	signals := make(chan os.Signal, 1)
	signal.Notify(signals)
	for {
		signal := <-signals
		switch signal {
		case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP:
			h.Shutdown()
			os.Exit(1)
		}
	}
}
