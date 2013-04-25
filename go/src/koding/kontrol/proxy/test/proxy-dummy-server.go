package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
)

var localPort *string = flag.String("p", "8002", "local port")

func HelloServer(w http.ResponseWriter, req *http.Request) {
	log.Printf("got a request")
	res := fmt.Sprintf("hello koding from localhost:%s ...\n", *localPort)
	io.WriteString(w, res)
}

func main() {
	flag.Parse()
	log.Printf("server started on localhost:%s. you change port via -p <port>", *localPort)
	http.HandleFunc("/", HelloServer)

	addr := ":" + *localPort

	err := http.ListenAndServe(addr, nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
