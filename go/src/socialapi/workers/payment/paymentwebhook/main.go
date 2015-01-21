package main

import (
	"log"
	"net/http"
)

var (
	port = "6600"
)

func main() {
	http.HandleFunc("/stripe", stripeHandler)
	http.HandleFunc("/paypal", paypalHandler)

	log.Printf("Listening on port: %s", port)

	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Fatal(err.Error())
	}
}

func stripeHandler(w http.ResponseWriter, r *http.Request) {
}

func paypalHandler(w http.ResponseWriter, r *http.Request) {
}
