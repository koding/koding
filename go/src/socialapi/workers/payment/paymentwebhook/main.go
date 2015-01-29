package main

import (
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"koding/kodingemail"
	"net/http"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/payment"
	"socialapi/workers/payment/paymentmodels"
	"time"

	"github.com/koding/kite"
)

var (
	WorkerName = "paymentwebhook"
	Log        = helper.CreateLogger(WorkerName, false)
)

type Controller struct {
	Kite  *kite.Client
	Email kodingemail.Client
}

func main() {
	r := initializeRunner()

	conf := r.Conf
	kloud := conf.Kloud

	// initialize client to talk to kloud
	kiteClient := initializeKiteClient(r.Kite, kloud.SecretKey, kloud.Address)

	// initialize client to send email
	email := initializeEmail(conf.Email)

	// initialize controller to inject dependencies
	cont := &Controller{Kite: kiteClient, Email: email}

	// initialize mux for two implement vendor webhooks
	st := &stripeMux{Controller: cont}
	pp := &paypalMux{Controller: cont}

	// initialize http server
	mux := http.NewServeMux()
	mux.Handle("/-/payments/stripe/webhook", st)
	mux.Handle("/-/payments/paypal/webhook", pp)

	http.HandleFunc("/version", artifact.VersionHandler())
	http.HandleFunc("/healthCheck", artifact.HealthCheckHandler(WorkerName))

	port := conf.PaymentWebhook.Port

	Log.Info("Listening on port: %s\n", port)

	err := http.ListenAndServe(":"+port, mux)
	if err != nil {
		Log.Fatal(err.Error())
	}
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

func initializeRunner() *runner.Runner {
	r := runner.New(WorkerName)
	if err := r.Init(); err != nil {
		Log.Fatal(err.Error())
	}

	modelhelper.Initialize(r.Conf.Mongo)
	payment.Initialize(config.MustGet())

	return r
}

func initializeKiteClient(k *kite.Kite, kloudKey, kloudAddr string) *kite.Client {
	if k == nil {
		Log.Info("kite not initialized in runner")
		return nil
	}

	// create a new connection to the cloud
	kiteClient := k.NewClient(kloudAddr)
	kiteClient.Auth = &kite.Auth{Type: "kloudctl", Key: kloudKey}

	// dial the kloud address
	if err := kiteClient.DialTimeout(time.Second * 10); err != nil {
		Log.Info("%s. Is kloud/kontrol running?", err.Error())
		return nil
	}

	Log.Debug("Connected to klient: %s", kloudAddr)

	return kiteClient
}

func initializeEmail(conf config.Email) kodingemail.Client {
	return kodingemail.NewSG(conf.Username, conf.Password)
}

func getEmailForCustomer(customerId string) (string, error) {
	return paymentmodels.NewCustomer().GetEmail(customerId)
}
