package pastehere_test

import (
	"flag"
	"log"
	"net/http"

	"github.com/remyoudompheng/go-misc/pastehere"
)

var address string

func init() {
	flag.StringVar(&address, "http", ":8080", "listen address")
}

func ExampleRegister() {
	flag.Parse()
	if address == "" {
		flag.Usage()
		return
	}
	log.Printf("start listening at %s", address)

	pastehere.Register(nil)
	err := http.ListenAndServe(address, nil)
	if err != nil {
		log.Fatal(err)
	}
}
