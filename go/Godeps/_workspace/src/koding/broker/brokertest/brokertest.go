package main

import (
	"fmt"
	"io/ioutil"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"
)

var session string

func main() {
	rand.Seed(time.Now().UnixNano())
	session = strconv.Itoa(rand.Int())

	request("/xhr", "")
	for i := 0; i < 5000; i++ {
		// go request("/xhr_send", `{ "action": "publish", "exchange": "notExisting", "routingKey": "client.iAmEvil", "payload": "" }`)
		// request("/xhr_send", `{ "action": "ping", "nr": `+strconv.Itoa(i)+` }`)
		request("/xhr_send", `{ "action": "subscribe", "routingKeyPrefix": "something`+strconv.Itoa(i)+`", "nr": `+strconv.Itoa(i)+` }`)
		// request("/xhr_send", `{ "action": "unsubscribe", "routingKeyPrefix": "something`+strconv.Itoa(i)+`", "nr": `+strconv.Itoa(i)+` }`)
	}
	// time.Sleep(time.Second * 10)
}

func request(addr, data string) {
	respose, err := http.Post("http://localhost:8008/subscribe/0/"+session+addr, "", strings.NewReader(data))
	if err != nil {
		panic(err)
	}

	body, _ := ioutil.ReadAll(respose.Body)
	fmt.Print(string(body))
}
