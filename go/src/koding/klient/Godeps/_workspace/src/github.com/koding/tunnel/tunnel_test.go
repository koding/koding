package tunnel

import (
	"io"
	"io/ioutil"
	"math/rand"
	"net"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"
)

type testEnv struct {
	server         *Server
	client         *Client
	remoteListener net.Listener
	localListener  net.Listener
}

type testConfig struct {
	localHandler http.Handler
}

func singleTestEnvironment(cfg *testConfig) (*testEnv, error) {
	if cfg == nil {
		cfg = &testConfig{}
	}

	debug := false
	if testing.Verbose() {
		debug = true
	}

	var identifier = "123abc"

	tunnelServer, _ := NewServer(&ServerConfig{Debug: debug})
	remoteServer := http.Server{Handler: tunnelServer}
	remoteListener, err := net.Listen("tcp", ":0")
	if err != nil {
		return nil, err
	}

	tunnelServer.AddHost(remoteListener.Addr().String(), identifier)
	go remoteServer.Serve(remoteListener)

	localListener, err := net.Listen("tcp", ":0")
	if err != nil {
		return nil, err
	}

	tunnelClient, _ := NewClient(&ClientConfig{
		Identifier: identifier,
		ServerAddr: remoteListener.Addr().String(),
		LocalAddr:  localListener.Addr().String(),
		Debug:      debug,
	})
	go tunnelClient.Start()
	<-tunnelClient.StartNotify()

	localHandler := echo()
	if cfg.localHandler != nil {
		localHandler = cfg.localHandler
	}

	localServer := http.Server{Handler: localHandler}
	go localServer.Serve(localListener)

	return &testEnv{
		server:         tunnelServer,
		client:         tunnelClient,
		remoteListener: remoteListener,
		localListener:  localListener,
	}, nil
}

func (t *testEnv) Close() {
	if t.client != nil {
		t.client.Close()
	}

	if t.remoteListener != nil {
		t.remoteListener.Close()
	}

	if t.localListener != nil {
		t.localListener.Close()
	}
}

func TestMultipleRequest(t *testing.T) {
	tenv, err := singleTestEnvironment(nil)
	if err != nil {
		t.Fatal(err)
	}
	defer tenv.Close()

	// make a request to tunnelserver, this should be tunneled to local server
	var wg sync.WaitGroup
	for i := 0; i < 100; i++ {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()
			msg := "hello" + strconv.Itoa(i)
			res, err := makeRequest(tenv.remoteListener.Addr().String(), msg)
			if err != nil {
				t.Errorf("make request: %s", err)
			}

			if res != msg {
				t.Errorf("Expecting %s, got %s", msg, res)
			}
		}(i)
	}

	wg.Wait()
	tenv.Close()
}

func TestMultipleLatencyRequest(t *testing.T) {
	tenv, err := singleTestEnvironment(&testConfig{
		localHandler: randomLatencyEcho(),
	})
	if err != nil {
		t.Fatal(err)
	}
	defer tenv.Close()

	// make a request to tunnelserver, this should be tunneled to local server
	var wg sync.WaitGroup
	for i := 0; i < 100; i++ {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()
			msg := "hello" + strconv.Itoa(i)
			res, err := makeRequest(tenv.remoteListener.Addr().String(), msg)
			if err != nil {
				t.Errorf("make request: %s", err)
			}

			if res != msg {
				t.Errorf("Expecting %s, got %s", msg, res)
			}
		}(i)
	}

	wg.Wait()
	tenv.Close()
}

func TestReconnectClient(t *testing.T) {
	tenv, err := singleTestEnvironment(nil)
	if err != nil {
		t.Fatal(err)
	}
	defer tenv.Close()

	msg := "hello"
	res, err := makeRequest(tenv.remoteListener.Addr().String(), msg)
	if err != nil {
		t.Errorf("make request: %s", err)
	}

	if res != msg {
		t.Errorf("expecting '%s', got '%s'", msg, res)
	}

	// close client, and start it again
	tenv.client.Close()

	go tenv.client.Start()
	<-tenv.client.StartNotify()

	msg = "helloagain"
	res, err = makeRequest(tenv.remoteListener.Addr().String(), msg)
	if err != nil {
		t.Errorf("make request: %s", err)
	}

	if res != msg {
		t.Errorf("expecting '%s', got '%s'", msg, res)
	}

}

func TestNoClient(t *testing.T) {
	tenv, err := singleTestEnvironment(nil)
	if err != nil {
		t.Fatal(err)
	}

	// close client, this is the main point of the test
	tenv.client.Close()

	msg := "hello"
	res, err := makeRequest(tenv.remoteListener.Addr().String(), msg)
	if err != nil {
		t.Errorf("make request: %s", err)
	}

	if res != errNoClientSession.Error() {
		t.Errorf("Expecting '%s', got '%s'", "no client session established", res)
	}
	tenv.Close()
}

func TestNoLocalServer(t *testing.T) {
	tenv, err := singleTestEnvironment(nil)
	if err != nil {
		t.Fatal(err)
	}

	// close local listener, this is the main point of the test
	tenv.localListener.Close()

	msg := "hello"
	res, err := makeRequest(tenv.remoteListener.Addr().String(), msg)
	if err != nil {
		t.Errorf("make request: %s", err)
	}

	if res != "no local server" {
		t.Errorf("Expecting %s, got %s", msg, res)
	}
	tenv.Close()
}

func TestSingleRequest(t *testing.T) {
	tenv, err := singleTestEnvironment(nil)
	if err != nil {
		t.Fatal(err)
	}

	msg := "hello"
	res, err := makeRequest(tenv.remoteListener.Addr().String(), msg)
	if err != nil {
		t.Errorf("make request: %s", err)
	}

	if res != msg {
		t.Errorf("Expecting %s, got %s", msg, res)
	}
	tenv.Close()
}

func TestSingleLatencyRequest(t *testing.T) {
	tenv, err := singleTestEnvironment(&testConfig{
		localHandler: randomLatencyEcho(),
	})
	if err != nil {
		t.Fatal(err)
	}

	msg := "hello"
	res, err := makeRequest(tenv.remoteListener.Addr().String(), msg)
	if err != nil {
		t.Errorf("make request: %s", err)
	}

	if res != msg {
		t.Errorf("Expecting %s, got %s", msg, res)
	}
	tenv.Close()
}

func makeRequest(serverAddr, msg string) (string, error) {
	resp, err := http.Get("http://" + serverAddr + "/?echo=" + msg)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	res, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return strings.TrimSpace(string(res)), nil
}

func echo() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		msg := r.URL.Query().Get("echo")
		io.WriteString(w, msg)
	})
}

func randomLatencyEcho() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(time.Duration(rand.Intn(2000)) * time.Millisecond)
		msg := r.URL.Query().Get("echo")
		io.WriteString(w, msg)
	})
}
