package streamtunnel

import (
	"io"
	"io/ioutil"
	"net/http"
	"strconv"
	"sync"
	"testing"
	"time"
)

var (
	serverAddr = "127.0.0.1:7000"
	localAddr  = "127.0.0.1:5000"
	identifier = "123abc"
)

func TestTunnel(t *testing.T) {
	// setup tunnelserver
	server := NewServer(&ServerConfig{
		Debug: true,
	})
	server.AddHost(serverAddr, identifier)
	http.Handle("/", server)
	go func() {
		err := http.ListenAndServe(serverAddr, nil)
		if err != nil {
			t.Fatal(err)
		}
	}()

	time.Sleep(time.Second)

	// setup tunnelclient
	client := NewClient(&ClientConfig{
		ServerAddr: serverAddr,
		LocalAddr:  localAddr,
		Debug:      true,
	})
	go client.Start(identifier)

	// start local server to be tunneled
	go http.ListenAndServe(localAddr, echo())

	time.Sleep(time.Second)

	// make a request to tunnelserver, this should be tunneled to local server
	var wg sync.WaitGroup
	for i := 0; i < 10; i++ {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()
			msg := "hello" + strconv.Itoa(i)
			res, err := makeRequest(msg)
			if err != nil {
				t.Errorf("make request: %s", err)
			}

			if res != msg {
				t.Errorf("Expecting %s, got %s", msg, res)
			}
		}(i)
	}

	wg.Wait()
}

func makeRequest(msg string) (string, error) {
	resp, err := http.Get("http://" + serverAddr + "/?echo=" + msg)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	res, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return string(res), nil
}

func echo() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		msg := r.URL.Query().Get("echo")
		io.WriteString(w, msg)
	})
}
