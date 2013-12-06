package main

import (
	"io"
	"log"
	"net/http"
)

func HelloServer(w http.ResponseWriter, req *http.Request) {
	log.Println("hello world invoked ", req.RemoteAddr)
	io.WriteString(w, "hello, world!\n")
}

func wat(w http.ResponseWriter, req *http.Request) {
	log.Println("wat", req.RemoteAddr)
	io.WriteString(w, "wat\n")
}

func main() {
	http.HandleFunc("/hello", HelloServer)
	http.HandleFunc("/", wat)
	log.Println("example server started at port 5000")
	err := http.ListenAndServe("127.0.0.1:5000", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
