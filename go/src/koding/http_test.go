package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"testing"
)

func sendRequest(url string, data string) string {

	dataByte := strings.NewReader(data)

	req, err := http.Post(url, "application/json", dataByte)

	if err != nil {
		fmt.Println(err)
	}
	body, _ := ioutil.ReadAll(req.Body)
	defer req.Body.Close()
	// fmt.Println("Request sent")
	return fmt.Sprintf("%s", body)
}

func main() {
}

func Benchmark_TimeConsumingFunction(b *testing.B) { //benchmark function starts with "Benchmark" and takes a pointer to type testing.B

	for i := 0; i < 500; i++ {
		url := "http://localhost:7474/db/data/ext/CypherPlugin/graphdb/execute_query"
		// data := ``
		data := `{ "query" : "start koding=node:koding(\"id:512a2abdd9e58de55e000003\") MATCH koding<-[:follower]-myfollowees-[:creator]->items where myfollowees.name=\"JAccount\" return myfollowees, items;", "params" : {  } }`
		as := sendRequest(url, data)
		fmt.Println(as)
	}
}
