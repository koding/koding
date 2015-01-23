package main

import (
	"koding/db/mongodb/modelhelper"
	"koding/kodingemail"
	"log"
	"net/http"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/payment"
	"socialapi/workers/payment/paymentmodels"
)

func main() {
	conf := initialize()

	mux := http.NewServeMux()

	email := kodingemail.InitializeSG(conf.Email.Username, conf.Email.Password)
	email.FromAddress = conf.Email.DefaultFromMail
	email.FromName = conf.Email.DefaultFromMail

	st := &stripeMux{EmailClient: email}
	pp := &paypalMux{EmailClient: email}

	mux.Handle("/stripe", st)
	mux.Handle("/paypal", pp)

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

func initialize() *config.Config {
	r := runner.New("paymenttest")
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	modelhelper.Initialize(r.Conf.Mongo)
	payment.Initialize(config.MustGet(), r.Kite)

	return r.Conf
}

func getEmailForCustomer(customerId string) (string, error) {
	return paymentmodels.NewCustomer().GetEmail(customerId)
}
