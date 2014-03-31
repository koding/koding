package main

import (
	"fmt"
	"koding/kite"
	"koding/kite/dnode"
	"strings"
	"testing"
	"time"
)

func TestTerminal(t *testing.T) {
	termKite := NewTerminal()
	termKite.PublicIP = "127.0.0.1"
	termKite.Port = "3636"
	termKite.KontrolEnabled = false
	termKite.Start()
	defer termKite.Close()

	options := &kite.Options{
		Kitename:    "client",
		Version:     "0.0.1",
		Region:      "localhost",
		Environment: "development",
		PublicIP:    "127.0.0.1",
		Port:        "3637",
	}
	client := kite.New(options)
	client.KontrolEnabled = false
	client.Start()
	defer client.Close()

	// Use the kodingKey auth type since they are on same host.
	auth := kite.Authentication{
		Type: "kodingKey",
		Key:  termKite.KodingKey,
	}
	remote := client.NewRemoteKite(termKite.Kite, auth)
	err := remote.Dial()
	if err != nil {
		t.Error(err.Error())
		return
	}

	termClient := newTermHandler()

	result, err := remote.Tell("connect", struct {
		Remote       *termHandler
		Session      string
		SizeX, SizeY int
		NoScreen     bool
	}{
		Remote: termClient,
		SizeX:  80,
		SizeY:  24,
	})
	if err != nil {
		t.Error(err)
		return
	}

	var term *remoteTerm
	err = result.Unmarshal(&term)
	if err != nil {
		t.Error(err.Error())
		return
	}

	// Two commands are run to make sure that the order of the keys are preserved.
	// If not, sometimes inputs are mixed in a way that is non-deterministic.

	term.Input(`say hi`)
	// time.Sleep(100 * time.Millisecond)
	term.ControlSequence("\r")

	// time.Sleep(100 * time.Millisecond)

	term.Input(`python -c "print 123455+1"`)
	// time.Sleep(100 * time.Millisecond)
	term.ControlSequence("\r")

	fullOutput := ""
	for {
		select {
		case output := <-termClient.output:
			// fmt.Printf("Received output from channel: %+v\n", output)
			fullOutput += output
			if strings.Contains(fullOutput, "123456") { // magic number
				return
			}
		case <-time.After(2 * time.Second):
			fmt.Println(fullOutput)
			t.Error("Timeout")
			return
		}
	}
}

type termHandler struct {
	output chan string
}

func newTermHandler() *termHandler {
	return &termHandler{
		output: make(chan string),
	}
}

func (r *termHandler) Output(req *kite.Request) {
	data := req.Args.MustSliceOfLength(1)[0].MustString()
	r.output <- data
}

func (r *termHandler) SessionEnded(req *kite.Request) {
	fmt.Println("Session ended")
}

type remoteTerm struct {
	Session         string `json:"session"`
	Input           dnode.Function
	ControlSequence dnode.Function
	SetSize         dnode.Function
	Close           dnode.Function
	Terminate       dnode.Function
}
