package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"github.com/kr/pretty"
)

//  &{src:0xc20801e4c0 hdr:<nil> r:<nil> closing:false mu:{state:0 sema:0} closed:false}
type Response struct {
	Src     map[string]interface{} `json:"src"`
	Hdr     interface{}            `json:"hdr"`
	R       interface{}            `json:"r,omitempty"`
	Closing interface{}            `json:"closing"`
	Mu      Mu                     `json:"mu"`
	Closed  interface{}            `json:"closed"`
}

type Mu struct {
	State int `json:"state"`
	Sema  int `json:"sema"`
}

func main() {
	http.HandleFunc("/", dota)
	fmt.Println("started listening")
	http.ListenAndServe(":8080", nil)

}

func dota(w http.ResponseWriter, req *http.Request) {

	req.ParseForm()
	value := req.Form["text"]
	// 	body := `{
	//     "text": "It's 80 degrees right now.",
	//     "attachments": [
	//         {
	//             "text":"Partly cloudy today and tomorrow"
	//         }
	//     ]
	// }`
	command := fmt.Sprintf("You typed %s", strings.Join(value, ""))
	w.Write([]byte(command))
}

func handler(w http.ResponseWriter, req *http.Request) {
	pretty.Println("req is:", req)
	// pretty.Println("req.body is:", req.Body)
	re := fmt.Sprintf("%+v", req)
	fmt.Println("REQUEST IS:", re)
	body := fmt.Sprintf("%+v", req.Body)
	fmt.Println("REQUEST Body IS:", body)
	//
	// value := make(map[string]interface{})
	//
	// val := req.Body

	// fmt.Println(val)

	value := &Response{}
	err := json.NewDecoder(req.Body).Decode(value)
	defer req.Body.Close()

	if err != nil {
		fmt.Print("err is:", err)
		return
	}
	//
	// fmt.Println("value is:", value)

	// var value map[string]interface{}

	// err := json.Unmarshal([]byte(req.Body), &value)
	// if err != nil {
	// 	fmt.Println("err is:", err)
	// 	return
	// }

	fmt.Println("request is delivered")
	pretty.Println("req is:", req)
	// pretty.Println("REQ V INTERFACE IS:", v)
}

func form(w http.ResponseWriter, r *http.Request) {
	r.ParseForm() //Parse url parameters passed, then parse the response packet for the POST body (request body)
	// attention: If you do not call ParseForm method, the following data can not be obtained form
	fmt.Println(r.Form) // print information on server side.
	fmt.Println("path", r.URL.Path)
	fmt.Println("scheme", r.URL.Scheme)
	fmt.Println(r.Form["url_long"])
	for k, v := range r.Form {
		fmt.Print("key:", k)
		fmt.Println("\tval:", strings.Join(v, ""))
	}
}

//
