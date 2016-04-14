package main

import (
	"koding/klient/app"
	"koding/s3logrotate"
	"log"
)

func main() {
	u, err := s3logrotate.NewUploadClient("us-west-1", "koding-klient-logs")
	if err != nil {
		log.Fatal(err)
	}

	// uploads upto 25MB
	c := s3logrotate.New(1024*1024*25, u, app.LogLocations()...)

	log.Fatal(c.ReadAndUpload())
}
