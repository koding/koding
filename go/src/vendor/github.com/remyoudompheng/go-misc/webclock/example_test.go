package webclock_test

import (
	"flag"
	"log"
	"net/http"
)

func ExampleRegister() {
	var addr string
	flag.StringVar(&addr, "http", "localhost:8082", "listen here")
	flag.Parse()

	log.Printf("serving on %s", addr)
	err := http.ListenAndServe(addr, nil)
	if err != nil {
		log.Printf("error in server: %s", err)
	}
}
