package kite

import (
	"fmt"
	"net/http"
	"net/url"
	"os/exec"
	"runtime"
	"sync"
	"time"

	"code.google.com/p/go.crypto/ssh/terminal"
	"github.com/gorilla/websocket"
	"github.com/koding/kite/sockjsclient"
	"github.com/koding/kite/systeminfo"
)

func (k *Kite) addDefaultHandlers() {
	k.HandleFunc("kite.systemInfo", systemInfo)
	k.HandleFunc("kite.heartbeat", k.handleHeartbeat)
	k.HandleFunc("kite.ping", handlePing).DisableAuthentication()
	k.HandleFunc("kite.tunnel", handleTunnel)
	k.HandleFunc("kite.log", k.handleLog)
	k.HandleFunc("kite.print", handlePrint)
	k.HandleFunc("kite.prompt", handlePrompt)
	k.HandleFunc("kite.getPass", handleGetPass)
	if runtime.GOOS == "darwin" {
		k.HandleFunc("kite.notify", handleNotifyDarwin)
	}
}

// systemInfo returns info about the system (CPU, memory, disk...).
func systemInfo(r *Request) (interface{}, error) {
	return systeminfo.New()
}

// handleHeartbeat pings the callback with the given interval seconds.
func (k *Kite) handleHeartbeat(r *Request) (interface{}, error) {
	args := r.Args.MustSliceOfLength(2)
	seconds := args[0].MustFloat64()
	ping := args[1].MustFunction()

	heartbeat := time.NewTicker(time.Duration(seconds) * time.Second)
	done := make(chan bool, 0)

	// stop the ticker and close the done chan so we can break the loop
	var once sync.Once
	r.Client.OnDisconnect(func() {
		heartbeat.Stop()
		once.Do(func() { close(done) })
	})

	// we need to break out because stopping the ticker is not enough. If we
	// stop the ticker ping.Call() will block until there is data from the
	// other end of the connection. So use an explicit exit.

loop:
	for {
		select {
		case <-done:
			break loop
		case <-heartbeat.C:
			if err := ping.Call(); err != nil {
				k.Log.Error(err.Error())
			}
		}
	}

	// remove the onDisconnect again so it doesn't call close twice
	r.Client.onDisconnectHandlers = nil

	return nil, nil
}

// handleLog prints a log message to stderr.
func (k *Kite) handleLog(r *Request) (interface{}, error) {
	msg := r.Args.One().MustString()
	k.Log.Info(fmt.Sprintf("%s: %s", r.Client.Name, msg))
	return nil, nil
}

//handlePing returns a simple "pong" string
func handlePing(r *Request) (interface{}, error) {
	return "pong", nil
}

// handlePrint prints a message to stdout.
func handlePrint(r *Request) (interface{}, error) {
	return fmt.Print(r.Args.One().MustString())
}

// handlePrompt asks user a single line input.
func handlePrompt(r *Request) (interface{}, error) {
	fmt.Print(r.Args.One().MustString())
	var s string
	_, err := fmt.Scanln(&s)
	return s, err
}

// handleGetPass reads a line of input from a terminal without local echo.
func handleGetPass(r *Request) (interface{}, error) {
	fmt.Print(r.Args.One().MustString())
	data, err := terminal.ReadPassword(0) // stdin
	fmt.Println()
	if err != nil {
		return nil, err
	}
	return string(data), nil
}

// handleNotifyDarwin displays a desktop notification on OS X.
func handleNotifyDarwin(r *Request) (interface{}, error) {
	args := r.Args.MustSliceOfLength(3)
	cmd := exec.Command("osascript", "-e", fmt.Sprintf("display notification \"%s\" with title \"%s\" subtitle \"%s\"",
		args[1].MustString(), args[2].MustString(), args[0].MustString()))
	return nil, cmd.Start()
}

// handleTunnel opens two websockets, one to proxy kite and one to itself,
// then it copies the message between them.
func handleTunnel(r *Request) (interface{}, error) {
	var args struct {
		URL string
	}
	r.Args.One().MustUnmarshal(&args)

	parsed, err := url.Parse(args.URL)
	if err != nil {
		return nil, err
	}

	requestHeader := http.Header{}
	requestHeader.Add("Origin", "http://"+parsed.Host)

	remoteConn, _, err := websocket.DefaultDialer.Dial(parsed.String(), requestHeader)
	if err != nil {
		return nil, err
	}

	session := sockjsclient.NewWebsocketSession(remoteConn)

	go r.LocalKite.sockjsHandler(session)
	return nil, nil
}
