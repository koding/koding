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

func initialize() *config.Config {
	r := runner.New("paymenttest")
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	modelhelper.Initialize(r.Conf.Mongo)
	payment.Initialize(config.MustGet(), r.Kite)

	return r.Conf
}
