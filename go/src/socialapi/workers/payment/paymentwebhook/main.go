package main

import (
	"koding/db/mongodb/modelhelper"
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

	st := &stripeMux{}
	pp := &paypalMux{}

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
	customer := paymentmodels.NewCustomer()
	return customer.GetEmail(customerId)
}
