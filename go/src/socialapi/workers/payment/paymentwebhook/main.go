package main

import (
	"fmt"
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"koding/kodingemail"
	"log"
	"net/http"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/payment"
	"socialapi/workers/payment/paymentmodels"
	"time"

	"github.com/koding/kite"
)

var WorkerName = "paymentwebhook"

type Controller struct {
	Kite  *kite.Client
	Email *kodingemail.SG
}

func main() {
	r := initialize()
	conf := r.Conf

	kiteClient := initializeKiteClient(r.Kite, conf.Kloud.SecretKey, conf.Kloud.Address)

	email := kodingemail.InitializeSG(conf.Email.Username, conf.Email.Password)
	email.FromAddress = conf.Email.DefaultFromMail
	email.FromName = conf.Email.DefaultFromMail

	cont := &Controller{Kite: kiteClient, Email: email}

	st := &stripeMux{Controller: cont}
	pp := &paypalMux{Controller: cont}

	mux := http.NewServeMux()
	mux.Handle("/stripe", st)
	mux.Handle("/paypal", pp)

	http.HandleFunc("/version", artifact.VersionHandler())
	http.HandleFunc("/healthCheck", artifact.HealthCheckHandler(WorkerName))

	port := conf.PaymentWebhook.Port

	log.Printf("Listening on port: %s", port)

	err := http.ListenAndServe(":"+port, mux)
	if err != nil {
		log.Fatal(err.Error())
	}
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

func initialize() *runner.Runner {
	r := runner.New("paymenttest")
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	modelhelper.Initialize(r.Conf.Mongo)
	payment.Initialize(config.MustGet(), r.Kite)

	return r
}

func initializeKiteClient(k *kite.Kite, kloudSecretKey, kloudAddr string) *kite.Client {
	if k == nil {
		fmt.Println("kite not initialized in runner")
		return nil
	}

	// create a new connection to the cloud
	kiteClient := k.NewClient(kloudAddr)
	kiteClient.Auth = &kite.Auth{
		Type: "kloudctl",
		Key:  kloudSecretKey,
	}

	// dial the kloud address
	if err := kiteClient.DialTimeout(time.Second * 10); err != nil {
		fmt.Println("%s. Is kloud/kontrol running?", err.Error())
		return nil
	}

	fmt.Println("Connected to klient: %s", kloudAddr)

	return kiteClient
}

func getEmailForCustomer(customerId string) (string, error) {
	return paymentmodels.NewCustomer().GetEmail(customerId)
}
