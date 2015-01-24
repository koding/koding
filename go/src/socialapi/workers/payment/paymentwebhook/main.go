package main

import (
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"koding/kodingemail"
	"log"
	"net/http"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/payment"
	"socialapi/workers/payment/paymentmodels"

	"github.com/koding/kite"
)

var WorkerName = "paymentwebhook"

type Controller struct {
	Kite  *kite.Kite
	Email *kodingemail.SG
}

func main() {
	r := initialize()
	conf := r.Conf

	mux := http.NewServeMux()

	email := kodingemail.InitializeSG(conf.Email.Username, conf.Email.Password)
	email.FromAddress = conf.Email.DefaultFromMail
	email.FromName = conf.Email.DefaultFromMail

	cont := &Controller{Kite: r.Kite, Email: email}

	st := &stripeMux{Controller: cont}
	pp := &paypalMux{Controller: cont}

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

func getEmailForCustomer(customerId string) (string, error) {
	return paymentmodels.NewCustomer().GetEmail(customerId)
}
