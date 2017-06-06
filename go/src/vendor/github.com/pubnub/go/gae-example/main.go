package main

import (
	"fmt"
	"github.com/gorilla/mux"
	"github.com/gorilla/sessions"
	"github.com/pubnub/go/gae/messaging"
	"golang.org/x/net/context"
	"google.golang.org/appengine"
	"google.golang.org/appengine/channel"
	"google.golang.org/appengine/log"
	"html/template"
	"math/big"
	"net/http"
	"strconv"
	"strings"
	//"time"
)

var mainTemplate = template.Must(template.ParseFiles("main.html"))
var subscribeKey = "demo"
var publishKey = "demo"
var secretKey = "demo"

var store = sessions.NewCookieStore([]byte(secretKey))

//func main(){
//appengine.Main()
//init();
//}

func init() {
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
	router.HandleFunc("/signout", signout)
	router.HandleFunc("/connect", connect)
	router.HandleFunc("/keepAlive", keepAlive)
	router.HandleFunc("/detailedHistory", detailedHistory)
	router.HandleFunc(`/{rest:[a-zA-Z0-9=\-\/]+}`, handler)

	http.Handle("/", router)
	//http.Handle("/", handler)

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

	//	ctx := context.NewContext(r)
	ctx := createContext(r)

	pubInstance := messaging.New(ctx, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pubInstance.History(ctx, w, r, ch, iLimit, iStart, iEnd, bReverse, successChannel, errorChannel)
	handleResult(ctx, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Detailed History")
}

func createContext(r *http.Request) context.Context {
	//parent := context.TODO()
	//ctx := context.WithValue(parent, "request", r)
	ctx := appengine.NewContext(r)
	return ctx
}

func connect(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	pubKey := q.Get("pubKey")
	subKey := q.Get("subKey")
	uuid := q.Get("uuid")
	secKey := q.Get("secKey")
	cipher := q.Get("cipher")
	ssl := q.Get("ssl")
	bSsl := false
	if ssl == "1" {
		bSsl = true
	}

	//	c := context.NewContext(r)
	c := createContext(r)
	messaging.SetSessionKeys(c, w, r, pubKey, subKey, secKey, cipher, bSsl, uuid)

	session, err := store.Get(r, "example-session")
	if err != nil {
		log.Errorf(c, "Session store error %s", err.Error())
		http.Error(w, "Session store error", http.StatusInternalServerError)
		return
	}

	tok, err := channel.Create(c, uuid)

	if err != nil {
		http.Error(w, "Couldn't create Channel", http.StatusInternalServerError)
		log.Errorf(c, "channel.Create: %v", err)
		return
	}
	session.Values["token"] = tok
	err1 := session.Save(r, w)
	if err1 != nil {
		log.Errorf(c, "error1, %s", err1.Error())
	}
	fmt.Fprintf(w, tok)
}

func keepAlive(w http.ResponseWriter, r *http.Request) {

}

func signout(w http.ResponseWriter, r *http.Request) {
	//c := context.NewContext(r)
	c := createContext(r)
	messaging.DeleteSession(c, w, r, secretKey)
}

func getUserState(w http.ResponseWriter, r *http.Request) {
	/*successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	c := createContext(r)
	pubInstance := messaging.New(c, "", w, r, publishKey, subscribeKey, secretKey, "", false)

	go pubInstance.ChannelGroupAddChannel(c, w, r, "cg-user-a-friends", "ch-user-a-present", successChannel, errorChannel)

	select {
	case response := <-successChannel:
		log.Infof(c, "success:", string(response))
	case err := <-errorChannel:
		log.Infof(c, "success:", string(err))
	}

	go pubInstance.ChannelGroupAddChannel(c, w, r, "cg-user-a-status-feed", "ch-user-a-present", successChannel, errorChannel)

	select {
	case response := <-successChannel:
		log.Infof(c, "1success:", string(response))
	case err := <-errorChannel:
		log.Infof(c, "1success:", string(err))
	}*/
	q := r.URL.Query()
	ch := q.Get("ch")
	uuid := q.Get("uuid")

	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pubInstance.GetUserState(c, w, r, ch, successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Get User State")
}

func deleteUserState(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	key := q.Get("k")
	uuid := q.Get("uuid")
	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pubInstance.SetUserStateKeyVal(c, w, r, ch, key, "", successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Del User State")
}

func setUserStateJSON(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	j := q.Get("j")
	uuid := q.Get("uuid")
	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pubInstance.SetUserStateJSON(c, w, r, ch, j, successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Set User State JSON")
}

func setUserState(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	k := q.Get("k")
	v := q.Get("v")
	uuid := q.Get("uuid")
	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	//setUserState

	go pubInstance.SetUserStateKeyVal(c, w, r, ch, k, v, successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Set User State")
}

func auditPresence(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	uuid := q.Get("uuid")
	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	go pubInstance.AuditPresence(c, w, r, ch, "", successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Audit Presence")
}

func revokePresence(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	uuid := q.Get("uuid")
	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	go pubInstance.GrantPresence(c, w, r, ch, false, false, 0, "", successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke Presence")
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

	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	go pubInstance.GrantPresence(c, w, r, ch, bRead, bWrite, iTTL, "", successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke Presence")

}

func auditSubscribe(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	uuid := q.Get("uuid")
	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	go pubInstance.AuditSubscribe(c, w, r, ch, "", successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Audit Subscribe")
}

func revokeSubscribe(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ch := q.Get("ch")
	uuid := q.Get("uuid")
	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	go pubInstance.GrantSubscribe(c, w, r, ch, false, false, 0, "", successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke Subscribe")
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
	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	go pubInstance.GrantSubscribe(c, w, r, ch, bRead, bWrite, iTTL, "", successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke Subscribe")
}

func setAuthKey(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	authKey := q.Get("authkey")
	uuid := q.Get("uuid")

	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	pubInstance.SetAuthenticationKey(c, w, r, authKey)
	sendResponseToChannel(w, "Auth key set", r, uuid)
}

func getAuthKey(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	uuid := q.Get("uuid")
	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	sendResponseToChannel(w, "Auth key: "+pubInstance.GetAuthenticationKey(), r, uuid)
}

func publish(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	message := q.Get("m")
	uuid := q.Get("uuid")
	ch := q.Get("ch")
	fire := q.Get("fire")
	//meta, _ := url.QueryUnescape(q.Get("meta"))
	metaKey := q.Get("metakey")
	metaVal := q.Get("metaval")
	storeInHistory := q.Get("storeInHistory")
	storeInHistoryBool := false
	if storeInHistory == "1" {
		storeInHistoryBool = true
	}

	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	meta := make(map[string]string)
	if strings.TrimSpace(metaKey) != "" && strings.TrimSpace(metaVal) != "" {
		meta[metaKey] = metaVal
	} else {
		meta = nil
	}

	//c := context.NewContext(r)
	c := createContext(r)

	/*message1 := make(map[string]string)
	message1["author"] = "user-a"
	message1["status"] = "I am reading about Advanced Channel Groups!"
	message1["timestamp"] = time.Now().String()*/

	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	//go pubInstance.Publish(c, w, r, "my_channel", message1, successChannel, errorChannel)

	if fire == "1" {
		go pubInstance.Fire(c, w, r, ch, message, false, successChannel, errorChannel)
	} else if meta != nil {
		log.Infof(c, fmt.Sprintf("Meta: %s", meta))
		go pubInstance.PublishExtendedWithMeta(c, w, r, ch, message, meta, storeInHistoryBool, false, successChannel, errorChannel)
	} else if storeInHistoryBool {
		go pubInstance.PublishExtended(c, w, r, ch, message, storeInHistoryBool, false, successChannel, errorChannel)
	} else {
		go pubInstance.Publish(c, w, r, ch, message, successChannel, errorChannel)
	}

	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Publish")
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

	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	go pubInstance.GlobalHereNow(c, w, r, disableUUID, includeUserState, successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Global Here Now")
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

	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	go pubInstance.HereNow(c, w, r, channel, disableUUID, includeUserState, successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "HereNow")
}

func whereNow(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	whereNowUUID := q.Get("whereNowUUID")
	uuid := q.Get("uuid")

	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	go pubInstance.WhereNow(c, w, r, whereNowUUID, successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "WhereNow")
}

func getTime(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	uuid := q.Get("uuid")

	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	//c := context.NewContext(r)
	c := createContext(r)
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	go pubInstance.GetTime(c, w, r, successChannel, errorChannel)
	handleResult(c, w, r, uuid, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Time")
}

func handler(w http.ResponseWriter, r *http.Request) {
	c := createContext(r)
	log.Infof(c, "IN handler")
	uuid := ""
	pubInstance := messaging.New(c, uuid, w, r, publishKey, subscribeKey, secretKey, "", false)
	if pubInstance == nil {
		log.Errorf(c, "Couldn't create pubnub instance")
		http.Error(w, "Couldn't create pubnub instance", http.StatusInternalServerError)
		return
	}
	nuuid := pubInstance.GetUUID()

	session, err := store.Get(r, "example-session")
	if err != nil {
		log.Errorf(c, "Session store error %s", err.Error())
		http.Error(w, "Session store error", http.StatusInternalServerError)
		return
	}

	//Enhancement: can be kept in memcache
	tok, err := channel.Create(c, nuuid)
	if err != nil {
		http.Error(w, "Couldn't create Channel", http.StatusInternalServerError)
		log.Errorf(c, "channel.Create: %v", err)
		return
	}
	session.Values["token"] = tok

	err1 := mainTemplate.Execute(w, map[string]string{
		"token":        tok,
		"uuid":         nuuid,
		"subscribeKey": subscribeKey,
		"publishKey":   publishKey,
		"secretKey":    secretKey,
	})
	if err1 != nil {
		log.Errorf(c, "mainTemplate: %v", err1)
	}
}

func flush(w http.ResponseWriter) {
	f, ok := w.(http.Flusher)
	if ok && f != nil {
		//log.Infof(c, "flush")
		f.Flush()
	} else {
		// Response writer does not support flush.
		fmt.Fprintf(w, fmt.Sprintf(" Response writer does not support flush.:"))
	}

}

func sendResponseToChannel(w http.ResponseWriter, message string, r *http.Request, uuid string) {
	//c := context.NewContext(r)
	c := createContext(r)
	err := channel.SendJSON(c, uuid, message)
	log.Infof(c, "json")
	if err != nil {
		log.Errorf(c, "sending Game: %v", err)
	}
}

func handleResultSubscribe(c context.Context, w http.ResponseWriter, r *http.Request, uuid string, successChannel, errorChannel chan []byte, timeoutVal uint16, action string) {
	for {
		select {

		case success, ok := <-successChannel:
			if !ok {
				log.Infof(c, fmt.Sprintf("success!OK"))

			}
			if string(success) != "[]" {
				log.Infof(c, "subscribe success:", string(success))
			}
			flush(w)
		case failure, ok := <-errorChannel:
			if !ok {
				log.Infof(c, fmt.Sprintf("failure!OK"))
			}
			if string(failure) != "[]" {
				log.Infof(c, "subscribe failure:", string(failure))
			}
		}
	}
}

func handleResult(c context.Context, w http.ResponseWriter, r *http.Request, uuid string, successChannel, errorChannel chan []byte, timeoutVal uint16, action string) {
	for {
		select {

		case success, ok := <-successChannel:
			if !ok {
				log.Infof(c, "success!OK")
				break
			}
			if string(success) != "[]" {
				log.Infof(c, "success:", string(success))
				sendResponseToChannel(w, string(success), r, uuid)
			}

			return
		case failure, ok := <-errorChannel:
			if !ok {
				log.Infof(c, "fail1:", string("failure"))
				break
			}
			if string(failure) != "[]" {
				log.Infof(c, "fail:", string(failure))
				sendResponseToChannel(w, string(failure), r, uuid)
			}
			return
		}
	}
}
