package main

import (
	"fmt"
	"io/ioutil"
	"log"
)

func main() {
	fmt.Println("fatih arslan")
	if err := ioutil.WriteFile("/root/deneme.txt", []byte("Hello Koding!"), 0755); err != nil {
		log.Fatalln(err)
	}
}
