package tunnel

import (
	"io"
	"io/ioutil"
	"net/http"
	"testing"
	"time"
)

var (
	serverAddr = "127.0.0.1:7000"
	localAddr  = "127.0.0.1:5000"
	identifier = "123abc"
	testMsg    = "hello"
)

func TestTunnel(t *testing.T) {
	// setup tunnelserver
	server := NewServer()
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
	client := NewClient(serverAddr, localAddr)
	go client.Start(identifier)

	// start local server to be tunneled
	go http.ListenAndServe(localAddr, hello())
	time.Sleep(time.Second)

	// make a request to tunnelserver, this should be tunneled to local server
	res, err := makeRequest()
	if err != nil {
		t.Errorf("make request: %s", err)
	}

	if res != testMsg {
		t.Errorf("Expecting %s, got %s", testMsg, res)
	}
}

func makeRequest() (string, error) {
	resp, err := http.Get("http://" + serverAddr)
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

func hello() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, testMsg)
	})
}
