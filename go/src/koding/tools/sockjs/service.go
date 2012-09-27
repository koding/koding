package sockjs

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
	"net/http"
	"runtime/debug"
	"strings"
	"sync"
	"time"
)

type Service struct {
	IFrameContent      []byte
	IFrameETag         string
	Websocket          bool
	CookieNeeded       bool
	Timeout            time.Duration
	StreamLimit        int
	Callback           func(receiveChan <-chan interface{}, sendChan chan<- interface{})
	Sessions           map[string]*Session
	SessionsMutex      sync.Mutex
	LastSessionCleanup time.Time
}

func NewService(jsFileUrl string, websocket, cookieNeeded bool, timeout time.Duration, streamLimit int, callback func(receiveChan <-chan interface{}, sendChan chan<- interface{})) *Service {
	iFrameContent := createIFrameContent(jsFileUrl)
	hash := md5.New()
	hash.Write(iFrameContent)
	iFrameETag := "\"" + hex.EncodeToString(hash.Sum(nil)) + "\""

	if streamLimit == 0 {
		streamLimit = 128 * 1024
	}

	return &Service{
		IFrameContent:      iFrameContent,
		IFrameETag:         iFrameETag,
		Websocket:          websocket,
		CookieNeeded:       cookieNeeded,
		Timeout:            timeout,
		StreamLimit:        streamLimit,
		Callback:           callback,
		Sessions:           make(map[string]*Session),
		LastSessionCleanup: time.Now(),
	}
}

func (service *Service) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	defer func() {
		err := recover()
		if err != nil {
			fmt.Println(err)
			debug.PrintStack()
		}
	}()

	path := r.URL.Path

	if r.Header.Get("Origin") != "" && r.Header.Get("Origin") != "null" {
		w.Header().Set("Access-Control-Allow-Origin", r.Header.Get("Origin"))
	} else {
		w.Header().Set("Access-Control-Allow-Origin", "*")
	}
	w.Header().Set("Access-Control-Allow-Credentials", "true")
	h := r.Header.Get("Access-Control-Request-Headers")
	if h != "" {
		w.Header().Set("Access-Control-Allow-Headers", h)
	}

	if strings.HasPrefix(path, "/iframe") && strings.HasSuffix(path, ".html") && !strings.ContainsRune(path[1:], '/') {
		makeCachable(w)
		if r.Header.Get("If-None-Match") == service.IFrameETag {
			w.WriteHeader(http.StatusNotModified)
			return
		}

		w.Header().Set("ETag", service.IFrameETag)
		w.Header().Set("Content-Type", "text/html; charset=UTF-8")
		w.Write(service.IFrameContent)
		return

	} else if path == "" || path == "/" {
		w.Header().Set("Content-Type", "text/plain; charset=UTF-8")
		w.Write([]byte("Welcome to SockJS!\n"))
		return

	} else if path == "/info" {
		if r.Method == "OPTIONS" {
			answerOptions(w, "OPTIONS, GET")
			return
		}

		makeNotCachable(w)
		w.Header().Set("Content-Type", "application/json; charset=UTF-8")
		enc := json.NewEncoder(w)
		info := make(map[string]interface{})
		info["websocket"] = service.Websocket
		info["cookie_needed"] = service.CookieNeeded
		info["origins"] = []string{"*:*"}
		info["entropy"] = rand.Int31()
		enc.Encode(info)
		return

	} else if path == "/websocket" {
		service.serveRawWebsocket(w, r)
		return
	}

	parts := strings.Split(path, "/")[1:]
	if len(parts) != 3 || parts[0] == "" || strings.ContainsRune(parts[0], '.') || parts[1] == "" || strings.ContainsRune(parts[1], '.') {
		http.NotFound(w, r)
		return
	}

	if parts[2] == "websocket" {
		service.serveWebsocket(w, r)
		return
	}

	service.SessionsMutex.Lock()
	if service.LastSessionCleanup.Add(service.Timeout).Before(time.Now()) {
		for key, session := range service.Sessions {
			if session.Broken || session.LastActivity.Add(service.Timeout).Before(time.Now()) {
				close(session.ReceiveChan)
				delete(service.Sessions, key)
			}
		}
		service.LastSessionCleanup = time.Now()
	}
	session := service.Sessions[parts[1]]
	if session == nil {
		if parts[2] == "xhr_send" || parts[2] == "jsonp_send" {
			http.NotFound(w, r)
			service.SessionsMutex.Unlock()
			return
		}
		session = service.newSession()
		service.Sessions[parts[1]] = session
	}
	session.LastActivity = time.Now()
	service.SessionsMutex.Unlock()

	if service.CookieNeeded {
		newCookie := r.Header.Get("Cookie")
		if newCookie != "" {
			session.Cookie = newCookie
		}
		w.Header().Set("Set-Cookie", session.Cookie+";path=/")
	}

	chunked := r.ProtoMinor == 1
	switch parts[2] {
	case "xhr_send":
		if r.Method == "OPTIONS" {
			answerOptions(w, "OPTIONS, POST")
			return
		}

		if r.ContentLength == 0 {
			http.Error(w, "Payload expected.", http.StatusInternalServerError)
			return
		}

		data := make([]byte, r.ContentLength)
		io.ReadFull(r.Body, data)
		if session.readMessages(data) {
			w.Header().Set("Content-Type", "text/plain; charset=UTF-8")
			w.WriteHeader(http.StatusNoContent)
		} else {
			http.Error(w, "Broken JSON encoding.", http.StatusInternalServerError)
		}

	case "jsonp_send":
		var data []byte
		if r.Header.Get("Content-Type") == "application/x-www-form-urlencoded" {
			data = []byte(r.FormValue("d"))
		} else {
			data = make([]byte, r.ContentLength)
			io.ReadFull(r.Body, data)
		}
		if len(data) == 0 {
			http.Error(w, "Payload expected.", http.StatusInternalServerError)
			return
		}

		if session.readMessages(data) {
			w.Header().Set("Content-Type", "text/plain; charset=UTF-8")
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("ok"))
		} else {
			http.Error(w, "Broken JSON encoding.", http.StatusInternalServerError)
		}

	case "xhr":
		if r.Method == "OPTIONS" {
			answerOptions(w, "OPTIONS, POST")
			return
		}

		w.Header().Set("Content-Type", "application/javascript; charset=UTF-8")
		w.WriteHeader(http.StatusOK)

		session.writeFrames(w, false, chunked, nil, []byte{'\n'}, false)

	case "xhr_streaming":
		if r.Method == "OPTIONS" {
			answerOptions(w, "OPTIONS, POST")
			return
		}

		w.Header().Set("Content-Type", "application/javascript; charset=UTF-8")
		w.WriteHeader(http.StatusOK)

		prelude := make([]byte, 2049)
		for i := 0; i < 2048; i++ {
			prelude[i] = 'h'
		}
		prelude[2048] = '\n'
		w.Write(prelude)
		session.writeFrames(w, true, chunked, nil, []byte{'\n'}, false)

	case "eventsource":
		w.Header().Set("Content-Type", "text/event-stream; charset=UTF-8")
		makeNotCachable(w)
		w.WriteHeader(http.StatusOK)

		w.Write([]byte("\r\n"))
		session.writeFrames(w, true, chunked, []byte("data: "), []byte("\r\n\r\n"), false)

	case "htmlfile":
		callback := r.URL.Query().Get("c")
		if callback == "" {
			http.Error(w, `"callback" parameter required`, http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "text/html; charset=UTF-8")
		makeNotCachable(w)
		w.WriteHeader(http.StatusOK)

		w.Write(createHtmlfileContent(callback))
		session.writeFrames(w, true, chunked, []byte("<script>\np(\""), []byte("\");\n</script>\r\n"), true)

	case "jsonp":
		callback := r.URL.Query().Get("c")
		if callback == "" {
			http.Error(w, `"callback" parameter required`, http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/javascript; charset=UTF-8")
		makeNotCachable(w)
		w.WriteHeader(http.StatusOK)

		session.writeFrames(w, false, chunked, []byte(callback+"(\""), []byte("\");\r\n"), true)

	default:
		http.NotFound(w, r)
	}

}

func (service *Service) newSession() *Session {
	session := &Session{
		Service:         service,
		ReceiveChan:     make(chan interface{}, 100),
		SendChan:        make(chan interface{}, 100),
		DoConnCheck:     make(chan bool),
		ConnCheckResult: make(chan bool),
		ReadSemaphore:   make(chan bool, 1),
		WriteOpenFrame:  true,
		Cookie:          "JSESSIONID=dummy",
	}
	go func() {
		service.Callback(session.ReceiveChan, session.SendChan)
		close(session.SendChan)
	}()
	return session
}

func makeCachable(w http.ResponseWriter) {
	cachingDuration := time.Hour * 24 * 365
	w.Header().Set("Cache-Control", fmt.Sprintf("public, max-age=%d", int(cachingDuration.Seconds())))
	w.Header().Set("Expires", time.Now().Add(cachingDuration).Format(time.RFC1123))
}

func makeNotCachable(w http.ResponseWriter) {
	w.Header().Set("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
}

func answerOptions(w http.ResponseWriter, allowedMethods string) {
	makeCachable(w)
	w.Header().Set("Access-Control-Max-Age", "31536000")
	w.Header().Set("Access-Control-Allow-Methods", allowedMethods)
	w.WriteHeader(http.StatusNoContent)
}

func createIFrameContent(jsFileUrl string) []byte {
	return []byte(`<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <script>
    document.domain = document.domain;
    _sockjs_onload = function(){SockJS.bootstrap_iframe();};
  </script>
  <script src="` + jsFileUrl + `"></script>
</head>
<body>
  <h2>Don't panic!</h2>
  <p>This is a SockJS hidden iframe. It's used for cross domain magic.</p>
</body>
</html>`)
}

func createHtmlfileContent(callback string) []byte {
	body := []byte(`<!doctype html>
<html><head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head><body><h2>Don't panic!</h2>
  <script>
    document.domain = document.domain;
    var c = parent.` + callback + `;
    c.start();
    function p(d) {c.message(d);};
    window.onload = function() {c.stop();};
  </script>`)
	content := make([]byte, 1025)
	copy(content, body)
	for i := len(body); i < len(content); i++ {
		content[i] = ' '
	}
	return content
}
