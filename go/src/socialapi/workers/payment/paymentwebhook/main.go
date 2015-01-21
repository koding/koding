package main

import (
	"koding/db/mongodb/modelhelper"
	"log"
	"net/http"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/payment"
)

func main() {
	conf := initialize()

	http.HandleFunc("/stripe", stripeHandler)
	http.HandleFunc("/paypal", paypalHandler)

	port := conf.PaymentWebhook.Port

	log.Printf("Listening on port: %s", port)

	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Fatal(err.Error())
	}
}

func initialize() *config.Config {
	r := runner.New("paymenttest")
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	modelhelper.Initialize(r.Conf.Mongo)
	payment.Initialize(config.MustGet(), r.Kite)

	return r.Conf
}
