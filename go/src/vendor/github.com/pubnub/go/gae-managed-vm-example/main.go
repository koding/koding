package main

import (
	"fmt"
	"github.com/gorilla/mux"
	"github.com/gorilla/sessions"
	"github.com/pubnub/go/messaging"
	"golang.org/x/net/websocket"
	"html/template"
	"log"
	"math/big"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

var mainTemplate = template.Must(template.ParseFiles("main.html"))
var subscribeKey = "demo"
var publishKey = "demo"
var secretKey = "demo"
var hostname = "localhost"
var port = ":8080"
var infoLogger = log.New(os.Stdout, "", log.Ldate|log.Ltime|log.Lshortfile)

var store = sessions.NewCookieStore([]byte(secretKey))

func main() {
	/*n, err := os.Hostname()
	if err == nil {
		hostname = n
	}*/

	router := mux.NewRouter()
	router = router.StrictSlash(true)
	router.HandleFunc("/", handler)
	router.HandleFunc("/publish", publish)
	router.HandleFunc("/globalHereNow", globalHereNow)
	router.HandleFunc("/hereNow", hereNow)
	router.HandleFunc("/whereNow", whereNow)
	router.HandleFunc("/time", getTime)
	router.HandleFunc("/setAuthKey", setAuthKey)
	router.HandleFunc("/getAuthKey", getAuthKey)
	router.HandleFunc("/deleteUserState", deleteUserState)
	router.HandleFunc("/setUserStateJson", setUserStateJSON)
	router.HandleFunc("/setUserState", setUserState)
	router.HandleFunc("/auditPresence", auditPresence)
	router.HandleFunc("/revokePresence", revokePresence)
	router.HandleFunc("/grantPresence", grantPresence)
	router.HandleFunc("/auditSubscribe", auditSubscribe)
	router.HandleFunc("/revokeSubscribe", revokeSubscribe)
	router.HandleFunc("/grantSubscribe", grantSubscribe)
	router.HandleFunc("/getUserState", getUserState)
	router.HandleFunc("/subscribe", subscribe)
	http.Handle("/echo", websocket.Handler(EchoServer))
	//router.HandleFunc("/signout", signout)
	//router.HandleFunc("/connect", connect)
	//router.HandleFunc("/keepAlive", keepAlive)
	router.HandleFunc("/detailedHistory", detailedHistory)
	router.HandleFunc(`/{rest:[a-zA-Z0-9=\-\/]+}`, handler)

	http.Handle("/", router)
	//http.Handle("/", handler)
	log.Print("Listening on port ", port)
	log.Fatal(http.ListenAndServe(port, nil))
}

type T struct {
	Msg   string
	Count int
}

var wsc *websocket.Conn

func EchoServer(ws *websocket.Conn) {
	wsc = ws
	log.Print("in WS")
	var data T
	websocket.JSON.Receive(ws, &data)
	log.Print("in WS", data)
}

// Echo the data received on the WebSocket.
func SendToWS(message string) {
	log.Print("sending to WS")
	websocket.Message.Send(wsc, message)
}

func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "ok")
}

func subscribe(w http.ResponseWriter, r *http.Request) {
	var errorChannel = make(chan []byte)
	var subscribeChannel = make(chan []byte)

	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, "", infoLogger)

	go pubInstance.Subscribe("test2", "", subscribeChannel, false, errorChannel)
	go handleSubscribeResult(subscribeChannel, errorChannel, "Subscribe")
}

func handleSubscribeResult(successChannel, errorChannel chan []byte, action string) {
	for {
		select {
		case success, ok := <-successChannel:
			if !ok {
				break
			}
			if string(success) != "[]" {
				fmt.Println(fmt.Sprintf("%s Response: %s ", action, success))
				fmt.Println("")
			}
		case failure, ok := <-errorChannel:
			if !ok {
				break
			}
			if string(failure) != "[]" {
				if true {
					fmt.Println(fmt.Sprintf("%s Error Callback: %s", action, failure))
					fmt.Println("")
				}
			}
		}
	}
}

func detailedHistory(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	uuid := q.Get("uuid")
	start := q.Get("start")
	var iStart int64
	if strings.TrimSpace(start) != "" {
		bi := big.NewInt(0)
		if _, ok := bi.SetString(start, 10); !ok {
			iStart = 0
		} else {
			iStart = bi.Int64()
		}
	}

	end := q.Get("end")
	var iEnd int64
	if strings.TrimSpace(end) != "" {
		bi := big.NewInt(0)
		if _, ok := bi.SetString(end, 10); !ok {
			iEnd = 0
		} else {
			iEnd = bi.Int64()
		}
	}

	limit := q.Get("limit")
	reverse := q.Get("reverse")

	iLimit := 100
	if ival, err := strconv.Atoi(limit); err == nil {
		iLimit = ival
	}

	bReverse := false
	if reverse == "1" {
		bReverse = true
	}

	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pubInstance.History(ch, iLimit, iStart, iEnd, bReverse, false, successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Detailed History")
}

/*func connect(w http.ResponseWriter, r *http.Request) {
q := r.URL.Query()
/*pubKey := q.Get("pubKey")
subKey := q.Get("subKey")*/
//uuid := q.Get("uuid")
/*secKey := q.Get("secKey")
cipher := q.Get("cipher")
ssl := q.Get("ssl")
bSsl := false
if ssl == "1" {
	bSsl = true
}*/

//	c := context.NewContext(r)
//c := createContext(r)
//messaging.NewPubnub (c, w, r, pubKey, subKey, secKey, cipher, bSsl, uuid)

/*session, err := store.Get(r, "example-session")
	if err != nil {
		log.Print("Error: Session store error %s", err.Error())
		http.Error(w, "Session store error", http.StatusInternalServerError)
		return
	}

	c := appengine.NewContext(r)
	tok, err := channel.Create(c, uuid)

	if err != nil {
		http.Error(w, "Couldn't create Channel", http.StatusInternalServerError)
		log.Print("Error: channel.Create: %v", err)
		return
	}
	session.Values["token"] = tok
	err1 := session.Save(r, w)
	if err1 != nil {
		log.Print("Error: error1, %s", err1.Error())
	}
	fmt.Fprintf(w, tok)
}*/

/*func keepAlive(w http.ResponseWriter, r *http.Request) {

}

func signout(w http.ResponseWriter, r *http.Request) {
	//c := context.NewContext(r)
	c := createContext(r)
	messaging.DeleteSession(c, w, r, secretKey)
}*/

func getUserState(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	uuid := q.Get("uuid")

	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pubInstance.GetUserState(ch, uuid, successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Get User State")
}

func deleteUserState(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	key := q.Get("k")
	uuid := q.Get("uuid")
	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pubInstance.SetUserStateKeyVal(ch, key, "", successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Del User State")
}

func setUserStateJSON(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	j := q.Get("j")
	uuid := q.Get("uuid")
	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pubInstance.SetUserStateJSON(ch, j, successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Set User State JSON")
}

func setUserState(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	k := q.Get("k")
	v := q.Get("v")
	uuid := q.Get("uuid")
	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pubInstance.SetUserStateKeyVal(ch, k, v, successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Set User State")
}

func auditPresence(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	uuid := q.Get("uuid")
	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	go pubInstance.AuditPresence(ch, "", successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Audit Presence")
}

func revokePresence(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	uuid := q.Get("uuid")
	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	go pubInstance.GrantPresence(ch, false, false, 0, "", successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke Presence")
}

func grantPresence(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	uuid := q.Get("uuid")
	read := q.Get("r")
	write := q.Get("w")
	ttl := q.Get("ttl")
	bRead := false
	if read == "1" {
		bRead = true
	}
	bWrite := false
	if write == "1" {
		bWrite = true
	}
	iTTL := 1440
	if ival, err := strconv.Atoi(ttl); err == nil {
		iTTL = ival
	}

	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	go pubInstance.GrantPresence(ch, bRead, bWrite, iTTL, "", successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke Presence")

}

func auditSubscribe(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	uuid := q.Get("uuid")
	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	go pubInstance.AuditSubscribe(ch, "", successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Audit Subscribe")
}

func revokeSubscribe(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	uuid := q.Get("uuid")
	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	go pubInstance.GrantSubscribe(ch, false, false, 0, "", successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke Subscribe")
}

func grantSubscribe(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	read := q.Get("r")
	write := q.Get("w")
	ttl := q.Get("ttl")
	bRead := false
	if read == "1" {
		bRead = true
	}
	bWrite := false
	if write == "1" {
		bWrite = true
	}
	iTTL := 1440
	if ival, err := strconv.Atoi(ttl); err == nil {
		iTTL = ival
	}

	uuid := q.Get("uuid")
	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	go pubInstance.GrantSubscribe(ch, bRead, bWrite, iTTL, "", successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke Subscribe")
}

func setAuthKey(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	authKey := q.Get("authkey")
	uuid := q.Get("uuid")

	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	pubInstance.SetAuthenticationKey(authKey)
	sendResponseToChannel(w, "Auth key set", r, uuid)
}

func getAuthKey(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	uuid := q.Get("uuid")
	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	sendResponseToChannel(w, "Auth key: "+pubInstance.GetAuthenticationKey(), r, uuid)
}

func publish(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	message := q.Get("m")
	uuid := q.Get("uuid")
	ch := q.Get("ch")

	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	go pubInstance.Publish(ch, message, successChannel, errorChannel)

	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Publish")
}

func globalHereNow(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	uuid := q.Get("uuid")
	globalHereNowShowUUID := q.Get("showUUID")
	globalHereNowIncludeUserState := q.Get("includeUserState")
	disableUUID := false
	includeUserState := false
	if globalHereNowShowUUID == "1" {
		disableUUID = true
	}
	if globalHereNowIncludeUserState == "1" {
		includeUserState = true
	}
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	go pubInstance.GlobalHereNow(disableUUID, includeUserState, successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Global Here Now")
}

func hereNow(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	channel := q.Get("ch")
	uuid := q.Get("uuid")
	hereNowShowUUID := q.Get("showUUID")
	hereNowIncludeUserState := q.Get("includeUserState")

	disableUUID := false
	includeUserState := false
	if hereNowShowUUID == "1" {
		disableUUID = true
	}
	if hereNowIncludeUserState == "1" {
		includeUserState = true
	}

	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	go pubInstance.HereNow(channel, "", disableUUID, includeUserState, successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "HereNow")
}

func whereNow(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	whereNowUUID := q.Get("whereNowUUID")
	uuid := q.Get("uuid")

	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	go pubInstance.WhereNow(whereNowUUID, successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "WhereNow")
}

func getTime(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	uuid := q.Get("uuid")

	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	go pubInstance.GetTime(successChannel, errorChannel)
	handleResult(w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Time")
}

func handler(w http.ResponseWriter, r *http.Request) {
	log.Print("Info: IN handler")
	uuid := ""
	pubInstance := messaging.NewPubnub(publishKey, subscribeKey, secretKey, "", true, uuid, infoLogger)
	if pubInstance == nil {
		log.Print("Error: Couldn't create pubnub instance")
		http.Error(w, "Couldn't create pubnub instance", http.StatusInternalServerError)
		return
	}
	nuuid := pubInstance.GetUUID()
	log.Print("UUID: %s", nuuid)
	tok := "s"

	err1 := mainTemplate.Execute(w, map[string]string{
		"token":        tok,
		"uuid":         nuuid,
		"subscribeKey": subscribeKey,
		"publishKey":   publishKey,
		"secretKey":    secretKey,
		"hostname":     fmt.Sprintf("%s%s", hostname, port),
	})
	if err1 != nil {
		log.Print("Error: mainTemplate: %v", err1)
	}
}

func flush(w http.ResponseWriter) {
	f, ok := w.(http.Flusher)
	if ok && f != nil {
		f.Flush()
	} else {
		// Response writer does not support flush.
		fmt.Fprintf(w, fmt.Sprintf(" Response writer does not support flush.:"))
	}

}

func sendResponseToChannel(w http.ResponseWriter, message string, r *http.Request, uuid string) {
}

func handleResultSubscribe(w http.ResponseWriter, r *http.Request, uuid string, successChannel, errorChannel chan []byte, timeoutVal uint16, action string) {
	for {
		select {

		case success, ok := <-successChannel:
			if !ok {
				log.Print(fmt.Sprintf("INFO: success!OK"))

			}
			if string(success) != "[]" {
				log.Print("Info: subscribe success:", string(success))
			}
			flush(w)
		case failure, ok := <-errorChannel:
			if !ok {
				log.Print(fmt.Sprintf("Info: failure!OK"))
			}
			if string(failure) != "[]" {
				log.Print("Info: subscribe failure:", string(failure))
			}
		}
	}
}

func handleResult(w http.ResponseWriter, r *http.Request, uuid string, successChannel, errorChannel chan []byte, timeoutVal uint16, action string) {
	timeout := make(chan bool, 1)
	go func() {
		time.Sleep(time.Duration(timeoutVal) * time.Second)
		timeout <- true
	}()
	for {
		select {

		case success, ok := <-successChannel:
			if !ok {
				log.Print("Info: success!OK")
				break
			}
			if string(success) != "[]" {
				log.Print("Info: success:", string(success))
				SendToWS(string(success))
				sendResponseToChannel(w, string(success), r, uuid)
			}

			return
		case failure, ok := <-errorChannel:
			if !ok {
				log.Print("Info: fail1:", string("failure"))
				break
			}
			if string(failure) != "[]" {
				log.Print("Info: fail:", string(failure))
				sendResponseToChannel(w, string(failure), r, uuid)
			}
			return
		case <-timeout:
			fmt.Println(fmt.Sprintf("%s Handler timeout after %d secs", action, timeoutVal))
			fmt.Println("")
			return
		}
	}
}
