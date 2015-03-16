package main

import (
	"koding/artifact"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net"
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
	Kite *kite.Client
}

func main() {
	r := initializeRunner()

	go r.Listen()

	defer func() {
		r.Close()
		modelhelper.Close()
	}()

	conf := r.Conf
	kloud := conf.Kloud

	Log = helper.CreateLogger(WorkerName, conf.PaymentWebhook.Debug)

	// initialize client to talk to kloud
	kiteClient := initializeKiteClient(r.Kite, kloud.SecretKey, kloud.Address)
	defer kiteClient.Close()

	// initialize controller to inject dependencies
	cont := &Controller{Kite: kiteClient}

	// initialize mux for two implement vendor webhooks
	st := &stripeMux{Controller: cont}
	pp := &paypalMux{Controller: cont}

	// initialize http server
	mux := initializeMux(st, pp)

	port := conf.PaymentWebhook.Port
	Log.Info("Listening on port: %s\n", port)

	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		Log.Fatal(err.Error())
	}

	defer func() {
		listener.Close()
	}()

	err = http.Serve(listener, mux)
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
		Log.Info("kite not initialized in runner. Pass '-kite-init'")
		return nil
	}

	// create a new connection to the cloud
	kiteClient := k.NewClient(kloudAddr)
	kiteClient.Auth = &kite.Auth{Type: "kloudctl", Key: kloudKey}
	kiteClient.Reconnect = true

	// dial the kloud address
	if err := kiteClient.DialTimeout(time.Second * 10); err != nil {
		Log.Error("%s. Is kloud/kontrol running?", err.Error())
		return nil
	}

	Log.Debug("Connected to klient: %s", kloudAddr)

	return kiteClient
}

func initializeMux(st *stripeMux, pp *paypalMux) *http.ServeMux {
	mux := http.NewServeMux()

	mux.Handle("/-/payments/stripe/webhook", st)
	mux.Handle("/-/payments/paypal/webhook", pp)
	mux.HandleFunc("/version", artifact.VersionHandler())
	mux.HandleFunc("/healthCheck", artifact.HealthCheckHandler(WorkerName))

	return mux
}

func getUserForCustomer(customerId string) (*models.User, error) {
	return paymentmodels.NewCustomer().GetUser(customerId)
}
