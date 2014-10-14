package artifact

import (
	"io"
	"log"
	"net/http"
	"strconv"
)

var (
	VERSION string
)

func VersionHandler() func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, VERSION)
	}
}

func HealthCheckHandler(serviceName string) func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, serviceName+" is running with version: "+VERSION)
	}
}

func StartDefaultServer(name string, port int) {
	http.HandleFunc("/healthCheck", HealthCheckHandler(name))
	http.HandleFunc("/version", VersionHandler())

	url := ":" + strconv.Itoa(port)
	log.Fatal(http.ListenAndServe(url, nil))
}
